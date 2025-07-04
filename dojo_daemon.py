#!/usr/bin/env python3
"""
dojo_daemon.py - Long-running Urbit Dojo Daemon

A daemon process that maintains a persistent connection to your Urbit ship,
continuously capturing all events and maintaining terminal state. Provides
a simple file-based IPC mechanism for sending commands and checking output.

Architecture:
- Daemon process maintains connection and captures all events
- Commands sent via command file
- Output retrieved via output file
- Events stored in rotating event log
"""

import json
import os
import queue
import requests
import signal
import sys
import threading
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

from urbit_dojo import UrbitDojo, TerminalBuffer, load_config


class DojoDaemon:
    """
    Long-running daemon that maintains Urbit connection and buffers all events.
    """
    
    def __init__(self, work_dir: str = None):
        """
        Initialize the daemon.
        
        Args:
            work_dir: Working directory for IPC files (default: .dojo_daemon/)
        """
        # Set up working directory
        if work_dir is None:
            work_dir = os.path.join(os.path.dirname(__file__), '.dojo_daemon')
        self.work_dir = Path(work_dir)
        self.work_dir.mkdir(exist_ok=True)
        
        # IPC file paths
        self.command_file = self.work_dir / 'command.json'
        self.output_file = self.work_dir / 'output.json'
        self.events_file = self.work_dir / 'events.jsonl'
        self.status_file = self.work_dir / 'status.json'
        self.pid_file = self.work_dir / 'daemon.pid'
        
        # Initialize dojo connection
        config = load_config()
        self.dojo = UrbitDojo(config['ship_url'], config['ship_name'], config['access_code'])
        
        # Terminal buffer and event storage
        self.terminal_buffer = TerminalBuffer()
        self.all_events = []
        self.event_queue = queue.Queue()
        
        # Daemon state
        self.running = False
        self.connected = False
        self.command_id = 0
        self.last_command_time = None
        self.start_time = time.time()
        self.reconnect_attempts = 0
        self.max_reconnect_attempts = 5
        self.reconnect_delay = 10.0
        self.slog_messages = []  # Store recent slog messages
        
        # Threads
        self.event_capture_thread = None
        self.command_watch_thread = None
        self.event_processor_thread = None
    
    def start(self):
        """Start the daemon"""
        print(f"Starting Dojo Daemon (PID: {os.getpid()})")
        
        # Write PID file
        with open(self.pid_file, 'w') as f:
            f.write(str(os.getpid()))
        
        # Connect to Urbit
        print("Connecting to Urbit...")
        if not self._connect_with_retry():
            print("Failed to connect to Urbit after retries!")
            return False
        
        self.connected = True
        self.running = True
        
        # Start threads
        self.event_capture_thread = threading.Thread(target=self._capture_events, daemon=True)
        self.command_watch_thread = threading.Thread(target=self._watch_commands, daemon=True)
        self.event_processor_thread = threading.Thread(target=self._process_events, daemon=True)
        
        self.event_capture_thread.start()
        self.command_watch_thread.start()
        self.event_processor_thread.start()
        
        # Update status
        self._update_status("running")
        
        print("Daemon started successfully!")
        print(f"Command file: {self.command_file}")
        print(f"Output file: {self.output_file}")
        
        # Set up signal handlers
        signal.signal(signal.SIGTERM, self._handle_shutdown)
        signal.signal(signal.SIGINT, self._handle_shutdown)
        
        # Main loop
        try:
            while self.running:
                time.sleep(1)
                self._update_status("running")
        except KeyboardInterrupt:
            pass
        
        self.shutdown()
        return True
    
    def _handle_shutdown(self, signum, frame):
        """Handle shutdown signals"""
        print(f"\nReceived signal {signum}, shutting down...")
        self.running = False
    
    def _connect_with_retry(self) -> bool:
        """Connect to Urbit with retry logic"""
        for attempt in range(self.max_reconnect_attempts):
            if attempt > 0:
                print(f"Reconnection attempt {attempt + 1}/{self.max_reconnect_attempts}...")
                time.sleep(self.reconnect_delay)
            
            try:
                if self.dojo.connect():
                    self.reconnect_attempts = 0
                    print("Connected successfully!")
                    return True
            except Exception as e:
                print(f"Connection attempt {attempt + 1} failed: {e}")
        
        return False
    
    def _reconnect_if_needed(self):
        """Check connection and reconnect if needed"""
        if not self.connected:
            return
        
        try:
            # Simple connection test - try to access cookies
            if not self.dojo.cookies:
                raise Exception("No cookies - connection lost")
            return  # Connection seems OK
        except:
            print("Connection lost, attempting to reconnect...")
            self.connected = False
            
            if self._connect_with_retry():
                self.connected = True
                print("Reconnected successfully")
            else:
                print("Failed to reconnect, shutting down")
                self.running = False

    def shutdown(self):
        """Shutdown the daemon"""
        print("Shutting down daemon...")
        self.running = False
        
        # Disconnect from Urbit
        if self.connected:
            try:
                self.dojo.disconnect()
            except:
                pass  # Ignore errors during shutdown
        
        # Clean up PID file
        if self.pid_file.exists():
            self.pid_file.unlink()
        
        # Final status update
        self._update_status("stopped")
        
        print("Daemon stopped.")
    
    def _capture_events(self):
        """Continuously capture events from Urbit"""
        while self.running and self.connected:
            try:
                response = requests.get(
                    f"{self.dojo.ship_url}/~/channel/{self.dojo.channel_id}",
                    cookies=self.dojo.cookies,
                    stream=True,
                    timeout=30  # 30 second timeout
                )
                
                if response.status_code != 200:
                    print(f"HTTP error {response.status_code}, will reconnect")
                    self._reconnect_if_needed()
                    continue
                
                for line in response.iter_lines():
                    if not self.running:
                        break
                    
                    if line and line.decode('utf-8').startswith('data: '):
                        try:
                            data = json.loads(line.decode('utf-8')[6:])
                            # Add to queue for processing
                            self.event_queue.put({
                                'timestamp': time.time(),
                                'event': data
                            })
                        except json.JSONDecodeError:
                            print(f"Invalid JSON in event: {line}")
                        except Exception as e:
                            print(f"Error processing event: {e}")
                
            except requests.exceptions.Timeout:
                print("Event stream timeout, reconnecting...")
                self._reconnect_if_needed()
            except requests.exceptions.ConnectionError:
                print("Connection error, will reconnect")
                self._reconnect_if_needed()
                time.sleep(5)
            except Exception as e:
                print(f"Event capture error: {e}")
                self._reconnect_if_needed()
                time.sleep(5)
    
    def _process_events(self):
        """Process events from the queue"""
        while self.running:
            try:
                # Get event from queue (timeout allows checking self.running)
                event_data = self.event_queue.get(timeout=1)
                
                # Store event
                self.all_events.append(event_data)
                
                # Rotate events if too many (keep last 1000)
                if len(self.all_events) > 1000:
                    self.all_events = self.all_events[-1000:]
                    # Rotate log file
                    if self.events_file.exists():
                        backup_file = self.events_file.with_suffix('.old')
                        self.events_file.rename(backup_file)
                
                # Write to event log
                with open(self.events_file, 'a') as f:
                    f.write(json.dumps(event_data) + '\n')
                
                # Process through terminal buffer
                event = event_data['event']
                if 'json' in event and 'mor' in event['json']:
                    for blit in event['json']['mor']:
                        self.dojo._process_blit(blit, self.terminal_buffer)
                
                # Update output file
                self._update_output()
                
            except queue.Empty:
                continue
            except Exception as e:
                print(f"Event processing error: {e}")
    
    def _watch_commands(self):
        """Watch for new commands to execute"""
        while self.running:
            try:
                if self.command_file.exists():
                    with open(self.command_file, 'r') as f:
                        command_data = json.load(f)
                    
                    # Remove command file immediately
                    self.command_file.unlink()
                    
                    # Execute command
                    self._execute_command(command_data)
                
                time.sleep(0.1)  # Check for commands 10 times per second
                
            except Exception as e:
                print(f"Command watch error: {e}")
                time.sleep(1)
    
    def _execute_command(self, command_data: Dict):
        """Execute a command from the command file"""
        try:
            chars = command_data.get('chars', [])
            command_id = command_data.get('id', self.command_id)
            command_str = ''.join(chars)
            
            print(f"Executing command {command_id}: {command_str[:50]}...")
            
            # Update state
            self.command_id = command_id
            self.last_command_time = time.time()
            
            # Use the library's run method which handles slog capture
            result = self.dojo.run(command_str, timeout=30.0)
            
            # Extract slog messages from result
            if hasattr(result, 'slog_messages') and result.slog_messages:
                self.slog_messages.extend(result.slog_messages)
                # Keep only recent slog messages (last 50)
                self.slog_messages = self.slog_messages[-50:]
                print(f"Captured {len(result.slog_messages)} slog messages")
            
            # Update output with command info and slog messages
            self._update_output(command_id=command_id, command=command_str, result=result)
            
        except Exception as e:
            print(f"Command execution error: {e}")
            self._update_output(error=str(e))
    
    def _clean_terminal_output(self, text: str) -> str:
        """Clean up terminal output for better readability"""
        lines = text.split('\n')
        cleaned_lines = []
        
        for line in lines:
            # Skip empty lines
            if not line.strip():
                continue
            
            # Skip duplicate prompts
            if line.strip().endswith(':dojo>') and cleaned_lines and cleaned_lines[-1].strip().endswith(':dojo>'):
                continue
                
            cleaned_lines.append(line)
        
        return '\n'.join(cleaned_lines)

    def _update_output(self, command_id: Optional[int] = None, command: Optional[str] = None, error: Optional[str] = None, result=None):
        """Update the output file with current state"""
        raw_terminal = self.terminal_buffer.get_visible_text()
        cleaned_terminal = self._clean_terminal_output(raw_terminal)
        
        # If we have a result from dojo.run(), use its output
        if result is not None:
            cleaned_terminal = result.output
            raw_terminal = result.raw_output if hasattr(result, 'raw_output') else result.output
        
        output_data = {
            'timestamp': time.time(),
            'terminal': cleaned_terminal,
            'terminal_raw': raw_terminal,
            'total_events': len(self.all_events),
            'last_command_id': self.command_id,
            'last_command_time': self.last_command_time,
            'daemon_uptime': time.time() - self.start_time,
            'slog_messages': self.slog_messages[-10:]  # Include last 10 slog messages
        }
        
        if command_id is not None:
            output_data['command_id'] = command_id
        
        if command is not None:
            output_data['command'] = command
        
        if error is not None:
            output_data['error'] = error
        
        # Add slog messages from current result if available
        if result is not None and hasattr(result, 'slog_messages') and result.slog_messages:
            output_data['current_slog_messages'] = result.slog_messages
        
        # Get recent events (last 10)
        recent_events = []
        for event_data in self.all_events[-10:]:
            event = event_data['event']
            if 'json' in event and 'mor' in event['json']:
                for blit in event['json']['mor']:
                    if 'put' in blit:
                        recent_events.append({
                            'time': event_data['timestamp'],
                            'type': 'text',
                            'content': ''.join(blit['put'])
                        })
                    elif 'bel' in blit:
                        recent_events.append({
                            'time': event_data['timestamp'],
                            'type': 'bell'
                        })
        
        output_data['recent_events'] = recent_events
        
        # Write atomically
        temp_file = self.output_file.with_suffix('.tmp')
        with open(temp_file, 'w') as f:
            json.dump(output_data, f, indent=2)
        temp_file.replace(self.output_file)
    
    def _update_status(self, status: str):
        """Update daemon status file"""
        status_data = {
            'status': status,
            'pid': os.getpid(),
            'connected': self.connected,
            'uptime': time.time() - self.start_time,
            'total_events': len(self.all_events),
            'last_update': time.time(),
            'ship': self.dojo.ship_name if self.connected else None,
            'reconnect_attempts': self.reconnect_attempts,
            'last_command_time': self.last_command_time
        }
        
        with open(self.status_file, 'w') as f:
            json.dump(status_data, f, indent=2)


class DojoClient:
    """
    Client for interacting with the Dojo Daemon.
    """
    
    def __init__(self, work_dir: str = None):
        if work_dir is None:
            work_dir = os.path.join(os.path.dirname(__file__), '.dojo_daemon')
        self.work_dir = Path(work_dir)
        
        self.command_file = self.work_dir / 'command.json'
        self.output_file = self.work_dir / 'output.json'
        self.status_file = self.work_dir / 'status.json'
        self.pid_file = self.work_dir / 'daemon.pid'
    
    def is_running(self) -> bool:
        """Check if daemon is running"""
        if not self.pid_file.exists():
            return False
        
        try:
            with open(self.pid_file, 'r') as f:
                pid = int(f.read().strip())
            
            # Check if process exists
            os.kill(pid, 0)
            return True
        except:
            return False
    
    def get_status(self) -> Optional[Dict]:
        """Get daemon status"""
        if not self.status_file.exists():
            return None
        
        try:
            with open(self.status_file, 'r') as f:
                return json.load(f)
        except:
            return None
    
    def send_command(self, command: str) -> Dict:
        """Send a command to the daemon"""
        if not self.is_running():
            return {'error': 'Daemon not running'}
        
        # Parse command for escape sequences
        chars = []
        i = 0
        while i < len(command):
            if command[i] == '\\' and i + 1 < len(command):
                next_char = command[i + 1]
                if next_char == 't':
                    chars.append('\t')
                elif next_char == 'n':
                    chars.append('\n')
                elif next_char == 'r':
                    chars.append('\r')
                elif next_char == 'b':
                    chars.append('\b')
                else:
                    chars.append(command[i])
                    chars.append(next_char)
                i += 2
            else:
                chars.append(command[i])
                i += 1
        
        # Add enter if not present
        if not chars or chars[-1] not in ['\r', '\n']:
            chars.append('\r')
        
        # Create command
        command_data = {
            'id': int(time.time() * 1000),
            'chars': chars,
            'timestamp': time.time()
        }
        
        # Write command file
        with open(self.command_file, 'w') as f:
            json.dump(command_data, f)
        
        # Wait a moment for command to be picked up
        time.sleep(0.2)
        
        return {
            'command_id': command_data['id'],
            'command': command,
            'status': 'sent'
        }
    
    def get_output(self) -> Optional[Dict]:
        """Get current output from daemon"""
        if not self.output_file.exists():
            return None
        
        try:
            with open(self.output_file, 'r') as f:
                return json.load(f)
        except:
            return None
    
    def wait_for_output(self, command_id: int = None, timeout: float = 10.0) -> Optional[Dict]:
        """Wait for output, optionally for a specific command"""
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            output = self.get_output()
            
            if output is None:
                time.sleep(0.1)
                continue
            
            # If no command_id specified, return latest output
            if command_id is None:
                return output
            
            # Check if our command has been processed
            if output.get('last_command_id', 0) >= command_id:
                return output
            
            time.sleep(0.1)
        
        return None


def main():
    """CLI interface for the dojo daemon"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Urbit Dojo Daemon')
    parser.add_argument('action', choices=['start', 'stop', 'status', 'send', 'output', 'watch'],
                        help='Action to perform')
    parser.add_argument('command', nargs='?', help='Command to send (for send action)')
    parser.add_argument('--timeout', type=float, default=10.0, help='Timeout for waiting')
    
    args = parser.parse_args()
    
    if args.action == 'start':
        # Check if already running
        client = DojoClient()
        if client.is_running():
            print("Daemon already running")
            return
        
        # Fork to background
        pid = os.fork()
        if pid > 0:
            # Parent process
            print(f"Starting daemon in background (PID: {pid})")
            time.sleep(1)  # Give daemon time to start
            
            # Check if started successfully
            if client.is_running():
                print("Daemon started successfully")
            else:
                print("Failed to start daemon")
            return
        
        # Child process - become daemon
        os.setsid()
        
        # Redirect stdout/stderr to log file
        log_file = client.work_dir / 'daemon.log'
        with open(log_file, 'a') as f:
            os.dup2(f.fileno(), sys.stdout.fileno())
            os.dup2(f.fileno(), sys.stderr.fileno())
        
        # Start daemon
        daemon = DojoDaemon()
        daemon.start()
        
    elif args.action == 'stop':
        # Stop daemon
        client = DojoClient()
        if not client.is_running():
            print("Daemon not running")
            return
        
        with open(client.pid_file, 'r') as f:
            pid = int(f.read().strip())
        
        print(f"Stopping daemon (PID: {pid})...")
        os.kill(pid, signal.SIGTERM)
        
        # Wait for shutdown
        for _ in range(50):
            if not client.is_running():
                print("Daemon stopped")
                return
            time.sleep(0.1)
        
        print("Daemon did not stop gracefully")
        
    elif args.action == 'status':
        # Check status
        client = DojoClient()
        
        if not client.is_running():
            print("Daemon not running")
            return
        
        status = client.get_status()
        if status:
            print(f"Status: {status['status']}")
            print(f"PID: {status['pid']}")
            print(f"Ship: {status.get('ship', 'N/A')}")
            print(f"Connected: {status['connected']}")
            print(f"Uptime: {status['uptime']:.1f} seconds")
            print(f"Total events: {status['total_events']}")
        else:
            print("Could not get status")
        
    elif args.action == 'send':
        # Send command
        if not args.command:
            print("Command required")
            return
        
        client = DojoClient()
        result = client.send_command(args.command)
        
        if 'error' in result:
            print(f"Error: {result['error']}")
            return
        
        print(f"Sent command (ID: {result['command_id']})")
        
        # Wait for output
        print("Waiting for output...")
        output = client.wait_for_output(result['command_id'], timeout=args.timeout)
        
        if output:
            print("\nTerminal output:")
            print("-" * 60)
            print(output['terminal'])
            print("-" * 60)
        else:
            print("Timeout waiting for output")
        
    elif args.action == 'output':
        # Get current output
        client = DojoClient()
        output = client.get_output()
        
        if output:
            print("Current terminal:")
            print("-" * 60)
            print(output['terminal'])
            print("-" * 60)
            
            # Show slog messages if available
            if 'current_slog_messages' in output and output['current_slog_messages']:
                print("\nRecent slog messages:")
                print("-" * 60)
                for slog in output['current_slog_messages']:
                    print(f"[SLOG] {slog}")
                print("-" * 60)
            elif 'slog_messages' in output and output['slog_messages']:
                print("\nStored slog messages:")
                print("-" * 60)
                for slog in output['slog_messages']:
                    print(f"[SLOG] {slog}")
                print("-" * 60)
            
            print(f"\nTotal events: {output['total_events']}")
            print(f"Last update: {datetime.fromtimestamp(output['timestamp']).isoformat()}")
        else:
            print("No output available")
        
    elif args.action == 'watch':
        # Watch output continuously
        client = DojoClient()
        print("Watching output (Ctrl+C to stop)...")
        
        last_output = None
        try:
            while True:
                output = client.get_output()
                if output and output != last_output:
                    os.system('clear' if os.name == 'posix' else 'cls')
                    print("=== Dojo Output ===")
                    print(output['terminal'])
                    print(f"\nEvents: {output['total_events']} | Updated: {datetime.fromtimestamp(output['timestamp']).strftime('%H:%M:%S')}")
                    last_output = output
                
                time.sleep(0.5)
        except KeyboardInterrupt:
            print("\nStopped watching")


if __name__ == '__main__':
    main()
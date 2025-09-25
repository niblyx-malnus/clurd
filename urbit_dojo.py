#!/usr/bin/env python3
"""
urbit_dojo.py - Urbit Dojo Client

A Python client for interacting with Urbit's dojo terminal that provides:

1. **Terminal Buffer Simulation**: Faithfully reproduces webterm's visual output by
   implementing Urbit's blit (terminal command) protocol including cursor positioning,
   line clearing, and text rendering.

2. **Bell Detection & Syntax Analysis**: Detects when Urbit rejects input (bell events) 
   and pinpoints exactly where parsing fails. Enables systematic exploration of 
   Urbit's syntax rules.

3. **Tab Completion Extraction**: Clean extraction of completion suggestions and
   function signatures from Urbit's interactive help system.

4. **Real-time Stream Processing**: Captures both terminal output and slog (system log)
   messages during specified time windows, providing complete interaction visibility.

Key Approach: Instead of trying to parse text streams, we simulate the actual terminal
that Urbit communicates with, giving us pixel-perfect output formatting and the ability
to detect real-time parser feedback through bell events.

Usage:
    # Simple command execution (automatically adds \r to submit)
    dojo = UrbitDojo(url, ship, code)
    result = dojo.run("(add 5 4)")  # Automatically submits with \r
    
    # Manual character-by-character input (requires \r to submit)
    result = dojo.send_and_listen(['(', 'a', 'd', 'd', ' ', '5', ' ', '4', ')', '\r'])
    
    # Syntax probing with bell detection
    result = dojo.send_until_bell(['1','0','0','0'])  # Stops when rejected
    
    # Tab completion extraction
    completions = dojo.get_completions("+he")  # Returns: ["+hello", "+help"]
    
    # Command validation without execution
    validation = dojo.validate_command("(add 5 )")  # Shows syntax errors
"""

import json
import os
import queue
import re
import requests
import threading
import time
from dataclasses import dataclass
from typing import Dict, List, Optional


# Configuration Constants
DEFAULT_TERMINAL_WIDTH = 100000  # TODO: Remove width-based truncation entirely
DEFAULT_TERMINAL_HEIGHT = 24
DEFAULT_LISTEN_DURATION = 0.5
DEFAULT_CHAR_TIMEOUT = 0.5
DEFAULT_STREAM_START_DELAY = 0.5
DEFAULT_CLEAR_LINE_DELAY = 0.2
DEFAULT_CHAR_DELAY = 0.05
DEFAULT_POST_SEQUENCE_WAIT = 1.0

# Network timeouts
DEFAULT_REQUEST_TIMEOUT = 10.0
CHANNEL_TIMEOUT_BUFFER = 10.0


@dataclass
class DojoResponse:
    """Container for dojo command responses"""
    command: str
    output: str
    success: bool


@dataclass 
class StreamCapture:
    """Container for raw stream capture results"""
    input_sequence: List[str]      # Original character sequence sent
    terminal_events: List[Dict]    # Raw terminal blit events
    slog_messages: List[str]       # Slog messages during capture
    listen_duration: float         # How long we listened
    chars_sent: int               # How many chars were actually sent


@dataclass
class BellResponse:
    """Container for bell-aware sequence processing results"""
    input_sequence: List[str]      # Original character sequence attempted
    chars_accepted: int            # How many chars were accepted before bell
    chars_rejected: List[str]      # Characters that were rejected
    terminal_state: str            # What's visible on screen when bell occurred
    bell_position: int             # Index where first bell occurred
    full_output: str              # Complete terminal output including post-bell


class TerminalBuffer:
    """
    Terminal buffer that simulates Urbit's blit (terminal command) protocol.
    
    This enables clean output formatting. Instead of trying to parse text streams, 
    we faithfully implement the terminal commands that Urbit sends, giving us 
    pixel-perfect reproduction of what appears in webterm.
    
    Supported Blit Commands:
    - put: Write text at cursor position
    - klr: Write styled text at cursor position  
    - nel: Move cursor to start of next line
    - hop: Set cursor position (absolute or column-only)
    - wyp: Clear current line from cursor to end
    - clr: Clear entire screen
    - bel: Bell/rejection signal (recorded for syntax analysis)
    
    The terminal buffer automatically handles:
    - Cursor positioning and bounds checking
    - Line scrolling when cursor exceeds screen height
    - Text wrapping and overwriting
    - Screen clearing and line wiping
    """
    
    def __init__(self, width: int = DEFAULT_TERMINAL_WIDTH, height: int = DEFAULT_TERMINAL_HEIGHT):
        self.width = width
        self.height = height
        self.cursor_x = 0  # Column position (0-based)
        self.cursor_y = 0  # Row position (0-based)
        # Initialize screen buffer - each row is a string of fixed width
        self.screen = [' ' * width for _ in range(height)]
        # Track if any bell events occurred (indicates input rejection)
        self.bell_occurred = False
    
    def write_text(self, text: str):
        """Write text at current cursor position"""
        for char in text:
            if self.cursor_x < self.width and self.cursor_y < self.height:
                # Convert screen line to list for modification
                line = list(self.screen[self.cursor_y])
                line[self.cursor_x] = char
                self.screen[self.cursor_y] = ''.join(line)
                self.cursor_x += 1
    
    def newline(self):
        """Move cursor to start of next line"""
        self.cursor_y += 1
        self.cursor_x = 0
        # If we go past bottom, scroll up
        if self.cursor_y >= self.height:
            self.scroll_up()
            self.cursor_y = self.height - 1
    
    def set_cursor_col(self, col: int):
        """Set cursor column on current row"""
        self.cursor_x = min(max(0, col), self.width - 1)
    
    def set_cursor_pos(self, x: int, y: int):
        """Set absolute cursor position"""
        self.cursor_x = min(max(0, x), self.width - 1)
        self.cursor_y = min(max(0, y), self.height - 1)
    
    def clear_line(self):
        """Clear current line from cursor to end"""
        if self.cursor_y < self.height:
            line = list(self.screen[self.cursor_y])
            # Clear from cursor position to end of line
            for i in range(self.cursor_x, self.width):
                line[i] = ' '
            self.screen[self.cursor_y] = ''.join(line)
    
    def clear_screen(self):
        """Clear entire screen"""
        self.screen = [' ' * self.width for _ in range(self.height)]
        self.cursor_x = 0
        self.cursor_y = 0
    
    def scroll_up(self):
        """Expand screen buffer instead of scrolling to preserve all content"""
        # Add empty line at bottom instead of removing top line
        self.screen.append(' ' * self.width)
        # Increase height to accommodate new content
        self.height += 1
    
    def get_visible_text(self) -> str:
        """Return all visible text as a string with line breaks"""
        # Remove trailing empty lines and spaces
        lines = []
        for line in self.screen:
            # Keep line if it has non-space content
            stripped = line.rstrip()
            if stripped or lines:  # Keep empty lines between content
                lines.append(stripped)
        
        # Remove trailing empty lines
        while lines and not lines[-1]:
            lines.pop()
        
        return '\n'.join(lines)
    
    def has_bell(self) -> bool:
        """Check if a bell event occurred"""
        return self.bell_occurred
    
    def record_bell(self):
        """Record that a bell event occurred"""
        self.bell_occurred = True


class UrbitDojo:
    """
    Interface to Urbit's dojo terminal with syntax analysis capabilities.
    
    Provides multiple interaction modes:
    
    1. **Simple Command Execution**: Traditional text-in, text-out commands
       dojo.run("(add 5 4)")  # Returns: "9"
    
    2. **Bell-Aware Syntax Probing**: Send characters until rejection, perfect for 
       exploring Urbit's parsing rules and syntax validation
       dojo.send_until_bell(['1','0','0','0'])  # Stops at first rejected character
    
    3. **Tab Completion**: Extract completion suggestions and function signatures
       dojo.get_completions("+he")  # Returns: ["+hello", "+help"]
    
    4. **Command Validation**: Test syntax without execution 
       dojo.validate_command("(add 5 )")  # Shows exactly where syntax fails
    
    5. **Raw Stream Processing**: Full control over character sequences and timing
       dojo.send_and_listen(['(', 'a', 'd', 'd'], duration=2.0)
    
    The client uses dual-channel architecture:
    - HTTP channel API for terminal I/O (blit commands)
    - EventSource stream for slog (system log) messages
    
    Authentication is handled automatically via Urbit's +code system.
    """
    
    def __init__(self, ship_url: str, ship_name: str, access_code: str):
        self.ship_url = ship_url
        self.ship_name = ship_name
        self.access_code = access_code
        self.cookies = None
        self.channel_id = None
        self.session_name = ""
        
        # Persistent slog connection attributes
        self.slog_queue = queue.Queue()
        self.slog_thread = None
        self.slog_stop_event = threading.Event()
        self.slog_connected = False
    
    def _start_persistent_slog_capture(self):
        """Start persistent slog message capture in background thread"""
        def capture_slog():
            try:
                response = requests.get(
                    f"{self.ship_url}/~_~/slog",
                    cookies=self.cookies,
                    stream=True,
                    timeout=None  # No timeout for persistent connection
                )
                
                if response.status_code != 200:
                    return
                
                self.slog_connected = True
                
                for line in response.iter_lines():
                    if self.slog_stop_event.is_set():
                        break
                        
                    if line:
                        line_str = line.decode('utf-8')
                        # Extract slog data, removing 'data:' prefix
                        if line_str.startswith('data:'):
                            slog_data = line_str[5:].strip()
                            if slog_data:
                                # Store with timestamp for correlation
                                message_data = {
                                    'timestamp': time.time(),
                                    'message': slog_data
                                }
                                self.slog_queue.put(message_data)
                                
            except Exception:
                self.slog_connected = False
                pass
        
        self.slog_thread = threading.Thread(target=capture_slog, daemon=True)
        self.slog_thread.start()
    
    def _send_terminal_resize(self, width: int, height: int):
        """Send terminal dimensions to Urbit via blew task"""
        try:
            resize_data = [{
                "id": 2,
                "action": "poke",
                "ship": self.ship_name,
                "app": "herm",
                "mark": "herm-task",
                "json": {
                    "session": self.session_name,
                    "blew": {
                        "w": width,
                        "h": height
                    }
                }
            }]
            
            requests.post(
                f"{self.ship_url}/~/channel/{self.channel_id}",
                json=resize_data,
                cookies=self.cookies
            )
        except Exception:
            pass  # Non-critical if resize fails
    
    def _stop_slog_capture(self):
        """Stop the persistent slog capture"""
        if self.slog_thread and self.slog_thread.is_alive():
            self.slog_stop_event.set()
            self.slog_thread.join(timeout=2)
        self.slog_connected = False
        
    def connect(self) -> bool:
        """Connect to Urbit and establish authenticated session"""
        try:
            # Authenticate
            auth_response = requests.post(
                f"{self.ship_url}/~/login",
                data={'password': self.access_code},
                headers={'Content-Type': 'application/x-www-form-urlencoded'},
                allow_redirects=False
            )
            
            if auth_response.status_code not in [200, 204]:
                return False
                
            self.cookies = auth_response.cookies.get_dict()
            
            # Open channel
            self.channel_id = f"{int(time.time() * 1000)}-dojo"
            channel_response = requests.post(
                f"{self.ship_url}/~/channel/{self.channel_id}",
                json=[],
                cookies=self.cookies
            )
            
            if channel_response.status_code != 204:
                return False
            
            # Subscribe to terminal output
            sub_data = [{
                "id": 1,
                "action": "subscribe",
                "ship": self.ship_name,
                "app": "herm",
                "path": f"/session/{self.session_name}/view"
            }]
            
            sub_response = requests.post(
                f"{self.ship_url}/~/channel/{self.channel_id}",
                json=sub_data,
                cookies=self.cookies
            )
            
            if sub_response.status_code == 204:
                # Send terminal dimensions to Urbit
                self._send_terminal_resize(DEFAULT_TERMINAL_WIDTH, DEFAULT_TERMINAL_HEIGHT)
                
                # Start persistent slog capture after successful connection
                self._start_persistent_slog_capture()
                # Give slog connection time to establish
                time.sleep(0.5)
                return True
            
            return False
            
        except Exception:
            return False
    
    def disconnect(self):
        """Disconnect from Urbit and clean up connections"""
        self._stop_slog_capture()
        self.cookies = None
        self.channel_id = None
    
    def send_and_listen(self, chars: List[str], listen_duration: float = DEFAULT_LISTEN_DURATION) -> StreamCapture:
        """
        Send a sequence of characters and capture ALL events for the specified duration.
        
        IMPORTANT: Choose listen_duration based on expected output timing:
        - Quick commands (arithmetic): 1-2 seconds  
        - Tab completion: 2-3 seconds
        - File operations: 5-10 seconds
        - Network requests: 10-30 seconds
        - Long computations: 30+ seconds
        
        The method captures whatever appears during the window - if output arrives
        after listen_duration expires, it will be missed.
        
        Args:
            chars: List of characters including special keys ('\t', '\n', '\b', etc.)
            listen_duration: How long to listen for events after sending the last character
            
        Returns:
            StreamCapture with all raw events captured during the time window
        """
        if not self.cookies or not self.channel_id:
            return StreamCapture(chars, [], [], listen_duration, 0)
        
        # Capture terminal events in background
        events = []
        stop_event = threading.Event()
        
        def capture_events():
            try:
                response = requests.get(
                    f"{self.ship_url}/~/channel/{self.channel_id}",
                    cookies=self.cookies,
                    stream=True,
                    timeout=listen_duration + 10
                )
                
                for line in response.iter_lines():
                    if stop_event.is_set():
                        break
                        
                    if line and line.decode('utf-8').startswith('data: '):
                        try:
                            data = json.loads(line.decode('utf-8')[6:])
                            events.append(data)
                        except:
                            pass
                            
            except Exception:
                pass
        
        # Start terminal event capture
        thread = threading.Thread(target=capture_events, daemon=True)
        thread.start()
        
        time.sleep(0.5)  # Let stream start
        
        # Record sequence start time for slog correlation
        sequence_start_time = time.time()
        chars_sent = 0
        
        try:
            # Send each character in the sequence
            id_counter = 100
            for i, char in enumerate(chars):
                self._send_character(char, id_counter)
                chars_sent = i + 1
                id_counter += 1
                time.sleep(0.05)
            
            # Listen for the specified duration
            time.sleep(listen_duration)
            
        except Exception:
            # If we hit an error, we still want to report how far we got
            pass
        finally:
            stop_event.set()
            
        # Collect slog messages that arrived during the listening window
        sequence_end_time = time.time()
        correlated_slog_messages = self._get_correlated_slog_messages(
            sequence_start_time, sequence_end_time
        )
        
        return StreamCapture(
            input_sequence=chars,
            terminal_events=events,
            slog_messages=correlated_slog_messages,
            listen_duration=listen_duration,
            chars_sent=chars_sent
        )
    
    def send_until_bell(self, chars: List[str], timeout_per_char: float = DEFAULT_CHAR_TIMEOUT) -> BellResponse:
        """
        Send characters one by one until a bell (rejection) occurs.
        
        This enables syntax analysis. Urbit sends bell events when it rejects input,
        allowing us to probe exactly where parsing fails. Useful for understanding 
        Urbit's syntax rules and parser behavior.
        
        Example:
            # Test invalid number syntax
            result = dojo.send_until_bell(['1','0','0','0','0','0','0','0'])
            # Returns: chars_accepted=3, terminal_state="100", rejected=['0','0','0','0','0']
            
        Args:
            chars: List of characters to send sequentially
            timeout_per_char: How long to wait after each character for response
            
        Returns:
            BellResponse containing:
            - chars_accepted: How many characters Urbit accepted before rejection
            - chars_rejected: List of characters that were rejected  
            - terminal_state: What's visible on screen when bell occurred
            - bell_position: Index where first bell occurred (-1 if no bell)
        """
        if not self.cookies or not self.channel_id:
            return BellResponse(chars, 0, chars, "Not connected", 0, "Not connected")
        
        # Start event capture
        events = []
        stop_event = threading.Event()
        
        def capture_events():
            try:
                response = requests.get(
                    f"{self.ship_url}/~/channel/{self.channel_id}",
                    cookies=self.cookies,
                    stream=True,
                    timeout=len(chars) * timeout_per_char + 10
                )
                
                for line in response.iter_lines():
                    if stop_event.is_set():
                        break
                    if line and line.decode('utf-8').startswith('data: '):
                        try:
                            data = json.loads(line.decode('utf-8')[6:])
                            events.append(data)
                        except:
                            pass
            except Exception:
                pass
        
        # Start capture thread
        thread = threading.Thread(target=capture_events, daemon=True)
        thread.start()
        time.sleep(DEFAULT_STREAM_START_DELAY)
        
        # Send characters one by one until bell
        chars_accepted = 0
        id_counter = 200
        
        try:
            for i, char in enumerate(chars):
                # Send the character
                self._send_character(char, id_counter)
                id_counter += 1
                time.sleep(timeout_per_char)
                
                # Check if we got a bell by analyzing events so far
                terminal = TerminalBuffer()
                for event in events:
                    if 'json' in event and 'mor' in event['json']:
                        for blit in event['json']['mor']:
                            self._process_blit(blit, terminal)
                
                if terminal.has_bell():
                    # Bell detected - stop here
                    chars_accepted = i  # Don't count the char that caused the bell
                    break
                else:
                    chars_accepted = i + 1
                    
        except Exception:
            pass
        finally:
            stop_event.set()
        
        # Wait for final events to arrive
        time.sleep(DEFAULT_POST_SEQUENCE_WAIT)
        
        # Process all events to get final terminal state
        terminal_output = self._extract_output(events)
        
        # Determine what was rejected
        chars_rejected = chars[chars_accepted:] if chars_accepted < len(chars) else []
        bell_position = chars_accepted if chars_accepted < len(chars) else -1
        
        return BellResponse(
            input_sequence=chars,
            chars_accepted=chars_accepted,
            chars_rejected=chars_rejected,
            terminal_state=terminal_output,
            bell_position=bell_position,
            full_output=terminal_output
        )
    
    def get_completions(self, prefix: str) -> List[str]:
        """
        Get tab completion suggestions for a prefix
        
        Args:
            prefix: String to get completions for
            
        Returns:
            List of completion suggestions
        """
        if not self.cookies or not self.channel_id:
            return []
        
        # Send prefix + double tab to get all suggestions
        chars = list(prefix) + ['\t', '\t']
        result = self.send_and_listen(chars, listen_duration=2.0)
        
        # Extract completion suggestions from terminal output
        output = self._extract_output(result.terminal_events)
        lines = output.split('\n')
        
        completions = []
        for line in lines:
            # Look for lines that contain completion patterns
            if '::' in line and not line.startswith('~'):
                # Extract the completion name (before the '::')
                parts = line.split('::')[0].strip()
                if parts and not parts.startswith('-----'):
                    completions.append(parts)
            elif '->' in line and '[' in line and ']' in line:
                # Function signature like "add  [a=@ b=@] -> @"
                parts = line.split('[')[0].strip()
                if parts:
                    completions.append(parts)
        
        return completions
    
    def validate_command(self, command: str) -> Dict:
        """
        Validate a command without executing it
        
        Args:
            command: Command to validate
            
        Returns:
            Dict with validation results
        """
        chars = list(command)
        bell_result = self.send_until_bell(chars)
        
        is_valid = bell_result.chars_accepted == len(chars)
        
        return {
            'is_valid': is_valid,
            'accepted_portion': ''.join(chars[:bell_result.chars_accepted]),
            'rejected_portion': ''.join(bell_result.chars_rejected),
            'error_position': bell_result.bell_position if not is_valid else None,
            'terminal_state': bell_result.terminal_state,
            'chars_accepted': bell_result.chars_accepted,
            'total_chars': len(chars)
        }
    
    def explore_syntax(self, base: str, test_chars: List[str]) -> Dict:
        """
        Systematically explore what characters Urbit will accept after a base string
        
        Args:
            base: Base string to build on
            test_chars: List of characters to test
            
        Returns:
            Dict mapping each test char to whether it was accepted
        """
        results = {}
        base_chars = list(base)
        
        for char in test_chars:
            test_sequence = base_chars + [char]
            bell_result = self.send_until_bell(test_sequence)
            
            # Character is accepted if we got through the whole sequence
            accepted = bell_result.chars_accepted == len(test_sequence)
            results[char] = {
                'accepted': accepted,
                'chars_accepted': bell_result.chars_accepted,
                'terminal_state': bell_result.terminal_state
            }
            
            # Small delay between tests
            time.sleep(0.1)
        
        return results
    
    def run(self, command: str, timeout: float = DEFAULT_REQUEST_TIMEOUT) -> DojoResponse:
        """
        Run a command in Urbit's dojo and return the result.
        
        This is a convenience wrapper around send_and_listen() for backward compatibility.
        For commands with unpredictable timing, use send_and_listen() directly with an
        appropriate listen_duration.
        
        Args:
            command: Hoon expression to evaluate
            timeout: How long to wait for response (captures output during this window)
            
        Returns:
            DojoResponse with whatever output was captured during the timeout window
        """
        # Convert string command to character sequence with carriage return (enter)
        chars = list(command) + ['\r']
        
        # Use send_and_listen to process the command
        result = self.send_and_listen(chars, timeout)
        
        # Extract text output from events for backward compatibility
        terminal_output = self._extract_output(result.terminal_events)
        
        # Combine terminal output with slog messages
        all_output = terminal_output
        if result.slog_messages:
            slog_output = '\n'.join(result.slog_messages)
            if all_output:
                all_output = f"{all_output}\n{slog_output}"
            else:
                all_output = slog_output
        
        # Convert StreamCapture back to DojoResponse for backward compatibility
        return DojoResponse(
            command=command,
            output=all_output,
            success=result.chars_sent == len(chars)
        )
    
    def _get_correlated_slog_messages(self, start_time: float, end_time: float) -> List[str]:
        """Get slog messages that arrived within the specified time window"""
        correlated_messages = []
        
        # Collect all messages from the queue that fall within the time window
        temp_messages = []
        try:
            while True:
                try:
                    message_data = self.slog_queue.get_nowait()
                    if start_time <= message_data['timestamp'] <= end_time:
                        correlated_messages.append(message_data['message'])
                    elif message_data['timestamp'] > end_time:
                        # Put back messages that are too new (for future commands)
                        temp_messages.append(message_data)
                    # Drop messages that are too old
                except queue.Empty:
                    break
        except Exception:
            pass
        
        # Put back messages that were too new
        for msg in temp_messages:
            try:
                self.slog_queue.put_nowait(msg)
            except queue.Full:
                pass  # Queue is full, drop the message
        
        return correlated_messages
    
    def _send_clear_line(self):
        """Clear the current dojo line"""
        clear_data = [{
            "id": 2,
            "action": "poke",
            "ship": self.ship_name,
            "app": "herm",
            "mark": "herm-task",
            "json": {
                "session": self.session_name,
                "belt": {"mod": {"mod": "ctl", "key": "u"}}
            }
        }]
        requests.post(f"{self.ship_url}/~/channel/{self.channel_id}", 
                     json=clear_data, cookies=self.cookies)
    
    def _send_character(self, char: str, id_num: int):
        """Send a single character to the dojo with proper Belt encoding"""
        # Handle arrow keys
        if char == 'ARROW_UP':
            belt = {"aro": "u"}
        elif char == 'ARROW_DOWN':
            belt = {"aro": "d"}
        elif char == 'ARROW_LEFT':
            belt = {"aro": "l"}
        elif char == 'ARROW_RIGHT':
            belt = {"aro": "r"}
        else:
            # Get ASCII code of character
            c = ord(char)
            
            # Handle special characters according to webterm's readInput logic
            if c == 9:  # Tab -> Ctrl+I
                belt = {"mod": {"mod": "ctl", "key": "i"}}
            elif c == 13:  # Enter/newline -> ret
                belt = {"ret": None}
            elif c == 8 or c == 127:  # Backspace
                belt = {"bac": None}
            elif 1 <= c <= 26:  # Other control characters
                key_char = chr(96 + c)  # Convert to corresponding letter
                if key_char != 'd':  # Prevent remote shutdowns
                    belt = {"mod": {"mod": "ctl", "key": key_char}}
                else:
                    return  # Skip Ctrl+D
            elif 32 <= c <= 126:  # Regular printable characters
                belt = {"txt": [char]}
            else:
                # Skip other characters (non-printable, etc.)
                return
        
        char_data = [{
            "id": id_num,
            "action": "poke",
            "ship": self.ship_name,
            "app": "herm",
            "mark": "herm-task",
            "json": {
                "session": self.session_name,
                "belt": belt
            }
        }]
        requests.post(f"{self.ship_url}/~/channel/{self.channel_id}", 
                     json=char_data, cookies=self.cookies)
    
    def _send_belt(self, belt: Dict, id_num: int):
        """Send a belt (keyboard input) to the dojo"""
        belt_data = [{
            "id": id_num,
            "action": "poke",
            "ship": self.ship_name,
            "app": "herm",
            "mark": "herm-task",
            "json": {
                "session": self.session_name,
                "belt": belt
            }
        }]
        requests.post(f"{self.ship_url}/~/channel/{self.channel_id}", 
                     json=belt_data, cookies=self.cookies)
    
    def _create_belts_from_string(self, text: str) -> List[Dict]:
        """
        Convert string to belts using webterm's batching approach.
        
        Mimics webterm's readInput function to batch consecutive printable 
        characters into single belts, dramatically reducing HTTP requests.
        """
        belts = []
        strap = ""
        
        for char in text:
            c = ord(char)
            
            # Accumulate printable characters (same logic as webterm)
            if c >= 32 and c != 127:
                strap += char
            else:
                # Flush accumulated text as single belt
                if strap:
                    belts.append({"txt": list(strap)})
                    strap = ""
                
                # Handle special characters individually
                if c == 0:
                    # Bell - skip (webterm writes \x07 to terminal)
                    pass
                elif c == 8 or c == 127:  # Backspace
                    belts.append({"bac": None})
                elif c == 13:  # Enter/return
                    belts.append({"ret": None})
                elif c == 9:  # Tab -> Ctrl+I
                    belts.append({"mod": {"mod": "ctl", "key": "i"}})
                elif 1 <= c <= 26:  # Other control characters
                    key_char = chr(96 + c)
                    if key_char != 'd':  # Prevent remote shutdowns
                        belts.append({"mod": {"mod": "ctl", "key": key_char}})
                # Skip other non-printable characters
        
        # Flush any remaining accumulated text
        if strap:
            belts.append({"txt": list(strap)})
        
        return belts

    def _create_belts_from_chars(self, chars: List[str]) -> List[Dict]:
        """
        Convert parsed character list to belts, handling special arrow keys.
        
        This handles both regular characters (for batching) and special
        arrow key strings like 'ARROW_UP'.
        """
        belts = []
        strap = ""
        
        for char in chars:
            # Handle arrow keys first
            if char == 'ARROW_UP':
                # Flush any accumulated text first
                if strap:
                    belts.append({"txt": list(strap)})
                    strap = ""
                belts.append({"aro": "u"})
            elif char == 'ARROW_DOWN':
                if strap:
                    belts.append({"txt": list(strap)})
                    strap = ""
                belts.append({"aro": "d"})
            elif char == 'ARROW_LEFT':
                if strap:
                    belts.append({"txt": list(strap)})
                    strap = ""
                belts.append({"aro": "l"})
            elif char == 'ARROW_RIGHT':
                if strap:
                    belts.append({"txt": list(strap)})
                    strap = ""
                belts.append({"aro": "r"})
            else:
                # Handle regular characters (same logic as _create_belts_from_string)
                c = ord(char)
                
                # Accumulate printable characters
                if c >= 32 and c != 127:
                    strap += char
                else:
                    # Flush accumulated text as single belt
                    if strap:
                        belts.append({"txt": list(strap)})
                        strap = ""
                    
                    # Handle special characters individually
                    if c == 8 or c == 127:  # Backspace
                        belts.append({"bac": None})
                    elif c == 13:  # Enter/return
                        belts.append({"ret": None})
                    elif c == 9:  # Tab -> Ctrl+I
                        belts.append({"mod": {"mod": "ctl", "key": "i"}})
                    elif 1 <= c <= 26:  # Other control characters
                        key_char = chr(96 + c)
                        if key_char != 'd':  # Prevent remote shutdowns
                            belts.append({"mod": {"mod": "ctl", "key": key_char}})
        
        # Flush any remaining accumulated text
        if strap:
            belts.append({"txt": list(strap)})
        
        return belts
    
    def _is_at_clean_prompt(self) -> bool:
        """Check if we're currently at a clean dojo prompt"""
        if not self.cookies or not self.channel_id:
            return False
        
        # Capture current terminal state without sending anything
        result = self.send_and_listen([], 0.1)  # Just listen briefly
        current_output = self._extract_output(result.terminal_events)
        
        # Check if the last line looks like a clean prompt
        lines = current_output.strip().split('\n')
        if lines:
            last_line = lines[-1].strip()
            # Check if it's a clean prompt: ~ship:dojo> with no command characters after >
            prompt_parts = last_line.split(':dojo>')
            
            has_command_chars = any(char in prompt_parts[0] for char in '()[]{}+*/%=<>|&')
            
            is_clean = (len(prompt_parts) == 2 and  # Splits into exactly 2 parts
                       prompt_parts[0].startswith('~') and  # Ship name starts with ~
                       prompt_parts[1] == '' and  # Nothing after >
                       not has_command_chars)  # No command chars in ship name
            return is_clean
        return False
    
    def send_chars_batched(self, chars: List[str], listen_duration: float = DEFAULT_LISTEN_DURATION) -> StreamCapture:
        """
        Send parsed character list using webterm's batching approach with arrow key support.
        
        This version handles both regular characters and special arrow key strings.
        
        Args:
            chars: List of characters including special strings like 'ARROW_UP'
            listen_duration: How long to listen for response
            
        Returns:
            StreamCapture with terminal events and timing
        """
        if not self.cookies or not self.channel_id:
            return StreamCapture(chars, [], [], listen_duration, 0)
        
        # Create belts using our enhanced logic that handles arrow keys
        belts = self._create_belts_from_chars(chars)
        
        # Start event capture
        events = []
        stop_event = threading.Event()
        
        def capture_events():
            try:
                response = requests.get(
                    f"{self.ship_url}/~/channel/{self.channel_id}",
                    cookies=self.cookies,
                    stream=True,
                    timeout=listen_duration + 10
                )
                
                for line in response.iter_lines():
                    if stop_event.is_set():
                        break
                    if line and line.decode('utf-8').startswith('data: '):
                        try:
                            data = json.loads(line.decode('utf-8')[6:])
                            events.append(data)
                        except:
                            pass
            except Exception:
                pass
        
        # Start terminal event capture
        thread = threading.Thread(target=capture_events, daemon=True)
        thread.start()
        time.sleep(DEFAULT_STREAM_START_DELAY)
        
        # Record sequence start time for slog correlation
        sequence_start_time = time.time()
        belts_sent = 0
        
        try:
            # Send belts (much fewer HTTP requests than character-by-character)
            id_counter = 300
            for belt in belts:
                self._send_belt(belt, id_counter)
                belts_sent += 1
                id_counter += 1
                time.sleep(0.02)  # Shorter delay between belts than between chars
            
            # Listen for response
            time.sleep(listen_duration)
            
        except Exception:
            pass
        finally:
            stop_event.set()
        
        # Collect correlated slog messages
        sequence_end_time = time.time()
        correlated_slog_messages = self._get_correlated_slog_messages(
            sequence_start_time, sequence_end_time
        )
        
        return StreamCapture(
            input_sequence=chars,
            terminal_events=events,
            slog_messages=correlated_slog_messages,
            listen_duration=listen_duration,
            chars_sent=len(chars)  # Report original command length for compatibility
        )
    
    def send_command_batched(self, command: str, listen_duration: float = DEFAULT_LISTEN_DURATION) -> StreamCapture:
        """
        Send command using webterm's batching approach for improved performance.
        
        This dramatically reduces HTTP requests by batching consecutive printable 
        characters into single belts, just like webterm does for pasted text.
        
        Example: "(add 5 4)" becomes just 2 HTTP requests instead of 9:
        1. { txt: ['(','a','d','d',' ','5',' ','4',')'] }
        2. { ret: None }
        
        Args:
            command: Command string to send
            listen_duration: How long to listen for response
            
        Returns:
            StreamCapture with terminal events and timing
        """
        if not self.cookies or not self.channel_id:
            return StreamCapture(list(command), [], [], listen_duration, 0)
        
        # Create belts using webterm's batching logic
        belts = self._create_belts_from_string(command)
        
        # Start event capture
        events = []
        stop_event = threading.Event()
        
        def capture_events():
            try:
                response = requests.get(
                    f"{self.ship_url}/~/channel/{self.channel_id}",
                    cookies=self.cookies,
                    stream=True,
                    timeout=listen_duration + 10
                )
                
                for line in response.iter_lines():
                    if stop_event.is_set():
                        break
                    if line and line.decode('utf-8').startswith('data: '):
                        try:
                            data = json.loads(line.decode('utf-8')[6:])
                            events.append(data)
                        except:
                            pass
            except Exception:
                pass
        
        # Start terminal event capture
        thread = threading.Thread(target=capture_events, daemon=True)
        thread.start()
        time.sleep(DEFAULT_STREAM_START_DELAY)
        
        # Record sequence start time for slog correlation
        sequence_start_time = time.time()
        belts_sent = 0
        
        try:
            # Send belts (much fewer HTTP requests than character-by-character)
            id_counter = 300
            for belt in belts:
                self._send_belt(belt, id_counter)
                belts_sent += 1
                id_counter += 1
                time.sleep(0.02)  # Shorter delay between belts than between chars
            
            # Listen for response
            time.sleep(listen_duration)
            
        except Exception:
            pass
        finally:
            stop_event.set()
        
        # Collect correlated slog messages
        sequence_end_time = time.time()
        correlated_slog_messages = self._get_correlated_slog_messages(
            sequence_start_time, sequence_end_time
        )
        
        return StreamCapture(
            input_sequence=list(command),
            terminal_events=events,
            slog_messages=correlated_slog_messages,
            listen_duration=listen_duration,
            chars_sent=len(command)  # Report original command length for compatibility
        )
    
    def _send_enter(self, id_num: int):
        """Send Enter to execute the command"""
        enter_data = [{
            "id": id_num,
            "action": "poke",
            "ship": self.ship_name,
            "app": "herm",
            "mark": "herm-task",
            "json": {
                "session": self.session_name,
                "belt": {"ret": None}
            }
        }]
        requests.post(f"{self.ship_url}/~/channel/{self.channel_id}", 
                     json=enter_data, cookies=self.cookies)
    
    def _extract_output(self, events: List[Dict]) -> str:
        """
        Simulate terminal output by processing blit commands.
        
        Core approach: instead of trying to parse text streams, we faithfully 
        execute Urbit's terminal commands on a virtual terminal buffer, giving 
        us pixel-perfect output formatting.
        """
        terminal = TerminalBuffer()
        
        # Process all events through the terminal buffer
        for event in events:
            if 'json' in event and 'mor' in event['json']:
                for blit in event['json']['mor']:
                    self._process_blit(blit, terminal)
        
        return terminal.get_visible_text()
    
    def _process_blit(self, blit: Dict, terminal: TerminalBuffer):
        """
        Process a single blit (terminal command) on the given terminal buffer.
        
        Blit Commands Reference:
        - mor: Multiple blits (process each recursively)
        - put: Write plain text at cursor position  
        - klr: Write styled text at cursor position
        - nel: Newline (move cursor to start of next line)
        - hop: Set cursor position (int=column, dict=absolute {x,y})
        - wyp: Wipe current line from cursor to end
        - clr: Clear entire screen
        - bel: Bell (rejection signal - recorded for syntax analysis)
        
        This faithfully implements Urbit's terminal protocol as seen in webterm.
        """
        if 'mor' in blit:
            # Multiple blits - process each recursively
            for sub_blit in blit['mor']:
                self._process_blit(sub_blit, terminal)
                
        elif 'put' in blit:
            # Plain text output
            text = ''.join(blit['put'])
            terminal.write_text(text)
            
        elif 'klr' in blit:
            # Styled text output (we ignore styling, just extract text)
            for styled_text in blit['klr']:
                if 'text' in styled_text:
                    text = ''.join(styled_text['text'])
                    terminal.write_text(text)
                    
        elif 'nel' in blit:
            # Newline
            terminal.newline()
            
        elif 'hop' in blit:
            # Cursor positioning
            if isinstance(blit['hop'], int):
                # Column-only positioning
                terminal.set_cursor_col(blit['hop'])
            else:
                # Absolute positioning {x, y}
                terminal.set_cursor_pos(blit['hop']['x'], blit['hop']['y'])
                
        elif 'wyp' in blit:
            # Wipe (clear) current line from cursor to end
            terminal.clear_line()
            
        elif 'clr' in blit:
            # Clear entire screen
            terminal.clear_screen()
            
        elif 'bel' in blit:
            # Bell - indicates input rejection (crucial for syntax analysis)
            terminal.record_bell()
            
        # Ignore other blit types: sag, sav, url (file operations, links)


def get_command(steps_back: int, timeout: float = None) -> str:
    """
    Navigate to a specific position in dojo history with a clean reset.
    
    This function:
    1. Clears the current prompt
    2. Hits Enter to reset history cursor position
    3. Goes up the specified number of steps
    4. Leaves the command ready (no final Enter)
    
    Args:
        steps_back: Number of commands to go back in history
        timeout: How long to wait for response
        
    Returns:
        The terminal output showing the historical command
    """
    config = load_config()
    
    if not all([config['ship_name'], config['access_code']]):
        return "Error: Missing ship configuration. Create config.json or set environment variables."
    
    dojo = UrbitDojo(config['ship_url'], config['ship_name'], config['access_code'])
    
    if not dojo.connect():
        return "Error: Could not connect to Urbit ship"
    
    # Step 1: Clear current prompt and reset history position
    clear_and_reset_chars = ['\x15', '\r']  # Ctrl+U (clear line) then Enter (reset history cursor)
    clear_result = dojo.send_and_listen(clear_and_reset_chars, 0.5)
    
    # Step 2: Navigate up the specified number of steps
    if steps_back > 0:
        navigation_chars = ['ARROW_UP'] * steps_back  # Go up N times
        
        # Use batched sending for the navigation
        listen_timeout = timeout if timeout is not None else DEFAULT_LISTEN_DURATION
        result = dojo.send_chars_batched(navigation_chars, listen_timeout)
        
        # Extract terminal output
        terminal_output = dojo._extract_output(result.terminal_events)
        
        # Add slog messages
        all_output = terminal_output
        if result.slog_messages:
            slog_output = '\n'.join([f"[SLOG] {msg}" for msg in result.slog_messages])
            if all_output:
                all_output = f"{all_output}\n{slog_output}"
            else:
                all_output = slog_output
        
        return all_output
    else:
        # If steps_back is 0 or negative, just return the cleared prompt
        return dojo._extract_output(clear_result.terminal_events)


def load_config():
    """Load configuration from config.json or environment variables"""
    # Try to load from config.json
    config_path = os.path.join(os.path.dirname(__file__), 'config.json')
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            return json.load(f)
    
    # Fall back to environment variables
    return {
        'ship_url': os.environ.get('URBIT_URL', 'http://localhost:80'),
        'ship_name': os.environ.get('URBIT_SHIP', ''),
        'access_code': os.environ.get('URBIT_CODE', '')
    }


def parse_command_string(cmd_str: str) -> List[str]:
    """
    Parse command string with escape sequences to character list
    
    Handles escape sequences like \t, \n, \b, etc.
    
    Args:
        cmd_str: Command string that may contain escape sequences
        
    Returns:
        List of individual characters including special characters
    """
    chars = []
    i = 0
    while i < len(cmd_str):
        if cmd_str[i] == '\\' and i + 1 < len(cmd_str):
            # Check for arrow key sequences
            if cmd_str[i:i+3] == '\\up':
                chars.append('ARROW_UP')
                i += 3
                continue
            elif cmd_str[i:i+5] == '\\down':
                chars.append('ARROW_DOWN')
                i += 5
                continue
            elif cmd_str[i:i+5] == '\\left':
                chars.append('ARROW_LEFT')
                i += 5
                continue
            elif cmd_str[i:i+6] == '\\right':
                chars.append('ARROW_RIGHT')
                i += 6
                continue
            
            # Handle regular escape sequences
            next_char = cmd_str[i + 1]
            if next_char == 't':
                chars.append('\t')
            elif next_char == 'n':
                chars.append('\n')
            elif next_char == 'b':
                chars.append('\b')
            elif next_char == 'r':
                chars.append('\r')
            elif next_char == '\\':
                chars.append('\\')
            elif next_char == '!':
                chars.append('!')
            else:
                # Unknown escape sequence, keep both characters
                chars.append('\\')
                chars.append(next_char)
            i += 2
        else:
            # Regular character
            chars.append(cmd_str[i])
            i += 1
    
    return chars


def quick_run(command: str, timeout: float = None, no_enter: bool = False) -> str:
    """
    Quick function to run a single command
    
    Supports escape sequences like \t (tab), \n (newline), \b (backspace)
    
    Usage:
        result = quick_run("(add 5 4)")         # "9"
        result = quick_run("+he\\t")            # Tab completion output
        result = quick_run("(add\\n5 4)")       # Multi-line expression
    """
    config = load_config()
    
    if not all([config['ship_name'], config['access_code']]):
        return "Error: Missing ship configuration. Create config.json or set environment variables."
    
    dojo = UrbitDojo(config['ship_url'], config['ship_name'], config['access_code'])
    
    if not dojo.connect():
        return "Error: Could not connect to Urbit ship"
    
    # Clear the dojo first with Ctrl+E then Ctrl+U  
    clear_chars = ['\x05', '\x15']  # Ctrl+E (end of line) then Ctrl+U (clear line)
    clear_result = dojo.send_and_listen(clear_chars, 0.5)
    
    # Parse command string for escape sequences
    chars = parse_command_string(command)
    
    # Only add enter if the command doesn't already end with carriage return and no_enter is False
    if not no_enter and (not chars or chars[-1] != '\r'):
        chars.append('\r')
    
    # Use send_and_listen for complete character stream processing  
    listen_timeout = timeout if timeout is not None else DEFAULT_LISTEN_DURATION
    result = dojo.send_and_listen(chars, listen_timeout)
    
    # Extract text from the captured events
    terminal_output = dojo._extract_output(result.terminal_events)
    
    # Add slog messages as categorized output
    all_output = terminal_output
    if result.slog_messages:
        slog_output = '\n'.join([f"[SLOG] {msg}" for msg in result.slog_messages])
        if all_output:
            all_output = f"{all_output}\n{slog_output}"
        else:
            all_output = slog_output
    
    return all_output if result.chars_sent == len(chars) else f"Error: Only sent {result.chars_sent}/{len(chars)} chars"


def quick_run_batched(command: str, timeout: float = None, no_enter: bool = False) -> str:
    """
    Quick function to run a single command using batched sending for improved performance.

    Uses webterm's batching approach to dramatically reduce HTTP requests.

    Usage:
        result = quick_run_batched("(add 5 4)")    # Much faster than quick_run
        result = quick_run_batched("now")          # Single HTTP request + enter
    """
    config = load_config()

    if not all([config['ship_name'], config['access_code']]):
        return "Error: Missing ship configuration. Create config.json or set environment variables."

    dojo = UrbitDojo(config['ship_url'], config['ship_name'], config['access_code'])

    if not dojo.connect():
        return "Error: Could not connect to Urbit ship"

    # Only clear if we're not at a clean prompt to avoid unnecessary bell
    if not dojo._is_at_clean_prompt():
        clear_command = '\x05\x15'  # Ctrl+E then Ctrl+U
        dojo.send_command_batched(clear_command, 0.5)

    # Parse command string for escape sequences
    chars = parse_command_string(command)

    # Add enter if not present and no_enter is False
    if not no_enter and (not chars or chars[-1] != '\r'):
        chars.append('\r')

    # Use enhanced batched sending for main command
    listen_timeout = timeout if timeout is not None else DEFAULT_LISTEN_DURATION
    result = dojo.send_chars_batched(chars, listen_timeout)

    # Extract text from captured events
    terminal_output = dojo._extract_output(result.terminal_events)

    # Add slog messages
    all_output = terminal_output
    if result.slog_messages:
        slog_output = '\n'.join([f"[SLOG] {msg}" for msg in result.slog_messages])
        if all_output:
            all_output = f"{all_output}\n{slog_output}"
        else:
            all_output = slog_output

    return all_output


def make_http_request(method: str, path: str, data: str = None, content_type: str = None) -> str:
    """
    Make an authenticated HTTP request to the Urbit ship.

    Uses the same authentication as dojo commands, allowing easy testing of
    web interfaces like sailbox without manual browser interaction.

    Args:
        method: HTTP method (GET, POST, PUT, DELETE, etc.)
        path: URL path (e.g., "/sailbox" or "/sailbox?foo=bar")
        data: Request body for POST/PUT requests (optional)
        content_type: Content-Type header (defaults to application/json for JSON data)

    Returns:
        Response body as string (HTML, JSON, etc.)

    Usage:
        # GET request
        result = make_http_request("GET", "/sailbox")

        # GET with query parameters
        result = make_http_request("GET", "/sailbox?ship=~zod&action=view")

        # POST JSON data
        result = make_http_request("POST", "/sailbox/command", '{"ship": "~zod"}')

        # POST form data
        result = make_http_request("POST", "/sailbox", "ship=~zod", "application/x-www-form-urlencoded")
    """
    config = load_config()

    if not all([config['ship_name'], config['access_code']]):
        return "Error: Missing ship configuration. Create config.json or set environment variables."

    # Create a dojo instance just for authentication
    dojo = UrbitDojo(config['ship_url'], config['ship_name'], config['access_code'])

    # Connect to get authenticated cookies
    if not dojo.connect():
        return "Error: Could not connect to Urbit ship for authentication"

    # Build full URL
    url = f"{config['ship_url']}{path}"

    # Prepare headers
    headers = {}
    if content_type:
        headers['Content-Type'] = content_type
    elif data and data.strip().startswith('{'):
        # Auto-detect JSON
        headers['Content-Type'] = 'application/json'

    try:
        # Make the request with authenticated cookies
        if method.upper() == 'GET':
            response = requests.get(url, cookies=dojo.cookies, headers=headers, timeout=10)
        elif method.upper() == 'POST':
            response = requests.post(url, cookies=dojo.cookies, headers=headers, data=data, timeout=10)
        elif method.upper() == 'PUT':
            response = requests.put(url, cookies=dojo.cookies, headers=headers, data=data, timeout=10)
        elif method.upper() == 'DELETE':
            response = requests.delete(url, cookies=dojo.cookies, headers=headers, timeout=10)
        else:
            return f"Error: Unsupported HTTP method: {method}"

        # Return response text (could be HTML, JSON, etc.)
        return response.text

    except requests.RequestException as e:
        return f"Error: HTTP request failed: {str(e)}"
# Urbit Dojo Client - Advanced Terminal Interface

A powerful Python client for interacting with Urbit's dojo terminal, featuring a **persistent daemon** for reliable command execution and comprehensive syntax analysis capabilities.

This tool is part of the **clurd project** (Claude + Urbit) - an initiative to give Claude mastery over Urbit by providing:
- **Persistent daemon connection** - Never miss delayed output or slog messages
- **Dynamic interaction** with running Urbit ships without timing guesswork  
- **Syntax analysis capabilities** - Bell detection, tab completion, command validation
- **Tools for computational archaeology** of Urbit's unique paradigm

The dojo client serves as Claude's primary instrument for probing and understanding Urbit's behavior in real-time.

## 🚀 Key Features

### 1. **Persistent Daemon Connection** ⭐ NEW
Long-running background process that maintains connection to your Urbit ship, capturing ALL events continuously. No more timing guesswork or missed output!

### 2. **Terminal Buffer Simulation**
Faithfully reproduces webterm's visual output by implementing Urbit's blit (terminal command) protocol including cursor positioning, line clearing, and text rendering.

### 3. **Bell Detection & Syntax Analysis** 
Revolutionary capability to detect when Urbit rejects input (bell events) and pinpoint exactly where parsing fails. Perfect for exploring Urbit's syntax rules.

### 4. **Tab Completion Extraction**
Clean extraction of completion suggestions and function signatures from Urbit's interactive help system.

### 5. **Smart Output Cleaning**
Automatically removes duplicate prompts and formats output for better readability.

## 📁 Recommended Directory Structure

For optimal use with Claude, organize your workspace like this:

```
your-workspace/             # Your main workspace directory
├── docs.urbit.org/         # git clone https://github.com/urbit/docs.urbit.org
├── urbit/                  # git clone https://github.com/urbit/urbit  
├── ships/                  # Your running Urbit ships
│   ├── zod/               # Development ship
│   └── your-ship/         # Your actual ship
└── clurd/                 # This repository
    ├── urbit_dojo.py
    ├── dojo
    ├── config.json
    └── README.md
```

**Why this structure?**
- Claude can access Urbit source code and documentation
- Ships directory keeps everything organized
- clurd can reference examples from docs and source

## Quick Start

### 1. **Set up the workspace:**
```bash
mkdir your-workspace && cd your-workspace
git clone https://github.com/urbit/docs.urbit.org
git clone https://github.com/urbit/urbit
mkdir ships
git clone [this-repo] clurd
```

### 2. **Install dependencies:**
```bash
cd clurd
pip install -r requirements.txt
```

### 3. **Configure your ship:**
```bash
cp config.example.json config.json
# Edit config.json with your ship details
```

**Getting your access code:**
1. In your ship's dojo: `+code`
2. Copy the result (like `ridlur-figbud-capmut-bidrup`)

**Example config.json:**
```json
{
  "ship_url": "http://localhost:80",
  "ship_name": "sampel-palnet", 
  "access_code": "ridlur-figbud-capmut-bidrup"
}
```

### 4. **Start the daemon:** ⭐ RECOMMENDED
```bash
./dojo-daemon start           # Start persistent connection
./dojo-daemon status          # Check if running
```

### 5. **Send commands:**
```bash
./dojo-daemon send "(add 5 4)"     # Basic arithmetic
./dojo-daemon send "+vats"          # System info
./dojo-daemon send "|mass"          # Memory usage
```

### 6. **Check output:**
```bash
./dojo-daemon output          # Get current state
./dojo-daemon watch           # Watch live (Ctrl+C to stop)
```

### 7. **When done:**
```bash
./dojo-daemon stop            # Clean shutdown
```

## 🎯 Why Use the Daemon?

**Before (old approach):**
```python
# Had to guess timeouts - risky!
result = dojo.run("complex-command", timeout=30)  # Hope 30s is enough...
```

**After (daemon approach):**
```bash
# Send and check back whenever convenient - no timing guesswork!
./dojo-daemon send "complex-command"
# ... do other work ...
./dojo-daemon output  # Check when ready
```

**Benefits:**
- ✅ **Never miss output** - Daemon captures everything continuously
- ✅ **No timing guesswork** - Commands can take as long as needed
- ✅ **Background operation** - Send commands and check back later
- ✅ **Persistent connection** - Avoids reconnection overhead
- ✅ **Clean output** - Automatic prompt cleaning and formatting
- ✅ **Complete event log** - All interactions saved in `.dojo_daemon/events.jsonl`

## 💡 Advanced Usage

### Working with Long-Running Commands
```bash
# Send a command that might take time
./dojo-daemon send "|pack"           # Memory defragmentation

# Continue with other work...
./dojo-daemon send "(add 1 2)"       # Quick command works fine

# Check back for pack results when convenient
./dojo-daemon output                 # See current state
```

### Daemon Status and Monitoring
```bash
./dojo-daemon status                 # Connection health, uptime, event count
cat .dojo_daemon/events.jsonl       # Full event history
cat .dojo_daemon/daemon.log         # Daemon logs for debugging
```

### Legacy Library Usage (Advanced Users)

For direct Python integration, the underlying library supports advanced features:

#### Bell-Aware Syntax Probing
```python
from urbit_dojo import UrbitDojo, load_config

dojo = UrbitDojo(**load_config())
dojo.connect()
result = dojo.send_until_bell(['1','0','0','0','0','0','0','0'])
print(f'Accepted: {result.chars_accepted} chars')  # 3
print(f'Rejected: {result.chars_rejected}')        # ['0','0','0','0','0'] 
print(f'Terminal: {result.terminal_state}')        # '100'
```

#### Tab Completion Extraction
```python
completions = dojo.get_completions("+he")
print(completions)  # ['+hello', '+help']
```

#### Command Validation
```python
validation = dojo.validate_command("(add 5 )")
print(validation['is_valid'])          # False
print(validation['accepted_portion'])  # "(add 5 "
print(validation['rejected_portion'])  # ")"
print(validation['error_position'])    # 7
```

**Note:** For most use cases, the daemon approach is recommended over direct library usage.

## 🎯 Use Cases

### Learning Urbit Syntax
- **Discover parsing rules**: See exactly where Urbit rejects input
- **Explore number formats**: Understand "100.000.000" vs "10000000"  
- **Test edge cases**: Probe malformed expressions safely

### Development Workflow  
- **Rapid prototyping**: Test Hoon expressions instantly
- **Syntax validation**: Check code before committing
- **Interactive exploration**: Tab completion for discovery

### Computational Archaeology
- **Reverse-engineer parsers**: Understand how Urbit thinks
- **Document behavior**: Capture exact parsing rules  
- **Research platform**: Systematic exploration of computational models

## Configuration

The daemon uses the same configuration as the library. Create a `config.json` file:

```json
{
  "ship_url": "http://localhost:80",
  "ship_name": "your-ship-name", 
  "access_code": "your-access-code"
}
```

**Alternative: Environment variables:**
```bash
export URBIT_URL="http://localhost:80"
export URBIT_SHIP="your-ship-name"  
export URBIT_CODE="your-access-code"
```

## 🔧 Troubleshooting

### Daemon Won't Start
```bash
./dojo-daemon status               # Check if already running
cat .dojo_daemon/daemon.log       # Check error logs
```

### Connection Issues
- Ensure your Urbit ship is running
- Verify ship URL (usually `http://localhost:80`)
- Check access code with `+code` in your ship's dojo
- Restart daemon: `./dojo-daemon stop && ./dojo-daemon start`

### Missing Output
With the daemon, you shouldn't miss output! But if you do:
- Check `./dojo-daemon status` for connection health
- View full event log: `cat .dojo_daemon/events.jsonl`
- Ensure daemon is running during command execution

## 🔬 Technical Innovation

**Key Insight**: Instead of trying to parse text streams, clurd simulates the actual terminal that Urbit communicates with. This gives us:

- **Pixel-perfect output formatting** (exactly like webterm)
- **Real-time parser feedback** through bell event detection
- **Natural text separation** via cursor positioning commands  
- **Complete interaction visibility** including system diagnostics

The terminal simulation faithfully implements Urbit's blit protocol:
- `put`: Write text at cursor position
- `klr`: Write styled text  
- `nel`: Newline
- `hop`: Set cursor position
- `wyp`: Clear line from cursor
- `clr`: Clear screen
- `bel`: **Bell (rejection signal)** ← The key innovation

## Examples

### Basic Daemon Usage
```bash
# Start daemon
./dojo-daemon start

# Basic commands
./dojo-daemon send "(add 10 5)"        # Arithmetic
./dojo-daemon send "(mul 3 4)"         # More arithmetic  
./dojo-daemon send "(lent ~[1 2 3])"   # List operations
./dojo-daemon send "our"               # Ship name

# System commands
./dojo-daemon send "+vats"             # Desk information
./dojo-daemon send "+code"             # Access code
./dojo-daemon send "|mass"             # Memory usage

# Check output anytime
./dojo-daemon output
```

### Working with Claude
The daemon is perfect for Claude interactions:

```bash
# Send a command
./dojo-daemon send "+ls /===/gen"

# Claude can do other work, then check back:
./dojo-daemon output

# Send follow-up based on results
./dojo-daemon send "+cat /===/gen/hello/hoon"
```

### Complete Workflow Example
```bash
# 1. Start daemon
./dojo-daemon start

# 2. Explore your ship
./dojo-daemon send "+vats"           # See what desks you have
./dojo-daemon output                 # Check results

# 3. Look at files
./dojo-daemon send "+ls %"           # List current directory
./dojo-daemon send "+tree % 2"       # Tree view with depth 2

# 4. Check system health
./dojo-daemon send "|mass"           # Memory usage
./dojo-daemon send "+trouble"        # Any problems?

# 5. When done
./dojo-daemon stop
```

### Special Characters in Commands
```bash
# Tab completion (use \t)
./dojo-daemon send "+he\t"           # Shows completions

# Multi-line input (use \n)  
./dojo-daemon send "(add\n5 4)"      # Multi-line expression
```

## Requirements

- Python 3.6+
- `requests` library
- Running Urbit ship

## Contributing

clurd represents a new paradigm for interacting with computational systems - instead of guessing at behavior, we probe systematically and learn the exact rules. This approach could be applied to any system with real-time feedback mechanisms.

## Files Overview

- `./dojo-daemon` - Main executable for daemon control
- `dojo_daemon.py` - Daemon implementation  
- `urbit_dojo.py` - Core library with terminal simulation
- `config.json` - Your ship configuration (create from config.example.json)
- `dojo-commands-reference.md` - Comprehensive command reference
- `.dojo_daemon/` - Runtime files (events, output, logs)

## Philosophy

We're not just building tools, we're developing **computational archaeology** - methods for understanding alien computational paradigms through systematic exploration and real-time feedback analysis.

The daemon approach eliminates the traditional "request-response with timeout" pattern, replacing it with "continuous observation" - much like how an archaeologist doesn't rush to conclusions but carefully observes and records everything over time.

Urbit becomes not just a platform to use, but an instrument for studying fundamentally different approaches to computation.
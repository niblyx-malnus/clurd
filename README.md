# clurd - Claude + Urbit Dojo Client

A Python client for interacting with Urbit's dojo terminal, designed for Claude's real-time exploration of Urbit systems.

## 80/20 Essential Toolkit

The three tools you need for 80% of Urbit dojo interaction:

### 1. `./run.sh dojo` - Execute Commands (Recommended)
```bash
./run.sh dojo "(add 5 4)"                    # Execute and get result: 9
./run.sh dojo "now"                          # Current Urbit time  
./run.sh dojo "|commit %base" 10             # Commit operation with 10s timeout
./run.sh dojo "\\up" --no-enter              # Navigate history without executing
./run.sh dojo "hello\\left\\leftworld"       # Arrow key cursor movement
```

**Or direct usage** (after manual setup):
```bash
./dojo "(add 5 4)"                    # Requires local Python setup
```

**Recommended timeouts by operation type:**
- **Most operations**: Default (0.5s) - try immediately first
- **`|commit` operations**: 10 seconds (compilation takes time)
- **Threads/async operations**: Consider wait time for completion
- **Network/HTTP requests**: Varies by operation

### 2. `./run.sh get` - Explore Command History  
```bash
./run.sh get 1           # Get the most recent command (clean reset)
./run.sh get 5           # Get command 5 steps back
./run.sh get 20          # Deep history exploration
```

**Or direct:** `./get 1` (after manual setup)

**Key advantage:** Each call resets history cursor position for predictable navigation.

### 3. Tab Completion - Discover Available Commands
```bash
./run.sh dojo "\\t" --no-enter              # Show all available functions
./run.sh dojo "+he\\t" --no-enter           # Autocomplete commands starting with "+he"
./run.sh dojo "ad\\t" --no-enter            # Complete "ad" to "add"
```

**Perfect for:** Learning Hoon standard library, discovering system functions, getting function signatures.

## Quick Start

1. **Configure your ship:**
   ```bash
   cp config.example.json config.json
   # Edit with your ship_url, ship_name, and access_code
   ```

2. **Get your access code:**
   ```bash
   ./dojo "+code"  # Copy the result like "ridlur-figbud-capmut-bidrup"
   ```

3. **Start exploring:**
   ```bash
   ./dojo "\\t" --no-enter             # See what's available
   ./get 10                           # Check recent history
   ./dojo "(add 1 2)"                 # Try a command
   ```

## Advanced Usage

### Command Execution Modes
```bash
./dojo "command"                      # Default (batched, fast)
./dojo "command" --slow               # Character-by-character (debugging)
./dojo "command" --no-enter           # Navigate/edit without executing
```

### Arrow Key Navigation
```bash
./dojo "\\up\\up" --no-enter          # Go back 2 commands in history
./dojo "\\down" --no-enter            # Go forward in history  
./dojo "word\\left\\leftnew" --no-enter  # Edit: "newword"
```

### History Exploration
```bash
./get 1           # Latest command with clean cursor reset
./get 50          # Deep dive into command history
```

## Configuration

Create `config.json`:
```json
{
  "ship_url": "http://localhost:80",
  "ship_name": "your-ship-name", 
  "access_code": "your-access-code"
}
```

**Getting your access code:**
1. In your ship's dojo: `+code`
2. Copy the result (like `ridlur-figbud-capmut-bidrup`)

## Python Library

```python
from urbit_dojo import quick_run, quick_run_batched, get_command

# Execute commands
result = quick_run("(add 5 4)")               # "9"
result = quick_run_batched("now", timeout=5)  # Fast batched execution

# History exploration  
command = get_command(5)                      # Get command 5 steps back
```

## Key Features

- **Full arrow key support** - History navigation and cursor movement
- **Predictable history navigation** - Clean cursor reset with `./get`
- **Interactive tab completion** - Discover and learn Urbit functions
- **Smart timeout handling** - Appropriate timeouts for different operations
- **Terminal simulation** - Faithful reproduction of dojo behavior
- **SLOG capture** - System log messages included in output

## Important Notes

### `|commit` Output Interpretation

**⚠️ Common Misconception:**
```bash
./dojo "|commit %base" 10
> |commit %base
>=
~zod:dojo>
```

**This output (`>=`) means:**
- **NOTHING IN THAT DESK HAS CHANGED**, or
- **THE CHANGES HAVEN'T PROPAGATED YET**

**It does NOT mean the commit was successful** (unless you're actually committing no changes).

**This usually indicates:**
- You need a longer timeout and missed a compilation error
- You're trying to commit changes that have already been committed
- Changes are still propagating through the system

**For successful commits with actual changes, expect meaningful output about what was compiled/changed.**

## Requirements

- Python 3.6+
- `requests` library  
- Running Urbit ship with web interface

## Philosophy

clurd provides a minimal, powerful toolkit for systematic exploration of Urbit's computational paradigm through real-time interaction and feedback analysis.
# clurd - Claude + Urbit Dojo Client

A Python client for interacting with Urbit's dojo terminal, designed for Claude's real-time exploration of Urbit systems.

📖 **[Technical Architecture Documentation](architecture.md)** - Deep dive into how clurd works internally.

## 80/20 Essential Toolkit

The four tools you need for 80% of Urbit interaction:

### 1. `./run.sh dojo` - Execute Commands
```bash
./run.sh dojo "(add 5 4)"                    # Execute and get result: 9
./run.sh dojo "now"                          # Current Urbit time  
./run.sh dojo "|commit %base" 10             # Commit operation with 10s timeout
./run.sh dojo "\\up" --no-enter              # Navigate history without executing
./run.sh dojo "hello\\left\\leftworld"       # Arrow key cursor movement
```


**Recommended timeouts by operation type:**
- **Most operations**: Default (0.5s) - try immediately first
- **`|commit` operations**: 10 seconds (compilation takes time)
- **Threads/async operations**: Consider wait time for completion
- **Network/HTTP requests**: Varies by operation

### 2. `./run.sh nth_last_command` - Get Nth Last Command  
```bash
./run.sh nth_last_command 1           # Get the most recent command (clean reset)
./run.sh nth_last_command 5           # Get 5th last command
./run.sh nth_last_command 20          # Get 20th last command
```


**Key advantage:** Each call resets history cursor position for predictable navigation.

### 3. Tab Completion - Discover Available Commands
```bash
./run.sh dojo "\\t" --no-enter              # Show all available functions
./run.sh dojo "+he\\t" --no-enter           # Autocomplete commands starting with "+he"
./run.sh dojo "ad\\t" --no-enter            # Complete "ad" to "add"
```

**Perfect for:** Learning Hoon standard library, discovering system functions, getting function signatures.

### 4. `./run.sh http` - Authenticated HTTP Requests
```bash
./run.sh http GET /sailbox                   # GET request to sailbox app
./run.sh http GET "/sailbox?foo=bar"         # GET with query parameters
./run.sh http POST /sailbox/command '{"ship": "~zod"}'  # POST JSON data
./run.sh http POST /sailbox "ship=~zod" --content-type "application/x-www-form-urlencoded"
```

**Perfect for:** Testing web interfaces like sailbox, debugging form submissions, automating UI interactions without browser.

## Quick Start

1. **Configure your ship:**
   ```bash
   cp config.example.json config.json
   # Edit with your ship_url, ship_name, and access_code
   ```

2. **Get your access code:**
   ```bash
   ./run.sh dojo "+code"  # Copy the result like "ridlur-figbud-capmut-bidrup"
   ```

3. **Start exploring:**
   ```bash
   ./run.sh dojo "\\t" --no-enter      # See what's available
   ./run.sh nth_last_command 10        # Check recent history
   ./run.sh dojo "(add 1 2)"           # Try a command
   ```

## Advanced Usage

### Command Execution Modes
```bash
./run.sh dojo "command"               # Default (batched, fast)
./run.sh dojo "command" --slow        # Character-by-character (debugging)
./run.sh dojo "command" --no-enter    # Navigate/edit without executing
```

### Arrow Key Navigation
```bash
./run.sh dojo "\\up\\up" --no-enter    # Go back 2 commands in history
./run.sh dojo "\\down" --no-enter      # Go forward in history
./run.sh dojo "word\\left\\leftnew" --no-enter  # Edit: "newword"
```

### History Exploration
```bash
./run.sh nth_last_command 1    # Latest command with clean cursor reset
./run.sh nth_last_command 50   # Deep dive into command history
```

## Configuration

Create `config.json`:
```json
{
  "ship_url": "http://localhost:80",
  "ship_name": "zod",
  "access_code": "your-access-code"
}
```

**Important:** Ship name should omit the `~` sig. Use `"zod"` not `"~zod"`.

**Getting your access code:**
1. In your ship's dojo: `+code`
2. Copy the result (like `ridlur-figbud-capmut-bidrup`)

## Python Library

```python
from urbit_dojo import quick_run, quick_run_batched, get_command, make_http_request

# Execute commands
result = quick_run("(add 5 4)")               # "9"
result = quick_run_batched("now", timeout=5)  # Fast batched execution

# History exploration
command = get_command(5)                      # Get command 5 steps back

# Authenticated HTTP requests
html = make_http_request("GET", "/sailbox")
json_response = make_http_request("POST", "/sailbox/api", '{"data": "value"}')
```

## Key Features

- **Full arrow key support** - History navigation and cursor movement
- **Predictable history navigation** - Clean cursor reset with `./nth_last_command`
- **Interactive tab completion** - Discover and learn Urbit functions
- **Smart timeout handling** - Appropriate timeouts for different operations
- **Terminal simulation** - Faithful reproduction of dojo behavior
- **SLOG capture** - System log messages included in output

## Important Notes

### `|commit` Output Interpretation

**⚠️ Common Misconception:**
```bash
./run.sh dojo "|commit %base" 10
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

## Desk Templates

- **[mindesk.md](mindesk.md)** - Minimal desk creation with working Gall agent (12 files)
- **[teddesk.md](teddesk.md)** - Minimal desk for thread-driven development with agent coordination examples (17 files)
- **[testdesk.md](testdesk.md)** - Testing infrastructure and patterns for Urbit development
- **[gendesk.md](gendesk.md)** - Generator development patterns (naked, %say, %ask, agent-specific)
- **[clibox.md](clibox.md)** - CLI development using %shoe library for terminal interfaces

## Documentation for Claude

- **[quick_reference.md](quick_reference.md)** - Comprehensive Urbit dojo command reference for Claude: desk notation, path substitution, navigation, and discovery
- **[FOO.md](FOO.md)** - Frequently Observed Oversights: Common mistakes Claude makes when working with Urbit (learning document)

## Philosophy

clurd provides a minimal, powerful toolkit for systematic exploration of Urbit's computational paradigm through real-time interaction and feedback analysis.

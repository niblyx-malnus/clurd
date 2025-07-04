# Urbit Dojo Client - Advanced Terminal Interface

A powerful Python client for interacting with Urbit's dojo terminal, featuring revolutionary syntax analysis capabilities and pixel-perfect output formatting.

This tool is part of the **clurd project** (Claude + Urbit) - an initiative to give Claude mastery over Urbit by providing:
- Access to foundational Urbit repositories and documentation
- Dynamic interaction with running Urbit ships  
- Iterative knowledge distillation through systematic exploration
- Tools for computational archaeology of Urbit's unique paradigm

The dojo client serves as Claude's primary instrument for probing and understanding Urbit's behavior in real-time.

## 🚀 Key Features

### 1. **Terminal Buffer Simulation**
Faithfully reproduces webterm's visual output by implementing Urbit's blit (terminal command) protocol including cursor positioning, line clearing, and text rendering.

### 2. **Bell Detection & Syntax Analysis** 
Revolutionary capability to detect when Urbit rejects input (bell events) and pinpoint exactly where parsing fails. Perfect for exploring Urbit's syntax rules.

### 3. **Tab Completion Extraction**
Clean extraction of completion suggestions and function signatures from Urbit's interactive help system.

### 4. **Real-time Stream Processing** 
Captures both terminal output and slog (system log) messages during specified time windows.

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

1. **Set up the workspace:**
   ```bash
   mkdir your-workspace && cd your-workspace
   git clone https://github.com/urbit/docs.urbit.org
   git clone https://github.com/urbit/urbit
   mkdir ships
   git clone [this-repo] clurd
   ```

2. **Install dependencies:**
   ```bash
   cd clurd
   pip install -r requirements.txt
   ```

3. **Configure your ship:**
   ```bash
   cp config.example.json config.json
   # Edit config.json with your ship details
   ```

4. **Run commands:**
   ```bash
   ./dojo "(add 5 4)\r"      # Execute: returns "9"
   ./dojo "+he\t"            # Tab completion: shows "+hello", "+help"
   ./dojo "now\r"            # Current time
   ```

## 💡 Advanced Usage

### Bell-Aware Syntax Probing
```bash
# Test where Urbit's number parser fails
python3 -c "
from urbit_dojo import UrbitDojo, load_config
dojo = UrbitDojo(**load_config())
dojo.connect()
result = dojo.send_until_bell(['1','0','0','0','0','0','0','0'])
print(f'Accepted: {result.chars_accepted} chars') # 3
print(f'Rejected: {result.chars_rejected}')       # ['0','0','0','0','0'] 
print(f'Terminal: {result.terminal_state}')       # '100'
"
```

### Tab Completion Extraction
```python
from urbit_dojo import UrbitDojo, load_config

dojo = UrbitDojo(**load_config())
dojo.connect()
completions = dojo.get_completions("+he")
print(completions)  # ['+hello', '+help']
```

### Command Validation
```python
# Test syntax without execution
validation = dojo.validate_command("(add 5 )")
print(validation['is_valid'])          # False
print(validation['accepted_portion'])  # "(add 5 "
print(validation['rejected_portion'])  # ")"
print(validation['error_position'])    # 7
```

### Syntax Exploration
```python
# Systematically test what characters Urbit accepts
results = dojo.explore_syntax("100", ['.', ' ', '0', ')'])
for char, result in results.items():
    status = '✓' if result['accepted'] else '✗'
    print(f"{status} 100{repr(char)}")
```

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

Create a `config.json` file:

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

**Alternative: Environment variables:**
```bash
export URBIT_URL="http://localhost:80"
export URBIT_SHIP="your-ship-name"  
export URBIT_CODE="your-access-code"
```

## ⏱️ Timing Considerations

**IMPORTANT**: clurd captures output during a time window. Choose your timeout based on the expected command behavior:

```python
# Fast arithmetic - 1-2 seconds
dojo.send_and_listen(['(add 5 4)\r'], listen_duration=2.0)

# Tab completion - 2-3 seconds  
dojo.send_and_listen(['+he\t'], listen_duration=3.0)

# File operations - 5-10 seconds
dojo.send_and_listen(['|commit %base\r'], listen_duration=10.0)

# Network operations - 10-30 seconds
dojo.send_and_listen(['+bitcoin|btc-wallet\r'], listen_duration=30.0)

# Long computations - adjust as needed
dojo.send_and_listen(['(some-complex-computation)\r'], listen_duration=60.0)
```

If output arrives after the window closes, it will be missed. When in doubt, use a longer timeout - you'll just wait a bit longer for the result.

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

### Basic Commands
```bash
./dojo "(add 10 5)\r"       # 15
./dojo "(mul 3 4)\r"        # 12  
./dojo "(lent ~[1 2 3])\r"  # 3
./dojo "our\r"              # Your ship name
```

### Tab Completion
```bash
./dojo "+he\t"              # Shows +hello, +help suggestions
./dojo "ad\t\t"             # Shows add function signature
```

### Multi-line Input
```bash
./dojo "(add\n5 4)\r"       # Multi-line expression
```

### Special Characters
- `\t` - Tab (triggers completion)
- `\r` - Carriage return (executes command)
- `\n` - Newline (multi-line input)
- `\b` - Backspace

## Library Usage

### Simple Commands
```python
from urbit_dojo import UrbitDojo

dojo = UrbitDojo("http://localhost:80", "ship-name", "access-code")
if dojo.connect():
    result = dojo.run("(add 5 4)")
    print(result.output)  # "9"
```

### Advanced Analysis
```python
# Bell detection
bell_result = dojo.send_until_bell(['(', 'a', 'd', 'd', ' ', '5', ' ', ')'])
print(f"Accepted: {bell_result.chars_accepted} chars")
print(f"Error at: {bell_result.bell_position}")

# Completion extraction  
completions = dojo.get_completions("+")
print(f"Available generators: {completions}")

# Command validation
validation = dojo.validate_command("malformed expression")
if not validation['is_valid']:
    print(f"Syntax error at position {validation['error_position']}")
```

## Requirements

- Python 3.6+
- `requests` library
- Running Urbit ship

## Contributing

clurd represents a new paradigm for interacting with computational systems - instead of guessing at behavior, we probe systematically and learn the exact rules. This approach could be applied to any system with real-time feedback mechanisms.

## Philosophy

We're not just building tools, we're developing **computational archaeology** - methods for understanding alien computational paradigms through systematic exploration and real-time feedback analysis.

Urbit becomes not just a platform to use, but an instrument for studying fundamentally different approaches to computation.
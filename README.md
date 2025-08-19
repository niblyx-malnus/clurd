# clurd - Claude + Urbit Dojo Client

A Python client for interacting with Urbit's dojo terminal, designed for Claude's real-time exploration of Urbit systems.

## Quick Start

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure your ship:**
   ```bash
   cp config.example.json config.json
   # Edit config.json with your ship details
   ```

3. **Run commands:**
   ```bash
   ./dojo "(add 5 4)"                    # Basic command
   ./dojo "|commit %desk" 10             # With 10 second timeout
   ./dojo "now"                          # Current time
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

## Usage

### Command Line Interface
```bash
./dojo "<command>" [timeout]
```

Examples:
- `./dojo "(add 5 4)"` - Basic arithmetic
- `./dojo "|commit %base" 30` - Long operation with 30s timeout
- `./dojo "+hello 'world'"` - Generator with argument

### Python Library
```python
from urbit_dojo import quick_run

result = quick_run("(add 5 4)")          # "9"
result = quick_run("|commit %base", 30)  # With timeout
```

## Key Features

- **Command execution** with proper Urbit terminal simulation
- **Timeout support** for long-running operations
- **SLOG capture** for system log messages
- **Tab completion** and syntax validation
- **Bell detection** for parsing error identification

## Requirements

- Python 3.6+
- `requests` library
- Running Urbit ship with web interface

## Philosophy

clurd enables systematic exploration of Urbit's computational paradigm through real-time interaction and feedback analysis.
# Urbit Dojo Command Reference

A compact catalog of all commands available in the Urbit dojo, organized by category.

## Command Types

- **Expressions**: Raw Hoon expressions (arithmetic, function calls, etc.)
- **Generators (+)**: Scripts that produce output
- **Threads (-)**: Asynchronous computations 
- **System Commands (|)**: Ship management and administrative tasks

## Desk & Path Notation

### Desk Specification for Commands

**For Threads**: Must specify desk unless using `%base`
- `-thread-name` (runs from current desk, usually `%base`)
- `-desk!thread-name` (runs from specified desk)
- Examples: `-hi ~ship`, `-landscape!make-glob`

**For Generators**: Can optionally specify desk
- `+generator` (runs from current desk, usually `%base`)  
- `+desk!generator args` (runs from specified desk)
- Examples: `+hello 'world'`, `+base!hello 'world'`

**Note**: The `%base` desk contains the core system threads and generators, so most commands work without desk specification.

### Directory Navigation

**Current Directory**: Use `%` to reference current location
- `%` - Current directory (like `.` in Unix)
- `%%` - One level up (like `..` in Unix)
- `%%%` - Two levels up (abandons revision and desk info)

**Changing Directories**: Use `=dir` (equivalent to Unix `cd`)
- `=dir` - Return to base desk root
- `=dir %/gen` - Go to `/gen` in current desk
- `=dir /=base=/gen` - Go to `/gen` in `%base` desk
- `=dir /=sandbox=/app` - Switch to different desk and directory

### Path Substitution

**The `=/=/` Pattern**: Substitute parts of the full path `/ship/desk/case/path`
- `/===/path` - Use current ship, desk, and case, specify only path
- `/=desk=/path` - Use current ship and case, specify desk and path

**Full Address Format**: `/ship/desk/case/path`
- Ship: `~sampel-palnet` (your ship name)
- Desk: `base`, `sandbox`, etc. (`%base` is system desk)
- Case: `~2025.9.9..02.38.54..3788` (revision/timestamp)
- Path: `/gen/hello/hoon` (file path within desk)

**Examples**:
```hoon
# Navigate to generators directory in base desk
=dir /=base=/gen

# List files in app directory using substitution
+ls /===/app

# Read file from different desk, same path structure  
+cat /=sandbox=/gen/=/hello/hoon

# Access system file with full substitution
+cat /===/sys/hoon/hoon
```

## System Commands (|)

Essential ship management and administrative operations:

### Core Ship Operations
- `|commit %desk` - Commit changes to a desk
- `|mount %desk` - Mount desk to Unix filesystem  
- `|unmount %desk` - Unmount desk from filesystem
- `|sync ~ship %their-desk %our-desk` - Sync desk from another ship
- `|unsync %desk` - Stop syncing a desk

### Installation & Software
- `|install ~ship %desk` - Install software from another ship
- `|uninstall %desk` - Remove installed software
- `|rein %desk [%app-name &]` - Start/stop apps on a desk
- `|ota` - Check for and apply Over-The-Air updates

### Ship Identity & Networking  
- `|code` - Get your ship's access code
- `|hi ~ship` - Send greeting to establish connection
- `|ping ~ship` - Test network connectivity
- `|moon ~name` - Spawn a moon (planet only)
- `|rekey` - Rotate networking keys

### System Administration
- `|mass` - Check memory usage by component
- `|pack` - Optimize event log storage
- `|meld` - Deduplicate nouns in memory
- `|trim` - Reduce memory usage
- `|verb` - Toggle verbose output

### Desk Management
- `|new-desk %name` - Create new desk
- `|cp %from %to` - Copy files between desks  
- `|mv %from %to` - Move files between desks
- `|rm %desk /path` - Remove files
- `|label %desk %label` - Tag desk version

### Advanced Operations
- `|nuke %desk` - Completely remove desk
- `|tomb ~ship` - Block communications from ship
- `|keen` - Force remote scry
- `|exit` - Gracefully shut down ship

## Generators (+)

Scripts that process input and produce output:

### Information & Debugging
- `+hello` - "Hello world" sample
- `+help` - List available commands  
- `+code` - Get ship's access code
- `+tree %desk` - Show desk file structure
- `+ls %desk /path` - List files in directory
- `+cat %desk /file` - Display file contents

### System Inspection
- `+dbug %app-name` - Debug app state
- `+vats` - List running applications
- `+keys` - Show cryptographic keys
- `+who` - Display ship identity info
- `+sponsor ~ship` - Check ship's sponsor

### Utilities
- `+deco 'some text'` - Apply text decorations
- `+kick ~ship %app` - Force restart subscription

## Threads (-)

Asynchronous operations and complex computations:

### Development & Building  
- `-build-file %desk /path` - Compile Hoon file
- `-build-mark %desk %mark` - Build mark definition
- `-build-cast %desk %from %to` - Build type conversion
- `-new-app %app-name` - Generate new app scaffold

### Network Operations
- `-hi ~ship` - Async greeting/connection *(may not be working)*
- `-eth-watcher` - Monitor Ethereum events
- `-retrieve-gh 'user/repo'` - Fetch from GitHub

### System Utilities
- `-eval 'hoon expression'` - Evaluate Hoon code
- `-peek /path` - Remote scry operation  
- `-read %desk /file` - Read file contents
- `-mass` - Detailed memory analysis
- `-time` - System time operations

### Testing & Development
- `-test %desk /test-file` - Run unit tests
- `-diff %desk /file1 /file2` - Compare files
- `-tree %desk` - Analyze desk structure
- `-meta` - System metadata operations

## Hoon Standard Library

Core functions available in expressions:

### Arithmetic & Logic
- `add`, `sub`, `mul`, `div`, `mod` - Basic math
- `gte`, `gth`, `lte`, `lth` - Comparisons  
- `max`, `min` - Extrema
- `and`, `or`, `not` - Boolean logic

### Lists & Data Structures
- `flop` - Reverse list
- `lent` - List length
- `snag` - Get list element by index
- `weld` - Concatenate lists
- `turn` - Map function over list
- `sort` - Sort list

### Text & Parsing
- `trip` - Cord to tape conversion
- `crip` - Tape to cord conversion  
- `scow` - Pretty-print atom
- `rush` - Parse with rule

### Type System
- `mold` - Type definition
- `vase` - Typed value container
- `spec` - Type specification

## Usage Examples

```hoon
# Basic arithmetic
(add 2 3)

# List operations  
(lent [1 2 3 4])
(flop [1 2 3])

# Generate fresh receiving address
+hello 'world'

# System operations
|commit %base
|mount %base
|mass

# Async operations
-hi ~sampel-palnet
-eval '(add 1 2)'

# File operations
+ls %base /
+cat %base /desk.bill
```

## Navigation & Discovery

### Command History (clurd enhanced)
- **Up/Down arrows** - Navigate command history
- **Left/Right arrows** - Edit current command  
- `./get N` - Jump back N commands in history without executing
- `--no-enter` flag - Navigate history without executing (e.g., `./dojo "+hello" --no-enter`)

### Tab Completion
- `[TAB]` - Show all available functions and commands
- `+[TAB]` - List all generators
- `-[TAB]` - List all threads  
- `|[TAB]` - List all system commands
- `+he[TAB]` - Autocomplete generators starting with "he"

### File Discovery
- `+ls /===/gen` - List all available generators
- `+ls /===/ted` - List all available threads
- `+ls /===/app` - List all applications

## Quick Reference

- **Need help?** `+help` or `+help %command`
- **Ship not responding?** `|hi ~ship` then `|ping ~ship`
- **Install software?** `|install ~ship %desk`
- **Check memory?** `|mass`
- **Commit changes?** `|commit %desk`
- **Debug app?** `+dbug %app`

---

*This reference covers the core commands available in a standard Urbit ship. Individual ships may have additional generators and threads installed via desks.*
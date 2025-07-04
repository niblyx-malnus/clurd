# Urbit Dojo Commands Reference

A comprehensive guide to Urbit dojo commands, organized by category for easy reference.

## Table of Contents
- [Basic Syntax](#basic-syntax)
- [File System Commands](#file-system-commands)
- [App Management](#app-management)
- [System Commands](#system-commands)
- [Network & Communication](#network--communication)
- [Common Generators](#common-generators)
- [Debug & Development](#debug--development)
- [Special Variables](#special-variables)
- [Examples](#examples)

## Basic Syntax

### Command Prefixes
- `+` - Run generators (read-only operations)
- `|` - Run Hood system commands (can modify system state)
- `:` - Send pokes to apps
- `-` - Run threads
- `=` - Set variables or environment
- `*` - Save output to Clay filesystem
- `.` - Export output to Unix filesystem

### Basic Patterns
```hoon
:: Set a variable
=my-var 42

:: Use a variable
my-var

:: Run a generator
+ls %

:: Send a poke to an app
:chat-cli "hello world"

:: Send a poke to a remote app
:~zod/chat-cli "hello from my ship"

:: Save output to Clay
*%/output/txt (add 2 2)

:: Export to Unix
.output/txt (add 2 2)
```

## File System Commands

### Listing & Navigation
```hoon
+ls %                    :: List current directory
+ls /===/app            :: List specific path
+tree %                 :: Recursive directory listing
+tree /===/gen 2        :: Tree with depth limit
=dir /=base=            :: Change working directory
```

### Reading Files
```hoon
+cat /===/app/dojo/hoon :: Display file contents
+cat %/gen/hello/hoon   :: Cat relative path
```

### File Operations
```hoon
|cp /===/source /===/dest :: Copy file
|mv /===/old /===/new     :: Move/rename file
|rm /===/unwanted         :: Delete file
```

### Desk Management
```hoon
|mount %base              :: Mount desk to Unix
|mount /=kids= %work      :: Mount with custom name
|commit %base             :: Commit changes to desk
|merge %base ~zod %kids   :: Merge from another desk
|sync %home ~bus %kids    :: Sync with remote desk
```

## App Management

### Installation & Control
```hoon
|install ~zod %bitcoin    :: Install desk from ship
|uninstall %bitcoin       :: Uninstall desk
|start %bitcoin           :: Start an agent
|rein %base [%.y %dojo]   :: Enable specific agent
|rein %base [%.n %dojo]   :: Disable specific agent
```

### App State Management
```hoon
|suspend %base            :: Suspend all agents on desk
|revive %base             :: Revive suspended agents
|nuke %app-name           :: Delete agent and its state
```

### App Information
```hoon
+agents                   :: List all running agents
+vats                     :: Show desk information
+trouble                  :: Show problematic desks
```

## System Commands

### Basic System
```hoon
+code                     :: Display web login code
|code %new-code           :: Change web login code
|exit                     :: Shut down ship (be careful!)
|pack                     :: Defragment memory
|meld                     :: Deduplicate memory
|mass                     :: Print memory report
```

### Verbosity & Debug
```hoon
|verb                     :: Toggle verbose mode
|ames/verb                :: Ames protocol verbosity
|ames/sift               :: Filter Ames debug output
```

### Updates
```hoon
|ota ~zod                 :: Set OTA update source
|ota (sein:title our now our) :: Set to sponsor
```

## Network & Communication

### Basic Communication
```hoon
|hi ~zod                  :: Send "hi" to another ship
|hi ~zod "custom message" :: Send custom message
```

### Ames (Network) Commands
```hoon
+ames/flows               :: Show network flows
+ames/peers               :: List connected peers
|ames/verb %rcv           :: Verbose receive messages
|ames/verb %snd           :: Verbose send messages
```

### Link Management
```hoon
|dojo/link %chat-cli      :: Link CLI app to dojo
|dojo/unlink %chat-cli    :: Unlink CLI app
```

## Common Generators

### Utility Generators
```hoon
+hello "world"            :: Hello world example
+code                     :: Show access code
+moon                     :: Generate moon name
```

### Information Generators
```hoon
+vats                     :: Desk information ✓ TESTED
+agents                   :: Running agents (may not be available on all ships)
+timers                   :: Active timers
+bindings                 :: Eyre bindings
```

### Development Generators
```hoon
+dbug [%state %app-name]  :: Debug app state (requires dbug agent)
+dbug [%bowl %app-name]   :: Show app bowl (requires dbug agent)
```

### Tested Generators on ~saphex-radsem-niblyx-malnus
```hoon
+code                     :: ✓ Returns: nactus-talpur-tagruc-micsul
+ls %                     :: ✓ Lists: app/ desk/bill gen/ lib/ mar/ sur/ sys/ ted/
+ls /===/gen              :: ✓ Shows available generators
+tree %                   :: ✓ Directory tree view
+vats                     :: ✓ Shows desks: %base, %kids, %penpal, %webterm
+hello                    :: ✓ Available
+help                     :: ✓ Available
+trouble                  :: ✓ Available
```

## Debug & Development

### Agent Debugging
```hoon
:app-name +dbug           :: Enter debug mode
:app-name +dbug [%state]  :: Print agent state
```

### Memory & Performance
```hoon
|mass                     :: Memory usage report
.urb/put/mass             :: Save mass report
|pack                     :: Garbage collection
```

### Error Handling
```hoon
+timers                   :: Check stuck timers
+trouble                  :: Find problematic desks
```

## Special Variables

### Built-in Variables
```hoon
our                       :: Your ship name (@p)
now                       :: Current time (@da)
eny                       :: Entropy (@uvJ)
dir                       :: Current directory (path)
```

### Usage Examples
```hoon
our                       :: ~sampel-palnet
now                       :: ~2023.7.4..12.30.45..1234
`@da`now                  :: Pretty-print time
`@ux`eny                  :: Hex entropy
```

### Tested on ~saphex-radsem-niblyx-malnus
```hoon
our                       :: ✓ Returns: ~saphex-radsem-niblyx-malnus
now                       :: ✓ Returns: ~2025.7.4..11.37.19..dc97 (example)
```

## Examples

### Basic Workflows

#### 1. File Management Workflow
```hoon
:: List files
+ls %

:: Read a file
+cat %/app/dojo/hoon

:: Copy a file
|cp %/app/dojo/hoon %/backup/dojo/hoon

:: Mount and edit
|mount %base
:: Edit files in Unix
|commit %base
```

#### 2. App Development Workflow
```hoon
:: Create new desk
|merge %myapp our %base

:: Mount for editing
|mount %myapp

:: Start development
|start %myapp

:: Debug your app
:myapp +dbug

:: Check app state
:myapp +dbug [%state]
```

#### 3. System Maintenance
```hoon
:: Check system health
+vats
+trouble
+agents

:: Clean up memory
|pack
|meld

:: Update from sponsor
|ota (sein:title our now our)
```

### Advanced Examples

#### Working with Remote Ships
```hoon
:: Sync desk from another ship
|sync %bitcoin ~zod %bitcoin

:: Send app message to remote
:~zod/chat-cli "hello from here"

:: Check connection
+ames/peers
```

#### Data Processing
```hoon
:: Save computation result
*%/data/result/txt (add 2 2)

:: Export to Unix
.data/numbers/txt (turn (gulf 1 10) @t)

:: Chain operations
=/  nums  (gulf 1 10)
=/  squares  (turn nums |=(n=@ (mul n n)))
squares
```

## Tips & Best Practices

1. **Use `+ls` and `+tree`** before file operations to verify paths
2. **Always `|commit`** after editing mounted files
3. **Use `+vats`** to check desk status before merging
4. **Run `|pack`** periodically for better performance
5. **Use `+code`** to get your access code for web login
6. **Check `+trouble`** if apps aren't starting properly
7. **Use `=dir`** to set working directory for cleaner paths
8. **Save important computations** with `*` to Clay

## Quick Reference Card

| Command | Description |
|---------|-------------|
| `+ls %` | List files |
| `+cat %/file` | Read file |
| `|mount %base` | Mount desk |
| `|commit %base` | Commit changes |
| `|start %app` | Start app |
| `+agents` | List agents |
| `+code` | Login code |
| `|hi ~ship` | Ping ship |
| `our` | Your ship |
| `now` | Current time |

## Dojo Daemon Usage

### Starting the Daemon
```bash
./dojo-daemon start           # Start in background
./dojo-daemon status          # Check if running
```

### Sending Commands
```bash
# Send any dojo command
./dojo-daemon send "(add 5 4)"
./dojo-daemon send "+vats"
./dojo-daemon send "|mass"

# Commands with special characters
./dojo-daemon send "our"      # Ship name
./dojo-daemon send "now"      # Current time
```

### Checking Output
```bash
./dojo-daemon output          # Get current terminal state
./dojo-daemon watch           # Watch output live (Ctrl+C to stop)
```

### Stopping
```bash
./dojo-daemon stop            # Clean shutdown
```

### Daemon Features
- **Persistent connection** - Maintains connection to Urbit
- **Event capture** - Never miss delayed output or slog messages
- **Output cleaning** - Removes duplicate prompts for cleaner display
- **Error handling** - Automatic reconnection on network issues
- **Event logging** - Full event history in `.dojo_daemon/events.jsonl`

## Testing Notes

### Commands Verified on ~saphex-radsem-niblyx-malnus
All basic commands tested and working correctly:
- ✓ Special variables (`our`, `now`)
- ✓ File system operations (`+ls`, `+tree`)
- ✓ System info (`+code`, `+vats`)
- ✓ Available generators confirmed in `/gen/` directory
- ✓ Error handling (invalid syntax detection)
- ✓ Long-running commands (+vats output)

### Daemon Testing Results
- ✓ Startup/shutdown cycle works correctly
- ✓ Commands execute and output is captured
- ✓ Invalid commands handled gracefully (bell detection)
- ✓ Output cleaning removes duplicate prompts
- ✓ Event logging captures all terminal events
- ✓ Status tracking shows connection health

### Available Desks
- `%base` - Base system desk
- `%kids` - Child ship management
- `%penpal` - Currently suspended
- `%webterm` - Essential, running

### Troubleshooting
- Check `./dojo-daemon status` for connection issues
- View daemon logs: `cat .dojo_daemon/daemon.log`
- Raw events available in: `.dojo_daemon/events.jsonl`
- If daemon won't start, check if Urbit ship is running

---

*Generated from Urbit documentation at docs.urbit.org*
*Tested on ~saphex-radsem-niblyx-malnus with improved clurd daemon*
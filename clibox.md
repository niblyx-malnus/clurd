# clibox

A simple CLI skeleton for building Urbit command-line interfaces using the `%shoe` library.

## Overview

clibox demonstrates how to build native Urbit CLI applications that integrate with your ship's terminal system. Unlike generators which are one-shot commands, CLI apps provide persistent interactive environments with custom command parsing and state management.

## Key Components

### CLI Application (`/app/clibox.hoon`)
- **Agent with CLI interface** using `%shoe` library
- **Command parsing** via custom parser functions
- **State management** maintaining ship list
- **Interactive commands** with real-time feedback

### Command Parser (`/lib/command-parser.hoon`)
- **Structured parsing** for different command types
- **Argument handling** for commands like `add ~ship`
- **Error handling** for invalid commands

### Structure Types (`/sur/clibox.hoon`)
- **Actions** for agent state changes
- **Commands** for CLI parsing
- **Tab completion** help text

## CLI Commands

The example provides four commands:
- `dat` - Do a thing (demo action)
- `dan` - Do another (demo action)
- `lis` - List ships in state
- `add ~ship` - Add ship to list

## Setup Workflow

1. **Create and mount desk:**
   ```
   |new-desk %clibox
   |mount %clibox
   ```

2. **Copy template files:**
   ```bash
   rm -rf [ship]/clibox/*
   cp -r clibox/* [ship]/clibox/
   ```

3. **Install and commit:**
   ```
   |commit %clibox
   |install our %clibox
   ```

4. **Link to terminal:**
   ```
   :hood +hood/dojo/link %clibox
   ```

   **Note:** The standard `|link %clibox` command may not work on all ships. Use the full `:hood +hood/dojo/link %clibox` form instead.

5. **Use CLI commands:**
   ```
   dat                 :: → "Do a thing..."
   add ~sampel-palnet  :: → "Adding ship..."
   lis                 :: → Shows ship list
   dan                 :: → "Do another..."
   ```

6. **Switch back to dojo:**
   ```
   :hood +hood/dojo/unlink
   ```

## CLI Development Patterns

### Command Parsing
Commands are parsed using combinator functions:
```hoon
++  parse-add-a-ship
  ;~  (glue ace)
    (cold %add-a-ship (jest 'add'))
    ;~(pfix sig fed:ag)
  ==
```

### State Integration
CLI commands can modify agent state:
```hoon
%add-a-ship
`this(ships [ship.axn ships])
```

### Interactive Feedback
Commands produce immediate terminal output:
```hoon
%list-ships
(print-green-cards (turn ships |=(=ship (scot %p ship))))
```

### Agent Communication
CLI commands generate pokes to the main agent:
```hoon
%do-a-thing
[%pass / %agent [our dap]:bowl %poke clibox-action+!>(command)]~
```

## Architecture

**Terminal Integration:**
- Uses `%shoe` library for terminal interface
- Handles command parsing and completion
- Manages terminal sessions and output

**Agent Pattern:**
- CLI front-end + agent back-end
- Commands trigger agent pokes
- Agent maintains persistent state

**Command Flow:**
1. User types command in terminal
2. `%shoe` parses input via command-parser
3. CLI generates poke to main agent
4. Agent processes action and updates state
5. Result displayed in terminal

## When to Use CLI Apps

- **Interactive tools** requiring persistent sessions
- **System administration** commands
- **Multi-step workflows** with state
- **Development tools** for debugging/monitoring
- **Integration with terminal** for Unix-like experience

## Best Practices

- **Clear command syntax** - Use intuitive command names
- **Good error messages** - Help users understand parsing failures
- **Tab completion** - Provide command discovery
- **State visibility** - Commands to inspect current state
- **Clean linking** - Easy to connect/disconnect from terminal

## File Structure

```
clibox/
├── app/
│   └── clibox.hoon        # Main CLI agent
├── lib/
│   └── command-parser.hoon # Command parsing logic
├── sur/
│   └── clibox.hoon        # Types and structures
└── mar/
    └── clibox/
        └── action.hoon    # Action mark file
```

Perfect for learning Urbit CLI development patterns!
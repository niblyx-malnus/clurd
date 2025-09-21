# gendesk

Complete guide to the three types of Urbit generators with working examples.

## Generator Types

### Naked Generators
**Purpose**: Pure computation with direct input

**Structure**: Simple gate (`|=`) that takes input and returns output

**Use when**: You need basic calculations or data transformations

```hoon
:: Naked generator - adds two numbers
:: Usage: +add [5 3]
|=  [a=@ud b=@ud]
^-  @ud
(add a b)
```

**Input format**: Direct arguments after generator name
Example: `+add [10 5]` → `15`

### %say Generators
**Purpose**: Access to system environment (ship, desk, time, entropy)

**Structure**: Head-tagged cell with `%say` and gate that receives environment + arguments

**Use when**: You need system information or optional arguments

```hoon
:: %say generator - shows system info with message
:: Usage: +info 'hello'
:-  %say
|=  [[now=@da eny=@uvJ bec=beak] [msg=@t ~] ~]
:-  %noun
:~  "Message: {<msg>}"
    "Ship: {<p.bec>}"
    "Desk: {<q.bec>}"
    "Time: {<now>}"
==
```

**Input format**:
- `[environment]` - Automatically provided by Dojo (now, entropy, beak)
- `[required-args]` - Required arguments in a cell
- `[optional-args]` - Optional named arguments with defaults

Example: `+info 'testing'` → Shows system info with message

### %ask Generators
**Purpose**: Interactive prompts and user input during execution

**Structure**: Head-tagged with `%ask`, uses `sole-result` type and prompt functions

**Use when**: You need interactive workflows or step-by-step input

```hoon
:: %ask generator - interactive greeting
:: Usage: +greet
/-  sole
/+  generators
=,  [sole generators]
:-  %ask
|=  *
^-  (sole-result (cask tang))
%+  print    leaf+"What is your name?"
%+  prompt   [%& %prompt "name: "]
|=  t=tape
%+  produce  %tang
:~  leaf+"Hello, {t}!"
    leaf+"Nice to meet you."
==
```

**Requirements**: Must import `/-  sole` and `/+  generators`
**Input format**: Interactive prompts during execution
Example: `+greet` → Prompts "What is your name?" → User types → "Hello, {name}!"

## Key Differences

| Type | System Access | Arguments | Interactive | Output Type |
|------|---------------|-----------|-------------|-------------|
| Naked | No | Direct | No | Any |
| %say | Yes (now, our, bec, eny) | Required + Optional | No | Any |
| %ask | Limited | Minimal | Yes | `sole-result` |

## Usage Examples

```
:: Create new desk from template
|new-desk %mydesk gendesk
|mount %mydesk

:: Basic generator calls (all patterns from quick_reference.md)
+mydesk!add [%add 10 5]      :: → 15 (naked with operation)
+mydesk!add [%mul 4 6]       :: → 24 (naked with multiplication)
+mydesk!info 'testing'       :: → System info (say)
+mydesk!greet                :: → Interactive prompt (ask)

:: Agent interaction (clean agent-specific pattern)
:increment|inc               :: → Clean agent poke (agent-specific generator)

:: Variable assignment with generators
=result +mydesk!add [%add 7 3]  :: Store result for further computation
=sysinfo +mydesk!info 'data'   :: Store system info

:: Using stored results
(mul result 10)              :: Compute with stored generator output

:: Different argument types
+mydesk!add [%div 20 4]      :: Numbers
+mydesk!info 'hello world'   :: Text/cord
+mydesk!info ~             :: Null argument
```

## All Generator Usage Patterns

### Basic Execution
- `+generator` - Run from current desk
- `+desk!generator` - Run from specific desk
- `+desk!generator args` - Run with arguments

### Agent Interaction
- `:agent +generator` - Send generator output as poke to agent
- `:agent +desk!generator args` - Agent poke from specific desk
- `:agent|generator` - Clean agent-specific generator syntax

### Variable Assignment & Computation
- `=var +generator args` - Store generator output for computation
- `(function var)` - Use stored results in expressions
- `function:var` - Access library functions from stored builds

### Argument Types
- `+gen [%operation 1 2]` - Structured data (naked generators)
- `+gen 'text'` - Text/cord arguments
- `+gen ~` - Null/empty arguments
- `+gen [arg1 arg2 ~]` - Multiple arguments (%say generators)

## When to Use Which

- **Naked**: Simple math, text processing, pure functions
- **%say**: System utilities, debugging tools, timestamped operations
- **%ask**: Setup wizards, interactive configuration, multi-step workflows

## Getting Started

1. **Create new desk from template:**
   ```
   |new-desk %mygens gendesk
   |mount %mygens
   ```

2. **Test all generators:**
   ```
   +mygens!add [%add 7 3]       :: → 10 (naked: math operations)
   +mygens!info 'hello'         :: → System info (say: ship, desk, time)
   +mygens!greet                :: → Interactive prompt (ask: name input)
   :increment|inc               :: → Agent poke (agent-specific: increment action)

   :: Test variable assignment
   =result +mygens!add [%mul 5 4]
   (add result 10)              :: → 30 (20 + 10)
   ```

3. **Create your own generators:**
   - Copy existing examples as starting points
   - Follow the patterns shown above
   - Test immediately after writing

## Development Workflow

1. **Write generator** in `/gen/yourgen.hoon`
2. **Commit changes** with `|commit %mygens`
3. **Test immediately** with `+mygens!yourgen args`
4. **Iterate** based on results

## Best Practices

- **Start simple** - Use naked generators for basic computation
- **Add system access** - Use %say when you need ship/time/desk info
- **Go interactive** - Use %ask for multi-step workflows
- **Test early** - Verify each generator works before building complex logic
- **Use type hints** - `^-` return types help catch errors
- **Discovery** - Use tab completion to explore: `+[TAB]` shows generators
- **Variable storage** - Store generator output with `=var +gen` for computation

## File Structure

```
gendesk/
├── gen/
│   ├── add.hoon      # Naked generator - math operations
│   ├── info.hoon     # %say generator - system information
│   ├── greet.hoon    # %ask generator - interactive prompts
│   └── increment/    # Agent-specific generators
│       └── inc.hoon  # Clean agent poke syntax
├── lib/
│   └── generators.hoon  # %ask helper functions
└── sur/
    └── sole.hoon     # %ask type definitions
```

Perfect for learning Urbit generator fundamentals!
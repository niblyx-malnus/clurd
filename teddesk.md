# Minimal Desk for Thread-Driven Development (teddesk)

Create a working Urbit desk optimized for thread-driven development in 5 commands using the teddesk template.

## Prerequisites

- Running Urbit ship accessible via clurd
- This repo cloned with the `teddesk/` template directory

## Process

1. **Create new desk:**
   ```bash
   ./run.sh dojo "|new-desk %yourdesk"
   ```

2. **Mount to filesystem:**
   ```bash
   ./run.sh dojo "|mount %yourdesk"
   ```

3. **Copy template to your mounted desk:**
   ```bash
   # Replace the contents of your mounted desk with the teddesk template
   cp -r teddesk/* /path/to/your/ship/yourdesk/
   ```

4. **Install the desk:**
   ```bash
   ./run.sh dojo "|install our %yourdesk"
   ```

5. **Commit and start:**
   ```bash
   ./run.sh dojo "|commit %yourdesk" 10
   ```

## Test the Thread-Driven Pattern

The template creates an increment agent with a powerful thread example. Test it:

```bash
# Check initial value
./run.sh dojo ".^(@ %gx /=increment=/value/noun)"

# Run thread to increment 5 times
./run.sh dojo "-yourdesk!increment-n-times 5"

# Verify final value
./run.sh dojo ".^(@ %gx /=increment=/value/noun)"
```

You should see the thread orchestrate multiple agent pokes while providing real-time logging and returning the final result.

## What You Get

The teddesk template contains exactly 17 files - the minimum needed for thread-driven development:

**Agent Foundation:**
- **2 config files**: `sys.kelvin`, `desk.bill`
- **3 custom files**: `app/increment.hoon`, `sur/increment.hoon`, `mar/increment/action.hoon`
- **7 system files**: Essential marks and libraries from Urbit core

**Thread Infrastructure:**
- **3 thread libraries**: `lib/strand.hoon`, `lib/strandio.hoon`, `sur/spider.hoon`
- **1 example thread**: `ted/increment-n-times.hoon`
- **1 example library**: `lib/skeleton.hoon`

## Thread-Driven Development Pattern

**Key Architecture:**
- **Agents hold state** - Simple CRUD operations with proper state persistence
- **Threads do work** - Complex logic, orchestration, and coordination
- **Clean separation** - State management vs. computational workflows

**The Example Thread Demonstrates:**
1. **Agent coordination** - Multiple pokes in sequence
2. **State monitoring** - Scrying agent state before/after
3. **Control flow** - Loops with strand binding
4. **Observable progress** - Real-time logging at each step
5. **Data collection** - Structured return values

## Next Steps

To customize for your project:
1. Rename `increment` to your agent name in the files
2. Update `desk.bill` with your agent name
3. Modify the agent logic in `app/` and data structures in `sur/`
4. Create threads in `ted/` for computational workflows
5. Use `strandio` functions for agent coordination, file operations, HTTP requests, timers, etc.

## Thread Development Guidelines

**Start with observable output:**
- Every thread should produce clear, visible results
- Use `~&` for progress logging
- Return meaningful data structures

**Build incrementally:**
- Start with the simplest working thread
- Add one capability at a time
- Test each addition immediately

**Follow strandio patterns:**
- Use `;<` for strand binding
- Prefer `scry:strandio` for state reading
- Use proper cage construction for pokes

The teddesk template demonstrates all essential patterns for building powerful, maintainable Urbit applications using the thread-driven development methodology.
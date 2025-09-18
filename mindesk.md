# Minimal Desk Creation with clurd

Create a working Urbit desk in 5 commands using the mindesk template.

## Prerequisites

- Running Urbit ship accessible via clurd
- This repo cloned with the `mindesk/` template directory

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
   # Replace the contents of your mounted desk with the mindesk template
   cp -r mindesk/* /path/to/your/ship/yourdesk/
   ```

4. **Install the desk:**
   ```bash
   ./run.sh dojo "|install our %yourdesk"
   ```

5. **Commit and start:**
   ```bash
   ./run.sh dojo "|commit %yourdesk" 10
   ```

## Test the Agent

The template creates an increment agent. Test it:

```bash
# Check initial value
./run.sh dojo ".^(@ %gx /=increment=/value/noun)"

# Increment the counter
./run.sh dojo ":increment &increment-action [%increment ~]"

# Verify it worked
./run.sh dojo ".^(@ %gx /=increment=/value/noun)"
```

You should see:
- Initial value: `0`
- After increment: `1`
- Log message: `"incrementing from 0 to 1"`

## What You Get

The mindesk template contains exactly 12 files - the minimum needed for a working Gall agent:

- **2 config files**: `sys.kelvin`, `desk.bill`
- **3 custom files**: `app/increment.hoon`, `sur/increment.hoon`, `mar/increment/action.hoon`
- **7 system files**: Essential marks and libraries from the Urbit source tree

This gives you a working foundation to build any Urbit application.

## Next Steps

To customize for your project:
1. Rename `increment` to your agent name in the files
2. Update `desk.bill` with your agent name
3. Modify the agent logic in `app/` and data structures in `sur/`
4. Recommit with `|commit` and `|install`

The template demonstrates all essential Gall patterns: state management, poke handling, scry endpoints, and proper error handling.
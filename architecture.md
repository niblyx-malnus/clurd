# Urbit Dojo Architecture: Deep Technical Dive

## Why urbit_dojo.py Exists

### The Problem Space

Urbit's dojo (command-line interface) is the primary way developers interact with running Urbit ships. However, the native dojo experience has significant limitations:

1. **No programmatic access** - Dojo is designed for human terminal interaction, not automation
2. **No reliable output parsing** - Terminal output mixes commands, results, and system messages
3. **Stateful navigation** - History and tab completion depend on hidden terminal state
4. **Bell-based feedback** - Syntax errors are communicated through terminal bells, not error messages
5. **Real-time streaming** - Output arrives via Server-Sent Events (SSE) with complex blit protocol

### The Solution

`urbit_dojo.py` creates a **terminal emulator** that speaks Urbit's blit protocol, enabling programmatic interaction with dojo while preserving the exact behavior a human would experience.

## Architecture Overview

```
┌─────────────────┐
│  Python Client  │
│   (clurd user)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ urbit_dojo.py   │
│                 │
│ ┌─────────────┐ │
│ │TerminalBuf  │ │ ← Simulates VT100 terminal
│ └─────────────┘ │
│ ┌─────────────┐ │
│ │ SSE Client  │ │ ← Handles real-time events
│ └─────────────┘ │
│ ┌─────────────┐ │
│ │ Blit Parser │ │ ← Interprets Urbit commands
│ └─────────────┘ │
└────────┬────────┘
         │ HTTP/SSE
         ▼
┌─────────────────┐
│  Urbit Ship     │
│                 │
│ ┌─────────────┐ │
│ │   webterm   │ │ ← Terminal session manager
│ └─────────────┘ │
│ ┌─────────────┐ │
│ │    dojo     │ │ ← Command interpreter
│ └─────────────┘ │
└─────────────────┘
```

## Core Components

### 1. TerminalBuffer Class

**Purpose**: Simulate a VT100-compatible terminal that maintains the exact visual state Urbit expects.

**Key Attributes**:
- `screen`: List of strings representing screen lines
- `cursor_x`, `cursor_y`: Current cursor position
- `width`, `height`: Terminal dimensions
- `bell_occurred`: Boolean tracking if bell event occurred

**Key Methods**:
- `write_text(text)`: Add text at cursor position
- `set_cursor_col(col)`: Move cursor horizontally
- `newline()`: Move cursor to start of next line
- `clear_screen()`: Clear entire screen
- `get_visible_text()`: Extract what's currently visible
- `record_bell()`: Record bell event occurrence

**Why This Exists**: Urbit sends terminal control commands (blits) that assume a stateful terminal. Without simulating this, we can't know what's actually displayed.

### 2. UrbitDojo Class

**Purpose**: Main orchestrator that manages the SSE connection, sends commands, and interprets responses.

**Key Attributes**:
- `cookies`: HTTP session cookies for authentication
- `channel_id`: Unique SSE channel identifier
- `ship_url`, `ship_name`, `access_code`: Connection parameters

**Key Methods**:

#### Connection Management
- `connect()`: Establishes authenticated session and creates SSE channel
- `disconnect()`: Closes connections and stops background threads

#### Command Execution
- `run(command, timeout)`: High-level library method using character-by-character input
- `send_and_listen(chars, duration)`: Character-by-character sending with event capture

#### Specialized Features (Library-Only Access)
- `get_completions(prefix)`: Extract tab completion suggestions
- `validate_command(command)`: Test syntax without execution
- `explore_syntax(base, test_chars)`: Systematically test character acceptance
- `send_until_bell(chars)`: Character-level syntax validation with bell detection
- `send_command_batched(command)`: High-performance batched input for faster execution
- `send_chars_batched(chars)`: Batched sending with arrow key support

**Note**: These specialized features require direct Python library usage and are not accessible through the `./run.sh` shell interface.

**Important**: The shell interface (`./run.sh dojo`) defaults to batched mode for performance, while the library method `UrbitDojo.run()` defaults to character-by-character mode for debugging capabilities.

## Data Flow

### 1. Command Execution Flow

```
User Input: "(add 5 4)"
    │
    ▼
parse_command_string()
    │ Converts to: ['(', 'a', 'd', 'd', ' ', '5', ' ', '4', ')']
    ▼
send_and_listen()
    │
    ├─► For each character:
    │      │
    │      ▼
    │   HTTP PUT /~/channel/{id}
    │   Body: [{"action": "poke", "app": "herm", "mark": "herm-task", "json": {"session": "session", "belt": {"txt": ["a"]}}}]
    │      │
    │      ▼
    │   SSE Stream Returns:
    │   data: {"json": {"mor": [{"put": ["a"]}]}}}
    │      │
    │      ▼
    │   TerminalBuffer.write_text("a")
    │
    ├─► Send '\r' (return key)
    │      │
    │      ▼
    │   Dojo executes command
    │      │
    │      ▼
    │   SSE Stream Returns:
    │   data: {"json": {"mor": [{"put": ["9\r\n"]}]}}}
    │
    ▼
Extract output: "9"
```

### 2. Bell Detection Flow (Syntax Validation)

```
Invalid Input: "(add 5 )"
    │
    ▼
send_until_bell(['(', 'a', 'd', 'd', ' ', '5', ' ', ')'])
    │
    ├─► Send '(' → Accepted
    ├─► Send 'a' → Accepted
    ├─► Send 'd' → Accepted
    ├─► Send 'd' → Accepted
    ├─► Send ' ' → Accepted
    ├─► Send '5' → Accepted
    ├─► Send ' ' → Accepted
    ├─► Send ')' → BELL! (syntax error)
    │      │
    │      ▼
    │   SSE: {"json": {"mor": [{"bel": null}]}}
    │
    ▼
Return: BellResponse(chars_accepted=7, chars_rejected=[')'])
```

### 3. Tab Completion Flow

```
Input: "ad\t"
    │
    ▼
get_completions("ad")
    │
    ├─► Send ['a', 'd', '\t']
    │      │
    │      ▼
    │   SSE Returns completion list:
    │   {"json": {"mor": [{"put": ["add  sub  mul  div"]}]}}}
    │      │
    │      ▼
    │   Parse and extract
    │
    ▼
Return: ["add", "sub", "mul", "div"]
```

## Protocol Details

### Blit Commands (Urbit → Terminal)

Urbit sends "blit" commands to control the terminal:

```python
{
    "put": ["text"]      # Display text
    "bel": null         # Ring bell (error)
    "clr": null         # Clear screen
    "hop": [5]          # Move cursor to column 5
    "nel": null         # New line
    "sag": ["/path"]    # Save to path
    "sav": ["/path"]    # Save file
    "url": ["http..."]  # URL to open
    "wyp": null         # Wipe line
}
```

### Belt Commands (Terminal → Urbit)

We send "belt" commands to provide input:

```python
{
    "txt": ["a"]        # Regular character(s) - single char in debug mode, multiple in batched mode
    "ret": null        # Return/enter key
    "bac": null        # Backspace
    "aro": "u"         # Arrow key (u/d/l/r)
    "del": null        # Delete
    "hit": [row, col]  # Mouse click
    "mod": {"mod": "ctl", "key": "c"}  # Control key
}
```

### Special Sequences

- `\t` → Tab completion request
- `\r` → Execute command
- `\\up` → History navigation
- `\\left` → Cursor movement

## Batching Strategies: Two Modes for Different Needs

urbit_dojo provides **two distinct input strategies** to balance performance with debugging capabilities:

### Mode 1: Batched Input (Default) - Performance Optimized

**Default behavior** - groups consecutive printable characters into single HTTP requests:

```python
# quick_run_batched() - Fast execution
# Command "(add 5 4)" becomes only 2 HTTP requests:

PUT /~/channel/123 [{"action": "poke", "app": "herm", "mark": "herm-task", "json": {"session": "session", "belt": {"txt": ["(", "a", "d", "d", " ", "5", " ", "4", ")"]}}}]
PUT /~/channel/123 [{"action": "poke", "app": "herm", "mark": "herm-task", "json": {"session": "session", "belt": {"ret": null}}}]
```

**Key Benefits:**
- **5-10x faster execution** due to reduced HTTP overhead
- **Mimics webterm's paste behavior** - exactly how webterm handles pasted text
- **Efficient for normal command execution** where you just want results

**Performance Impact:**
- Simple command: **2 HTTP requests** vs 10 with character-by-character
- Complex scry: **2 HTTP requests** vs 32 with character-by-character
- Network overhead reduced by 80-90%

### Mode 2: Character-by-Character (--slow flag) - Debug Mode

**Debug behavior** - each character is a separate HTTP request:

```python
# quick_run() - Precise execution
# Command "(add 5 4)" becomes 10 individual HTTP requests:

PUT /~/channel/123 [{"action": "poke", "app": "herm", "mark": "herm-task", "json": {"session": "session", "belt": {"txt": ["("]}}}]
PUT /~/channel/123 [{"action": "poke", "app": "herm", "mark": "herm-task", "json": {"session": "session", "belt": {"txt": ["a"]}}}]
PUT /~/channel/123 [{"action": "poke", "app": "herm", "mark": "herm-task", "json": {"session": "session", "belt": {"txt": ["d"]}}}]
# ... 7 more character requests ...
PUT /~/channel/123 [{"action": "poke", "app": "herm", "mark": "herm-task", "json": {"session": "session", "belt": {"ret": null}}}]
```

**Key Benefits:**
- **Bell detection**: Exact character positioning for syntax errors
- **Tab completion debugging**: Character-by-character context building
- **Interactive debugging**: See exactly how Urbit processes each character
- **Perfect state synchronization**: Terminal state matches Urbit's expectations exactly

### Usage Examples:

```bash
# Fast mode (default) - for normal usage:
./run.sh dojo "(add 5 4)"                    # 2 HTTP requests

# Debug mode - for syntax validation and debugging:
./run.sh dojo "(add 5 4)" --slow             # 10 HTTP requests
./run.sh dojo "ad\\t" --slow --no-enter      # Tab completion debugging
```

## Output Batching (Both Modes)

Regardless of input mode, **output is always batched efficiently**:

### Batched Blits in SSE Responses

**Multiple terminal operations arrive in single SSE messages:**

```json
// Single SSE event can contain multiple blits:
{
  "json": {
    "mor": [
      {"put": ["Result: "]},     // Display text
      {"put": ["9"]},            // Display result
      {"nel": null},             // New line
      {"put": ["~zod:dojo> "]},  // Show prompt
      {"hop": [12]}              // Position cursor
    ]
  }
}
```

**Processing Multiple Blits:**

```python
def _extract_output(self, events: List[Dict]) -> str:
    terminal = TerminalBuffer()

    # Process all events through the terminal buffer
    for event in events:
        if 'json' in event and 'mor' in event['json']:
            for blit in event['json']['mor']:
                self._process_blit(blit, terminal)

    return terminal.get_visible_text()
```

### Why These Strategies Work

**Batched Input Benefits (Default Mode):**
- **Performance**: 5-10x faster due to reduced HTTP request overhead
- **Webterm compatibility**: Mimics exactly how webterm handles pasted text
- **Efficiency**: Optimal for normal command execution where you just want results

**Character-by-Character Benefits (Debug Mode):**
- **Precise error detection**: `send_until_bell()` can identify exactly which character caused rejection
- **Tab completion**: Context builds character-by-character for accurate suggestions
- **State synchronization**: Terminal state matches Urbit's expectations exactly
- **Interactive debugging**: See exactly how Urbit processes each character

**Output Batching Benefits (Both Modes):**
- **Performance**: Multiple related screen updates happen atomically
- **Atomicity**: Complex output (results + prompts + formatting) appears together
- **Efficiency**: Reduces SSE message overhead for complex operations

### Real Example: Command Execution Flow Comparison

**Default Mode (Batched):**
```
Input:  "(add 5 4)\r"
        │
        ▼
Batched belt commands:
        PUT {"txt": ["(","a","d","d"," ","5"," ","4",")"]}  → SSE: {"json": {"mor": [{"put": ["(add 5 4)"]}]}}}
        PUT {"ret": null}                                   → SSE: BATCHED RESPONSE:
                                                                    {
                                                                      "json": {"mor": [
                                                                        {"nel": null},
                                                                        {"put": ["9"]},
                                                                        {"nel": null},
                                                                        {"put": ["~zod:dojo> "]}
                                                                      ]}
                                                                    }
Total: 2 HTTP requests
```

**Debug Mode (--slow):**
```
Input:  "(add 5 4)\r"
        │
        ▼
Individual belt commands:
        PUT {"txt": ["("]}      → SSE: {"json": {"mor": [{"put": ["("]}]}}
        PUT {"txt": ["a"]}      → SSE: {"json": {"mor": [{"put": ["a"]}]}}
        PUT {"txt": ["d"]}      → SSE: {"json": {"mor": [{"put": ["d"]}]}}
        PUT {"txt": ["d"]}      → SSE: {"json": {"mor": [{"put": ["d"]}]}}
        PUT {"txt": [" "]}      → SSE: {"json": {"mor": [{"put": [" "]}]}}
        PUT {"txt": ["5"]}      → SSE: {"json": {"mor": [{"put": ["5"]}]}}
        PUT {"txt": [" "]}      → SSE: {"json": {"mor": [{"put": [" "]}]}}
        PUT {"txt": ["4"]}      → SSE: {"json": {"mor": [{"put": ["4"]}]}}
        PUT {"txt": [")"]}      → SSE: {"json": {"mor": [{"put": [")"]}]}}
        PUT {"ret": null}       → SSE: BATCHED RESPONSE:
                                        {
                                          "json": {"mor": [
                                            {"nel": null},
                                            {"put": ["9"]},
                                            {"nel": null},
                                            {"put": ["~zod:dojo> "]}
                                          ]}
                                        }
Total: 10 HTTP requests (enables character-level bell detection)
```

### Performance Characteristics

**HTTP Request Count Comparison:**

| Command Type | Batched Mode (Default) | Debug Mode (--slow) | Speed Improvement |
|--------------|------------------------|---------------------|-------------------|
| `"our"` | 2 requests | 4 requests | 2x faster |
| `"(add 5 4)"` | 2 requests | 10 requests | 5x faster |
| `".^(@ %gx /=base=/sys/kelvin)"` | 2 requests | 32 requests | 16x faster |
| Tab completion `"ad\t"` | 2 requests | 3 requests | 1.5x faster |

**Timing Delays:**
```python
DEFAULT_CHAR_DELAY = 0.05          # 50ms between characters (debug mode only)
DEFAULT_POST_SEQUENCE_WAIT = 1.0   # 1s after command submission (both modes)
```

**When to Use Each Mode:**

**Use Batched Mode (Default) For:**
- Normal command execution where you just want results
- Performance-critical automation scripts
- Bulk operations where speed matters
- Production use cases

**Use Debug Mode (--slow) For:**
- Syntax validation and error debugging
- Tab completion exploration and debugging
- Understanding exactly how Urbit processes input
- Investigating bell events and character rejection
- Development and learning scenarios

**Why Debug Mode Preserves Character-Level Features:**

Character-by-character sending enables:

1. **Bell detection**: Know exactly which character caused syntax error
2. **Tab completion**: Urbit knows cursor position for accurate completion
3. **Interactive feedback**: See real-time character-by-character validation
4. **State synchronization**: Terminal state exactly matches Urbit's expectations

### Stream Processing Architecture

**Single-threaded with queue:**

```python
def _listen_to_stream(self, duration: float):
    events = queue.Queue()

    def stream_reader():
        for event in response.iter_lines():
            events.put(event)

    # Process events after collection period
    while not events.empty():
        event = events.get()
        self._process_event(event)  # May process multiple blits per event
```

This design ensures that:
- **Input fidelity**: Every character is validated and positioned correctly
- **Output efficiency**: Related screen updates are atomic and fast
- **Protocol compliance**: Matches exactly how webterm behaves
- **Debug capability**: Character-level error detection and tab completion

## Key Design Decisions

### 1. Terminal Simulation vs Text Parsing

**Decision**: Simulate a full terminal rather than parse text streams.

**Why**: Urbit's output depends on cursor position, screen clearing, and overwriting. Without simulating the terminal, we can't know what's actually visible.

### 2. Dual Input Strategies

**Decision**: Provide both batched (fast) and character-by-character (debug) input modes.

**Why**: Different use cases need different trade-offs:
- **Batched mode**: 5-10x faster for normal operations, mimics webterm paste behavior
- **Debug mode**: Preserves character-level bell detection and tab completion debugging

### 3. SSE vs WebSocket

**Decision**: Use Server-Sent Events like Urbit's webterm does.

**Why**: This is Urbit's native protocol. WebSockets would require a different interface.

### 4. Stateless Command Execution

**Decision**: Each `run()` command resets the channel.

**Why**: Prevents state pollution between commands. History and tab completion remain predictable.

## Error Handling

### Connection Failures
- Automatic channel recreation on 404
- Configurable timeouts for long operations
- Graceful SSE stream termination

### Syntax Errors
- Bell detection for invalid input
- Character-level error positioning
- Rejected character identification

### Stream Processing
- Queue-based event collection
- Thread-safe stream listening
- Timeout-based stream termination

## Performance Considerations

### Delays and Timing
```python
DEFAULT_LISTEN_DURATION = 0.5      # How long to collect output
DEFAULT_CHAR_DELAY = 0.05          # Between characters (for tab completion)
DEFAULT_POST_SEQUENCE_WAIT = 1.0   # After command submission
```

These delays balance between:
- **Too fast**: Missing output that arrives late
- **Too slow**: Poor user experience

### Channel Management
- Channels are created on-demand
- Each command typically uses a fresh channel
- Prevents cross-command interference

## Integration Points

### For Python Users
```python
from urbit_dojo import UrbitDojo

dojo = UrbitDojo(url, ship, code)
result = dojo.run("(add 5 4)")  # Returns: DojoResponse object
print(result.output)  # Prints: "9"
```

### For Shell Users
```bash
./run.sh dojo "(add 5 4)"       # Via shell wrapper
```

### For Claude/AI
```python
# Exploration and learning
completions = dojo.get_completions("ad")
validation = dojo.validate_command("(add 5 )")
```

## Why This Architecture Works

1. **Fidelity**: By simulating the terminal, we get exactly what a human would see
2. **Debugging**: Bell detection provides syntax validation without parsing Hoon
3. **Discovery**: Tab completion extraction enables systematic exploration
4. **Reliability**: Character-by-character input matches Urbit's expectations
5. **Simplicity**: Single-file implementation with minimal dependencies

## Future Considerations

### Potential Improvements
- WebSocket support for lower latency
- Persistent connections for long-running sessions
- Multi-command transactions
- Parallel command execution

### Known Limitations
- Single-threaded stream processing
- No built-in retry logic for network failures
- Terminal size assumptions (100000 width hack)
- Character delays needed for tab completion

## Summary

`urbit_dojo.py` solves the impedance mismatch between Urbit's human-centric terminal interface and the need for programmatic control. By faithfully simulating a terminal and speaking Urbit's blit protocol, it enables reliable automation while preserving the exact behavior developers expect from manual interaction.

The key insight: **Don't parse the stream, simulate the terminal.**
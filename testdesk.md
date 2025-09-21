# testdesk

A comprehensive desk template for test-driven development on Urbit, supporting both library and gall agent testing.

## Purpose

testdesk provides a foundation for writing comprehensive unit tests for both Hoon libraries and gall agents, following Urbit's standard testing patterns. It demonstrates proper TDD workflow with real examples for both pure functions and stateful agents.

## What's Included

### Library Testing
- **Standard test library integration** - Uses `/+  *test` for `expect-eq`, `expect`, `expect-fail`
- **Example library** (`/lib/text-utils.hoon`) - Text processing functions with comprehensive tests
- **Comprehensive test suite** (`/tests/text-utils.hoon`) - Real-world library testing patterns

### Agent Testing
- **Monadic testing framework** (`/lib/test-agent.hoon`) - Advanced agent testing with `mare` monad
- **Example agent** (`/app/increment.hoon`) - Stateful counter agent with subscriptions
- **Comprehensive agent tests** (`/tests/increment.hoon`) - Full agent lifecycle testing

### Demo Tests
- **Simple examples** (`/tests/demo.hoon`) - Basic passing/failing test examples for immediate verification

## Usage

1. Create a new desk from this template:
   ```
   |new-desk %mytest testdesk
   |mount %mytest
   ```

2. Add your library to `/lib/`:
   ```hoon
   :: /lib/mylib.hoon
   |%
   ++  my-function
     |=  input=@ud
     (add input 1)
   --
   ```

3. Write tests in `/tests/`:
   ```hoon
   :: /tests/mylib.hoon
   /+  *test, mylib
   |%
   ++  test-my-function
     %+  expect-eq
       !>  6
     !>  (my-function:mylib 5)
   --
   ```

4. Run tests:
   ```
   |commit %mytest
   -mytest!test /=mytest=/tests
   ```

## Testing Patterns

### Library Testing
- **expect-eq** - Compare two values: `%+  expect-eq  !>  expected  !>  actual`
- **expect** - Assert boolean true: `%-  expect  !>  (some-predicate input)`
- **expect-fail** - Verify crash: `%-  expect-fail  |.((crash-function input))`

### Agent Testing (Monadic Framework)
- **Agent initialization**: `do-init` tests agent startup and initial state
- **Poke testing**: `do-poke` tests agent message handling with automatic state management
- **Card verification**: `ex-cards` validates emitted cards with `ex-fact`, `ex-poke` helpers
- **Subscription testing**: `do-watch`/`do-leave` test subscription lifecycle
- **State inspection**: `get-save` retrieves agent state for verification
- **Bowl manipulation**: `set-src`, `jab-bowl` for multi-ship testing scenarios
- **Scry mocking**: `set-scry-gate` for dependency injection

#### Monadic Test Structure
```hoon
++  test-example
  %-  eval-mare
  =/  m  (mare ,~)
  ^-  form:m
  ;<  ~                bind:m  (set-scry-gate scries)
  ;<  caz=(list card)  bind:m  (do-init dap agent)
  ;<  ~                bind:m  (ex-cards caz ~)
  ;<  caz=(list card)  bind:m  (do-poke %my-mark !>(data))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/path] %mark !>(result))])
  ;<  state=vase       bind:m  get-save
  %+  ex-equal  !>(expected-state)  state
```

## Notes

- The `/ted/test.hoon` thread is included for reference but we use the standard `-test` thread from base
- Test arms must start with `test-` prefix
- Use `;:  weld` to combine multiple assertions in one test function:
  ```hoon
  ++  test-my-function
    ;:  weld
      :: First assertion
      %+  expect-eq
        !>  5
        !>  (my-function 4)
      :: Second assertion
      %+  expect-eq
        !>  10
        !>  (my-function 9)
    ==
  ```

## Example Output

### Library Tests
```
built   /tests/text-utils/hoon
test-words: took µs/348
OK      /tests/text-utils/test-words
test-word-count: took µs/74
OK      /tests/text-utils/test-word-count
ok=%.y
```

### Agent Tests
```
built   /tests/increment/hoon
'%increment initialized'
test-init: took ms/3.372
OK      /tests/increment/test-init
'%increment initialized'
test-increment-pokes: took ms/4.025
OK      /tests/increment/test-increment-pokes
'%increment initialized'
test-subscriptions: took ms/4.479
OK      /tests/increment/test-subscriptions
ok=%.y
```

## Features Demonstrated

- **Library TDD**: Pure function testing with comprehensive edge cases
- **Agent TDD**: Stateful agent testing with lifecycle management
- **Monadic composition**: Clean, readable test chains with automatic state management
- **Card verification**: Precise testing of agent outputs and side effects
- **Multi-ship scenarios**: Cross-ship communication and permission testing
- **Integration testing**: Libraries working together with agents

Perfect for both library and agent development with confidence that your code works as intended.
# testdesk

A minimal desk template for test-driven development on Urbit.

## Purpose

testdesk provides a foundation for writing comprehensive unit tests for Hoon libraries following Urbit's standard testing patterns. It demonstrates proper TDD workflow with real examples.

## What's Included

- **Standard test library integration** - Uses `/+  *test` for `expect-eq`, `expect`, `expect-fail`
- **Example library** (`/lib/text-utils.hoon`) - Text processing functions with comprehensive tests
- **Demo tests** (`/tests/demo.hoon`) - Simple passing/failing test examples
- **Comprehensive test suite** (`/tests/text-utils.hoon`) - Real-world testing patterns

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

- **expect-eq** - Compare two values: `%+  expect-eq  !>  expected  !>  actual`
- **expect** - Assert boolean true: `%-  expect  !>  (some-predicate input)`
- **expect-fail** - Verify crash: `%-  expect-fail  |.((crash-function input))`

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

```
built   /tests/text-utils/hoon
test-words: took µs/348
OK      /tests/text-utils/test-words
test-word-count: took µs/74
OK      /tests/text-utils/test-word-count
ok=%.y
```

Perfect for library development with confidence that your code works as intended.
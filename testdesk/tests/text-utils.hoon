:: Tests for text-utils library
::
/+  *test, text-utils
|%
:: Test word counting functionality
::
++  test-word-count
  ;:  weld
    :: Empty string has zero words
    %+  expect-eq
      !>  0
      !>  (word-count:text-utils "")
    :: Single word
    %+  expect-eq
      !>  1
      !>  (word-count:text-utils "hello")
    :: Multiple words
    %+  expect-eq
      !>  3
      !>  (word-count:text-utils "hello world test")
    :: Words with extra spaces
    %+  expect-eq
      !>  3
      !>  (word-count:text-utils "  hello   world  test  ")
  ==
:: Test string reversal
::
++  test-reverse
  ;:  weld
    :: Empty string
    %+  expect-eq
      !>  ""
      !>  (reverse:text-utils "")
    :: Single character
    %+  expect-eq
      !>  "a"
      !>  (reverse:text-utils "a")
    :: Multiple characters
    %+  expect-eq
      !>  "olleh"
      !>  (reverse:text-utils "hello")
    :: Palindrome should equal itself when reversed
    %+  expect-eq
      !>  "racecar"
      !>  (reverse:text-utils "racecar")
  ==
:: Test palindrome detection
::
++  test-palindrome
  ;:  weld
    :: Empty string is palindrome
    %-  expect
      !>  (palindrome:text-utils "")
    :: Single character is palindrome
    %-  expect
      !>  (palindrome:text-utils "a")
    :: Simple palindrome
    %-  expect
      !>  (palindrome:text-utils "racecar")
    :: Non-palindrome
    %+  expect-eq
      !>  %.n
      !>  (palindrome:text-utils "hello")
    :: Case insensitive palindrome
    %-  expect
      !>  (palindrome:text-utils "Racecar")
  ==
:: Test word extraction
::
++  test-words
  ;:  weld
    :: Empty string
    %+  expect-eq
      !>  `(list tape)`~
      !>  (words:text-utils "")
    :: Single word
    %+  expect-eq
      !>  `(list tape)`~["hello"]
      !>  (words:text-utils "hello")
    :: Multiple words
    %+  expect-eq
      !>  `(list tape)`~["hello" "world" "test"]
      !>  (words:text-utils "hello world test")
    :: Extra spaces handled correctly
    %+  expect-eq
      !>  `(list tape)`~["hello" "world"]
      !>  (words:text-utils "  hello   world  ")
  ==
:: Test title case conversion
::
++  test-title-case
  ;:  weld
    :: Empty string
    %+  expect-eq
      !>  ""
      !>  (title-case:text-utils "")
    :: Single word lowercase
    %+  expect-eq
      !>  "Hello "
      !>  (title-case:text-utils "hello")
    :: Multiple words
    %+  expect-eq
      !>  "Hello World Test "
      !>  (title-case:text-utils "hello world test")
    :: Already capitalized
    %+  expect-eq
      !>  "Hello World "
      !>  (title-case:text-utils "Hello world")
  ==
:: Test edge cases and error conditions
::
++  test-edge-cases
  ;:  weld
    :: Very long string handling
    %+  expect-eq
      !>  26
      !>  (lent (reverse:text-utils "abcdefghijklmnopqrstuvwxyz"))
    :: Single space string
    %+  expect-eq
      !>  `(list tape)`~
      !>  (words:text-utils " ")
    :: Multiple spaces only
    %+  expect-eq
      !>  `(list tape)`~
      !>  (words:text-utils "    ")
  ==
--
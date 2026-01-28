:: This is a parsing library thrown together as an example for Claude.
::
:: Parsing Tutorial - Building Parsers from First Principles
::
:: This library demonstrates parser construction in Hoon, building from
:: simple character matching to complex compositional parsers. Each example
:: is immediately testable and demonstrates a fundamental parsing concept.
::
:: TESTING IN DOJO:
::   Every parser can be tested interactively using +scan or by calling
::   the parser gate directly with a $nail (position + remaining text).
::
::   Examples:
::     (scan "a" (just 'a'))                    :: Uses +scan wrapper
::     ((just 'a') [[1 1] "abc"])               :: Direct parser call
::
:: FUNDAMENTAL TYPES:
::   $hair - [line column] position in text
::   $nail - [position remaining-text] parser input
::   $edge - [position result-or-failure] parser output
::   $rule - gate from $nail to $edge (i.e., a parser)
::
:: PARSER BUILDERS:
::   +just - match specific character
::   +shim - match character in range
::   +star - apply rule repeatedly (0 or more times)
::   +cook - transform parse result with gate
::   +ifix - match surrounded content, discard delimiters
::   +stun - apply rule exact number of times
::
:: PARSER COMBINATORS (used with ;~ rune):
::   +plug - sequence parsers, return tuple of results
::   +pose - try parsers until one succeeds
::   +glue - parse with delimiter between each rule
::
:: OUTSIDE CALLERS (hide parser internals):
::   +scan - parse tape, crash on failure
::   +rust - parse tape, return unit
::   +rash - parse atom as tape, crash on failure
::   +rush - parse atom as tape, return unit
::
:: ROADMAP - Future Examples:
::
:: Examples 1-16 are complete and tested. Below are planned additions:
::
:: [ ] Example 17: Whitespace Handling
::     - +gap: required whitespace (one or more spaces/newlines)
::     - +gay: optional whitespace (zero or more)
::     - +ace: single space
::     - +vul: comment parsing (:: to newline)
::     - Practical: building whitespace-aware parsers
::
:: [ ] Example 18: String Parsing with Escapes
::     - +qit: characters in quoted strings
::     - +mes: escape sequences (\n, \t, \xHH)
::     - +qut: full quoted string parser (stdlib approach)
::     - Building custom escape handling
::
:: [ ] Example 19: Conditional Parsing (+sear, +less, +simu)
::     - +sear: conditional success (filter/validate results)
::     - +less: negative lookahead (parse A but not if followed by B)
::     - +simu: positive lookahead (check without consuming)
::     - Error handling and validation patterns
::
:: [ ] Example 20: Optional/Maybe Patterns (+punt, +easy)
::     - +punt: unitize a parse (wrap result in unit)
::     - +easy: always succeeds with constant value
::     - Default values with ;~(pose rule (easy default))
::     - Building optional components
::
:: [ ] Example 21: List Building (+stir, +stag)
::     - +stir: fold over repeated parses (advanced +star)
::     - +stag: tag result with term (useful for unions)
::     - Custom accumulation patterns
::     - Building typed results
::
:: [ ] Example 22: Efficient Dispatch (+stew, +perk)
::     - +stew: switch on first character (fast dispatch)
::     - +perk: match from list of strings (enum-like)
::     - Performance considerations
::     - When to use vs +pose
::
:: [ ] Example 23: Symbol/Identifier Parsing
::     - +sym: standard Hoon symbol (lowercase + hyphens)
::     - +mixed-case-symbol: identifiers with mixed case
::     - Building custom identifier rules
::     - Keyword handling
::
:: [ ] Example 24: Full Grammar (arithmetic expressions)
::     - Expression parsing with precedence
::     - Factor/term/expression hierarchy
::     - Handling operators and parentheses
::     - Left-recursion elimination
::
:: [ ] Example 25: Monadic Parser Builders (lib/html-utils.hoon)
::     - Study actual examples: classes, styles, doqseg, soqseg parsers
::     - Uses =, monadic door for bind/easy/next/near/done helpers
::     - Learn pattern: ;<  result  bind  parser-expr
::     - Key helpers: +next (consume char), +near (peek), +done (check complete)
::     - Stateful parsing: accumulate results while iterating with $
::     - Comparison: applicative ;~ style vs monadic ;<  style
::     - Example: parsing CSS class lists and style properties
::
|%
::  Example 1: Single Character Parsing
::
::  The foundation of all parsing: matching individual characters.
::
::  +just creates a $rule that matches one specific character. It succeeds
::  if the next character in the input matches the given character, fails
::  otherwise. On success, it returns the matched character and advances
::  the parse position by one.
::
::  +next is a $rule that matches any single character. It always succeeds
::  unless the input is empty. It returns the character and advances position.
::
::  TESTING:
::    Raw parser output (showing $edge structure):
::      (next [[1 1] "abc"])
::      Returns: [p=[p=1 q=2] q=[~ [p='a' q=[p=[p=1 q=2] q="bc"]]]]
::      Interpretation: position advanced to [1 2], matched 'a', "bc" remains
::
::    Using +scan (hides $nail/$edge details):
::      (scan "a" (just 'a'))
::      Returns: 'a'
::      Interpretation: successfully parsed 'a', input fully consumed
::
::    Failure case:
::      (scan "a" (just 'b'))
::      Crashes with syntax error - 'a' doesn't match 'b'
::
++  ex1
  |%
  ::  Matches only the letter 'a'
  ::  Returns: @tD ('a')
  ::  Fails if: input is empty or first character is not 'a'
  ++  parse-a  (just 'a')
  ::
  ::  Matches only the letter 'w'
  ::  Returns: @tD ('w')
  ::  Fails if: input is empty or first character is not 'w'
  ++  parse-w  (just 'w')
  --
::
::  Example 2: Sequencing with +plug
::
::  Building complex parsers by composing simple ones in sequence.
::
::  The ;~ rune applies a combinator to a list of parsers. With +plug,
::  it runs each parser in order on the remaining input, collecting all
::  results into a cell (tuple). If any parser fails, the whole sequence fails.
::
::  MECHANICS:
::    ;~(plug (just 'a') (just 'b'))
::    - Runs (just 'a') on input
::    - If successful, runs (just 'b') on remainder
::    - Returns ['a' 'b'] if both succeed
::    - Fails if either parser fails
::
::  TESTING:
::    (scan "ab" ;~(plug (just 'a') (just 'b')))
::    Returns: ['a' 'b']
::
::    (scan "wpkh" ;~(plug (just 'w') (just 'p') (just 'k') (just 'h')))
::    Returns: ['w' 'p' 'k' 'h']
::
::  USE CASES:
::    - Parsing fixed-format strings (e.g., "wpkh", "http://")
::    - Matching keywords or identifiers
::    - Any sequence where order and all parts matter
::
++  ex2
  |%
  ::  Parses the exact string "wpkh" (witness public key hash script type)
  ::  Returns: ['w' 'p' 'k' 'h']
  ::  Fails if: any character doesn't match or input is shorter than 4 chars
  ++  parse-wpkh
    ;~  plug
      (just 'w')
      (just 'p')
      (just 'k')
      (just 'h')
    ==
  --
::
::  Example 3: Choice with +pose
::
::  Handling alternatives: trying multiple parsers until one succeeds.
::
::  The +pose combinator tries each parser in sequence. It returns the result
::  of the first parser that succeeds. If all parsers fail, +pose fails.
::  This is how you express "match A OR B OR C" in parser combinators.
::
::  MECHANICS:
::    ;~(pose (just 'a') (just 'b') (just 'c'))
::    - Tries (just 'a')
::    - If that fails, tries (just 'b')
::    - If that fails, tries (just 'c')
::    - Returns first successful match
::    - Fails only if all options fail
::
::  TESTING:
::    (scan "a" ;~(pose (just 'a') (just 'b')))
::    Returns: 'a'  (first option succeeded)
::
::    (scan "b" ;~(pose (just 'a') (just 'b')))
::    Returns: 'b'  (first option failed, second succeeded)
::
::    (scan "'" ;~(pose (just '\'') (just '\\')))
::    Returns: '\''  (matched single quote)
::
::  USE CASES:
::    - Parsing different variants (e.g., 'wpkh' or 'wsh' or 'tr')
::    - Character classes (digit OR letter)
::    - Escape sequences (match special characters that need escaping)
::    - Fallback behavior (try specific match, fall back to generic)
::
++  ex3
  |%
  ::  Parses either a single quote or a backslash
  ::  Useful for parsing escape sequences in strings
  ::  Returns: @tD ('\'' or '\\')
  ::  Fails if: input is empty or starts with neither character
  ++  parse-quote-or-slash
    ;~  pose
      (just '\'')
      (just '\\')
    ==
  --
::
::  Example 4: Repetition with +star
::
::  Parsing variable-length sequences by repeating a rule.
::
::  +star applies a $rule repeatedly (zero or more times) until it fails.
::  It collects all successful parses into a list. Since it accepts zero
::  matches, +star never fails - it returns an empty list if the first
::  application of the rule fails.
::
::  MECHANICS:
::    (star (just 'a'))
::    - Tries (just 'a') on input
::    - If successful, tries again on remainder
::    - Continues until (just 'a') fails
::    - Returns list of all matched characters
::    - Returns ~ (empty list) if first try fails
::
::  TESTING:
::    (scan "aaa" (star (just 'a')))
::    Returns: "aaa"  (list of three 'a' characters)
::
::    (scan "abc" (star (shim 'a' 'z')))
::    Returns: "abc"  (list of three lowercase letters)
::
::    (scan "" (star (just 'a')))
::    Returns: ""  (empty list - star accepts zero matches)
::
::  RELATED RULES:
::    +plus - one or more matches (fails if zero)
::    +stun - exact range of matches [min max]
::
::  USE CASES:
::    - Variable-length strings (names, identifiers)
::    - Whitespace sequences
::    - Repeated patterns (multiple digits, multiple words)
::    - Greedy matching (consume as much as possible)
::
++  ex4
  |%
  ::  Parses a sequence of lowercase letters
::  +shim creates a range matcher: (shim 'a' 'z') matches any char from a-z
  ::  Returns: (list @tD) - tape of matched letters
  ::  Accepts: zero or more letters (returns empty list if no matches)
  ++  parse-letters
    (star (shim 'a' 'z'))
  --
::
::  Example 5: Transformation with +cook
::
::  Transforming parse results: converting one type to another.
::
::  +cook modifies a $rule by applying a gate to its result. The gate takes
::  the successful parse result and transforms it into a different value/type.
::  This is how you convert raw parse output into the data structures you
::  actually need.
::
::  SIGNATURE:
::    +cook: (gate $rule) -> $rule
::    Takes a transformation gate and a parser, returns modified parser
::
::  MECHANICS:
::    (cook |=(a=tape (crip a)) (star (shim 'a' 'z')))
::    - (star (shim 'a' 'z')) parses lowercase letters -> returns tape
::    - Gate |=(a=tape (crip a)) converts tape to cord
::    - Final result is cord, not tape
::
::  TESTING:
::    (scan "abc" (cook |=(a=tape (crip a)) (star (shim 'a' 'z'))))
::    Returns: 'abc'  (cord, not tape)
::
::    (scan "123" (cook |=(a=tape (lent a)) (star (shim '0' '9'))))
::    Returns: 3  (length of parsed digits)
::
::  USE CASES:
::    - Type conversion (tape -> cord, list -> set, etc.)
::    - Semantic transformation (string of digits -> @ud number)
::    - Structure building (parse fields -> construct record)
::    - Data validation (parse then verify constraints)
::
++  ex5
  |%
  ::  Parses lowercase letters and converts result from tape to cord
  ::  +crip is the standard library function for tape-to-cord conversion
  ::  Returns: @t (cord) instead of tape
  ::  Useful when: you need atom representation for faster manipulation
  ++  parse-as-cord
    (cook |=(a=tape (crip a)) (star (shim 'a' 'z')))
  --
::
::  Example 6: Parsing hexadecimal
::
::  Parsing numbers in base-16: building from character ranges and using stdlib.
::
::  Hexadecimal digits are 0-9, a-f, and A-F. This example demonstrates:
::  1. Building a hex parser from first principles (+pose + +shim)
::  2. Using +stun to parse exact lengths
::  3. Combining +cook with stdlib +hex for semantic transformation
::  4. When to build custom vs. use stdlib functions
::
::  HEXADECIMAL CONTEXT:
::    - Base-16 number system
::    - Digits: 0-9 (values 0-9), a-f/A-F (values 10-15)
::    - Commonly used for: cryptographic hashes, addresses, fingerprints
::    - In Hoon: @ux aura for hex atoms (e.g., 0xd34d.b33f)
::
::  TESTING:
::    Single digit:
::      (scan "a" ;~(pose (shim '0' '9') (shim 'a' 'f') (shim 'A' 'F')))
::      Returns: 'a'
::
::    Multiple digits to tape:
::      (scan "d34db33f" (star parse-hex-digit:ex6:pt))
::      Returns: "d34db33f"  (tape of characters)
::
::    Convert to @ux:
::      (rash 'd34db33f' hex)
::      Returns: 0xd34d.b33f  (@ux atom)
::
::  COMPOSITION PATTERNS:
::    1. +star for variable length: (star parse-hex-digit)
::    2. +stun for exact length: (stun [8 8] parse-hex-digit)
::    3. +cook for conversion: (cook crip ...) or (cook hex-to-num ...)
::
++  ex6
  |%
  ::  Parses a single hexadecimal digit (0-9, a-f, A-F)
  ::  Uses +pose to try each character range in sequence
  ::  Returns: @tD (the matched character)
  ::  Case-insensitive: accepts both 'a' and 'A'
  ++  parse-hex-digit
    ;~  pose
      (shim '0' '9')  :: Digits 0-9
      (shim 'a' 'f')  :: Lowercase a-f
      (shim 'A' 'F')  :: Uppercase A-F
    ==
  ::
  ::  Parses any number of hex digits as a tape
  ::  Returns: (list @tD) - tape of hex characters
  ::  Accepts: zero or more hex digits
  ::  Use when: you need the raw characters, not the numeric value
  ++  parse-hex-tape
    (star parse-hex-digit)
  ::
  ::  Parses hex digits and converts to cord
  ::  Returns: @t (cord of hex characters)
  ::  Useful for: storing hex strings as atoms
  ++  parse-hex-cord
    (cook crip parse-hex-tape)
  ::
  ::  Parses exactly 8 hex digits and converts to @ux value
  ::  Used for BIP-32 fingerprints (32-bit values shown in 8 hex digits)
  ::  +stun enforces exact length: (stun [8 8] ...) means "between 8 and 8"
  ::  Returns: @ux (hexadecimal atom, e.g., 0xd34d.b33f)
  ::  Fails if: fewer or more than 8 hex digits
  ++  parse-fingerprint
    %+  cook
      |=(a=tape `@ux`(rash (crip a) hex))
    (stun [8 8] parse-hex-digit)
  ::
  ::  Parses hex string using standard library +hex parser
  ::  Demonstrates stdlib approach vs. custom building
  ::  Returns: @ux (hexadecimal atom)
  ::  Note: +rash converts cord to tape internally and parses
  ++  parse-with-hex
    |=  input=tape
    ^-  @ux
    (rash (crip input) hex)
  --
::
::  Example 7: Parsing delimited content with +ifix
::
::  Extracting content from within delimiters while discarding the delimiters.
::
::  +ifix takes a pair of $rules (for opening and closing delimiters) and a
::  content $rule. It parses: delimiter-open + content + delimiter-close,
::  but returns ONLY the content. The delimiters are matched and consumed but
::  not included in the result.
::
::  SIGNATURE:
::    +ifix: [open=$rule close=$rule] content=$rule -> $rule
::    Returns $rule that matches open+content+close, returns only content
::
::  MECHANICS:
::    (ifix [pal par] (jest '42'))
::    - Parses '(' with pal (short for (just '('))
::    - Parses '42' with (jest '42')
::    - Parses ')' with par (short for (just ')'))
::    - Returns: '42' (the delimiters are discarded)
::
::  TESTING:
::    (scan "(42)" (ifix [pal par] (jest '42')))
::    Returns: '42'
::
::    (scan "[fingerprint]" (ifix [sel ser] (jest 'fingerprint')))
::    Returns: 'fingerprint'
::
::    (scan "{wrapped}" (ifix [kel ker] (star (shim 'a' 'z'))))
::    Returns: "wrapped"
::
::  COMMON DELIMITERS (stdlib shortcuts):
::    [pal par] - parentheses ( )
::    [sel ser] - square brackets [ ]
::    [kel ker] - curly braces { }
::    [gal gar] - angle brackets < >
::    [doq doq] - double quotes " "
::
::  USE CASES:
::    - Parsing quoted strings (discard quotes, keep content)
::    - Extracting parenthesized expressions
::    - Parsing bracketed notation [fingerprint/path/segments]
::    - Removing wrapper syntax from structured data
::
++  ex7
  |%
  ::  Parses content within parentheses, discards the parens
  ::  Example: "(hello)" -> 'hello'
  ::  Returns: @t (the content as cord)
  ::  Fails if: delimiters missing or mismatched
  ++  parse-parenthesized
    %+  ifix  [pal par]
    (cook crip (star (shim 'a' 'z')))
  ::
  ::  Parses 8 hex digits within square brackets, converts to @ux
  ::  Example: "[d34db33f]" -> 0xd34d.b33f
  ::  Useful for: BIP-329 origin fingerprints like [d34db33f/84'/0'/0']
  ::  Returns: @ux (hexadecimal atom)
  ::  Fails if: not exactly 8 hex digits or missing/mismatched brackets
  ++  parse-bracketed-fingerprint
    %+  ifix  [sel ser]
    %+  cook
      |=(a=tape `@ux`(rash (crip a) hex))
    (stun [8 8] ;~(pose (shim '0' '9') (shim 'a' 'f') (shim 'A' 'F')))
  ::
  ::  Parses double-quoted string, discards quotes
  ::  Example: "\"hello\"" -> 'hello'
  ::  Returns: @t (cord of content)
  ::  Note: Does not handle escape sequences (simplified for demonstration)
  ::  Fails if: missing or mismatched quotes
  ++  parse-quoted
    %+  ifix  [doq doq]
    (cook crip (star ;~(less doq next)))
  --
::
::  Example 8: Constant replacement with +cold
::
::  Replacing parse results with constant values for semantic interpretation.
::
::  +cold is the opposite of +cook. While +cook transforms a parse result
::  through computation, +cold simply discards the parse result and replaces
::  it with a constant value. This is essential for converting syntax into
::  semantics: the string "true" becomes %.y, "wpkh" becomes %wpkh, etc.
::
::  SIGNATURE:
::    +cold: constant-value $rule -> $rule
::    Returns $rule that parses like the input rule but returns constant
::
::  COMPARISON:
::    +cook - transforms result via gate:  (cook |=(a ...) rule)
::    +cold - replaces result with constant: (cold %value rule)
::
::  MECHANICS:
::    (cold %.y (jest 'true'))
::    - (jest 'true') parses "true" and would normally return 'true'
::    - +cold discards that 'true' and returns %.y instead
::    - Result: parsing "true" produces %.y (boolean true)
::
::  TESTING:
::    (scan "yes" (cold %.y (jest 'yes')))
::    Returns: %.y
::
::    (scan "wpkh" ;~(pose (cold %wpkh (jest 'wpkh')) (cold %wsh (jest 'wsh'))))
::    Returns: %wpkh
::
::  USE CASES:
::    - Keywords to constants ("true" -> %.y, "null" -> ~)
::    - String literals to type tags ("wpkh" -> %wpkh)
::    - Command parsing ("quit" -> %quit, "help" -> %help)
::    - Enum-like parsing (fixed set of strings -> term values)
::    - Any situation where syntax doesn't matter, only which option matched
::
++  ex8
  |%
  ::  Parses boolean literals to actual booleans
  ::  "true" -> %.y, "false" -> %.n
  ::  Returns: ? (loobean)
  ::  Fails if: input is neither "true" nor "false"
  ++  parse-bool
    ;~  pose
      (cold %.y (jest 'true'))
      (cold %.n (jest 'false'))
    ==
  ::
  ::  Parses Bitcoin script type identifiers to terms
  ::  Converts string representation to semantic type tag
  ::  Returns: ?(%wpkh %wsh %tr %pkh %sh)
  ::  Useful for: BIP-329 origin parsing, wallet descriptor parsing
  ++  parse-script-type
    ;~  pose
      (cold %wpkh (jest 'wpkh'))  :: Witness public key hash (SegWit)
      (cold %wsh (jest 'wsh'))    :: Witness script hash (SegWit script)
      (cold %tr (jest 'tr'))      :: Taproot
      (cold %pkh (jest 'pkh'))    :: Legacy public key hash
      (cold %sh (jest 'sh'))      :: Legacy script hash
    ==
  ::
  ::  Parses hardened derivation marker to boolean flag
  ::  In BIP-32 paths, ' or h marks hardened derivation
  ::  "84'" -> %.y, "84h" -> %.y, "84" -> %.n
  ::  Returns: ? (loobean indicating hardened status)
  ::  Useful for: parsing derivation path segments
  ++  parse-hardened-marker
    ;~  pose
      (cold %.y (just '\''))
      (cold %.y (just 'h'))
      (easy %.n)  :: No marker means not hardened
    ==
  --
::
::  Example 9: Parsing decimal numbers with +dem
::
::  Converting digit strings to numeric values using standard library parsers.
::
::  +dem is the standard library parser for decimal (base-10) numbers. It parses
::  one or more digits and converts them to a @ud (unsigned decimal). This is
::  the foundation for parsing any numeric input in Hoon.
::
::  NUMBER PARSERS IN STDLIB:
::    +dem - decimal (@ud)
::    +hex - hexadecimal (@ux)
::    +bin - binary (@ub)
::    +viz - base-32 (@uv)
::
::  MECHANICS:
::    dem
::    - Internally uses (star (shim '0' '9')) to match digit characters
::    - Converts the digit string to numeric value
::    - Returns @ud (unsigned decimal integer)
::    - Fails if no digits present
::
::  TESTING:
::    (scan "42" dem)
::    Returns: 42
::
::    (scan "2147483647" dem)
::    Returns: 2.147.483.647
::
::  COMBINING WITH OTHER PARSERS:
::    Numbers often appear with markers, separators, or in structured formats.
::    Combine +dem with other parsers to handle complex numeric inputs:
::    - (ifix [pal par] dem) - number in parentheses "(42)"
::    - ;~(plug dem (just '%')) - percentage "42%"
::    - ;~((glue dot) dem dem) - version "1.2"
::
::  USE CASES:
::    - Parsing numeric literals in data formats
::    - BIP-32 derivation path indices (84, 0, 1, etc.)
::    - Amounts, counts, indices
::    - Configuration values
::
++  ex9
  |%
  ::  Parses a simple decimal number
  ::  Returns: @ud (unsigned decimal)
  ::  Fails if: input contains no digits
  ++  parse-number
    dem
  ::
  ::  Parses a BIP-32 path segment: number + optional hardened marker
::  Examples: "84'" -> [%.y 84], "0" -> [%.n 0], "1h" -> [%.y 1]
  ::  Returns: [hardened=? index=@ud]
  ::  Useful for: parsing derivation paths like m/84'/0'/0'
  ++  parse-path-segment
    %+  cook
      |=  [n=@ud h=?]
      [h n]
    ;~  plug
      dem
      ;~  pose
        (cold %.y (just '\''))
        (cold %.y (just 'h'))
        (easy %.n)
      ==
    ==
  ::
  ::  Parses a percentage value (number followed by %)
  ::  Examples: "75%" -> 75, "100%" -> 100
  ::  Returns: @ud (the numeric value, not the percentage as decimal)
  ::  Fails if: no digits or missing % symbol
  ++  parse-percentage
    %+  cook  head
    ;~(plug dem (just '%'))
  ::
  ::  Parses a version string (major.minor format)
  ::  Examples: "1.2" -> [1 2], "10.15" -> [10 15]
  ::  Returns: [@ud @ud] (major and minor version numbers)
  ::  Fails if: missing dot or either number
  ++  parse-version
    ;~((glue dot) dem dem)
  --
::
::  Example 10: Delimited sequences with +slug and +glue
::
::  Parsing separated values: choosing between folding and collecting.
::
::  Both +slug and +glue handle delimiter-separated values, but serve different
::  purposes:
::  - +slug: folds/reduces values with a binary gate (like reduce/fold in other languages)
::  - +glue: returns values as a tuple (fixed number of items)
::
::  SIGNATURES:
::    +slug: gate delimiter rule -> rule (folds all parsed values)
::    +glue: delimiter -> combinator (for use with ;~)
::
::  +SLUG MECHANICS:
::    ((slug add) com dem)
::    - Parses numbers separated by commas
::    - Folds them together using +add
::    - "1,2,3" -> 6 (1+2+3)
::
::  +GLUE MECHANICS:
::    ;~((glue fas) dem dem dem)
::    - Parses exactly 3 numbers separated by /
::    - Returns as tuple: [n1 n2 n3]
::    - "84/0/1" -> [84 0 1]
::
::  WHEN TO USE:
::    +slug - When you want to combine/reduce values (sum, product, concatenate)
::    +glue - When you want to keep values separate in a tuple (fixed structure)
::
::  TESTING:
::    (scan "1,2,3" ((slug add) com dem))
::    Returns: 6
::
::    (scan "84/0/1" ;~((glue fas) dem dem dem))
::    Returns: [84 0 1]
::
++  ex10
  |%
  ::  Computes sum of comma-separated numbers using +slug
  ::  Example: "1,2,3,4" -> 10
  ::  Returns: @ud (sum of all numbers)
  ::  Fails if: invalid format or no numbers
  ++  parse-sum
    ((slug add) com dem)
  ::
  ::  Computes product of slash-separated numbers using +slug
  ::  Example: "2/3/4" -> 24
  ::  Returns: @ud (product of all numbers)
  ::  Useful for: demonstrating different folding operations
  ++  parse-product
    ((slug mul) fas dem)
  ::
  ::  Parses 3-segment BIP-32 path (account level) using +glue
  ::  Example: "84/0/0" -> [[%.n 84] [%.n 0] [%.n 0]]
  ::  Returns: [seg seg seg] where seg is [hardened=? index=@ud]
  ::  Fixed-length: always expects exactly 3 segments
  ++  parse-account-path
    %+  cook
      |=  [a=@ b=@ c=@]
      [[%.n a] [%.n b] [%.n c]]
    ;~((glue fas) dem dem dem)
  --
::
::  Example 11: Recursive parsing with +knee
::
::  Building parsers that reference themselves: handling nested structures.
::
::  Recursive parsers are needed when parsing nested or self-similar structures
::  like nested parentheses, JSON objects, or lists. In Hoon, naive recursion
::  in parsers fails at compile time. +knee solves this by providing a
::  controlled recursion mechanism.
::
::  THE PROBLEM:
::    |-(;~(plug prn $))  :: FAILS - can't find $ in recursive context
::
::  THE SOLUTION:
::    |-(;~(plug prn (knee *tape |.(^$))))  :: WORKS - +knee manages recursion
::
::  SIGNATURE:
::    +knee: default-value gate-returning-rule -> rule
::    - default-value: bunt of result type (e.g., *tape for tape result)
::    - gate: produces the recursive rule (use ^$ to recurse)
::
::  MECHANICS:
::    (knee *tape |.(^$))
::    - *tape is default value (empty tape)
::    - |.(^$) is gate that recursively calls the parser
::    - ^$ refers to the enclosing |-(trap/core), enabling recursion
::
::  TESTING:
::    Simple recursive parser that consumes all characters:
::      |-(;~(plug prn ;~(pose (knee *tape |.(^$)) (easy ~))))
::      (scan "abc" parser)
::      Returns: ['a' "bc"]  (parses first char, recurses for rest)
::
::  USE CASES:
::    - Nested structures (parentheses, brackets, braces)
::    - Tree-like data (JSON, XML, S-expressions)
::    - Variable-length lists
::    - Any self-referential grammar
::
++  ex11
  |%
  ::  Parses a simple comma-separated list recursively
  ::  Example: "a,b,c" -> "abc"
  ::  Returns: tape (all letters concatenated)
  ::  Demonstrates: basic +knee usage with recursion
  ++  parse-letter-list
    |^  scan-letters
    ++  scan-letters
      ;~  pose
        ;~  plug
          (shim 'a' 'z')
          ;~  pose
            (ifix [com com] (knee *tape |.(scan-letters)))
            (easy ~)
          ==
        ==
        (easy ~)
      ==
    --
  ::
  ::  Parses nested parentheses and counts depth
  ::  Example: "((()))" -> 3
  ::  Returns: @ud (maximum nesting depth)
  ::  Demonstrates: +knee for hierarchical structures
  ++  parse-paren-depth
    |^  depth-count
    ++  depth-count
      ;~  pose
        %+  cook
          |=(a=@ +(a))
        (ifix [pal par] (knee *@ |.(depth-count)))
        (easy 0)
      ==
    --
  --
::
::  Example 12: BIP-329 origin strings
::
::  Parsing complex real-world formats: combining all learned techniques.
::
::  BIP-329 origin strings describe the derivation path for a Bitcoin wallet:
::    Format: script-type([fingerprint/path'/segments'])
::    Example: "wpkh([d34db33f/84'/0'/0'])"
::
::  This parser demonstrates composition of all previous concepts:
::  - Script type parsing (+cold, +pose from ex8)
::  - Bracketed content (+ifix from ex7)
::  - Hex fingerprint (+stun, hex from ex6)
::  - Path segments (+dem, hardened markers from ex9)
::  - Slash-delimited paths (+glue from ex10)
::  - Optional escaping (backslash handling from ex3)
::
::  STRUCTURE BREAKDOWN:
::    wpkh([d34db33f/84'/0'/0'])
::    ^^^^  ^^^^^^^^ ^^^^^^^^^
::     |        |         |
::     |        |         +-- Path segments (derivation indices)
::     |        +------------ Fingerprint (8 hex digits)
::     +--------------------- Script type (output descriptor type)
::
::  TESTING:
::    (scan "wpkh([d34db33f/84'/0'/0'])" parse-origin:ex12:pt)
::    Returns: [%wpkh 0xd34d.b33f [[%.y 84] [%.y 0] [%.y 0]]]
::
++  ex12
  |%
  ::  Parses a single hardened path segment: digits followed by apostrophe
  ::  Example: "84'" → 84
  ::  Returns: @ud (the numeric value)
  ::  Demonstrates: combining +dem with +sfix to parse and discard suffix
  ++  parse-hardened-segment
    ;~(sfix dem (just '\''))

  ::  Parses BIP-329 origin string to structured data
  ::  Returns: [script-type=?(%wpkh %wsh %tr) fingerprint=@ux path=(list [? @ud])]
  ::  This is the culmination: everything we've learned comes together
  ++  parse-origin
    %+  cook
      |=  [st=?(%wpkh %wsh %tr %pkh %sh) fp=@ux segs=(list @ud)]
      [st fp (turn segs |=(n=@ud [%.y n]))]
    ;~  plug
      ::  Parse script type (ex8: +cold for keyword→constant)
      ;~  pose
        (cold %wpkh (jest 'wpkh'))
        (cold %wsh (jest 'wsh'))
        (cold %tr (jest 'tr'))
        (cold %pkh (jest 'pkh'))
        (cold %sh (jest 'sh'))
      ==
      ::  Parse bracketed fingerprint and path (ex7: +ifix)
      %+  ifix  [pal par]
      %+  ifix  [sel ser]
      ;~  plug
        ::  Parse 8-digit hex fingerprint (ex6: +stun for exact length)
        %+  cook
          |=(a=tape `@ux`(rash (crip a) hex))
        (stun [8 8] ;~(pose (shim '0' '9') (shim 'a' 'f') (shim 'A' 'F')))
        ::  Parse /seg'/seg'/seg' format (ex9 + ex10: +more for delimiter)
        ::  Format: /84'/0'/0' → [84 0 0]
        ::  Uses +more: parses one segment, then zero or more /segment pairs
        ;~(pfix fas (more fas parse-hardened-segment))
      ==
    ==
  --
::
::  Example 13: Iteration Patterns (+plus, +most, +more)
::
::  Advanced repetition: understanding the full family of iteration combinators.
::
::  While +star (from ex4) parses zero or more matches, other iteration
::  combinators provide different semantics for common parsing patterns:
::
::  +plus - one or more (fails if zero matches)
::  +most - one or more with delimiter between items
::  +more - zero or more with delimiter between items
::
::  COMPARISON TABLE:
::    +star - 0+ matches, no delimiter → returns (list)
::    +plus - 1+ matches, no delimiter → returns [first rest=(list)]
::    +more - 0+ matches, with delimiter → returns (list)
::    +most - 1+ matches, with delimiter → returns [first rest=(list)]
::
::  SIGNATURES:
::    +star: rule -> rule  (returns list of results)
::    +plus: rule -> rule  (returns [first rest])
::    +most: delimiter rule -> rule  (returns [first rest])
::    +more: delimiter rule -> rule  (returns list)
::
::  WHY THE DIFFERENCE?
::    +plus and +most guarantee at least one match, so they return
::    a cell [first rest] rather than a list. This prevents empty results.
::    +star and +more allow zero matches, so they return lists (which can be empty).
::
::  MECHANICS OF +most:
::    (most com (shim 'a' 'z'))
::    - Parses first letter (must succeed)
::    - Then parses: comma + letter, repeatedly
::    - "a,b,c" → ['a' "bc"]  (first letter + rest)
::    - Fails on empty input or input starting with comma
::
::  MECHANICS OF +more:
::    (more com (shim 'a' 'z'))
::    - Tries to parse: letter (comma letter)*
::    - "a,b,c" → "abc"  (list of letters)
::    - "" → ""  (empty list - succeeds on empty input)
::    - Differs from +most by accepting zero matches
::
::  TESTING:
::    +plus (at least one letter):
::      (scan "abc" (plus (shim 'a' 'z')))
::      Returns: ['a' "bc"]
::
::    +most (at least one number, comma-separated):
::      (scan "1,2,3" (most com dem))
::      Returns: [1 ~[2 3]]
::
::    +more (zero or more numbers, comma-separated):
::      (scan "" (more com dem))
::      Returns: ~  (empty list)
::
::  USE CASES:
::    +plus - Non-empty sequences (at least one digit, one letter, etc.)
::    +most - CSV parsing, function arguments (must have at least one)
::    +more - Optional lists (can be empty), flexible input formats
::
++  ex13
  |%
  ::  Parses one or more lowercase letters (non-empty sequence)
::  Unlike +star which accepts empty input, +plus requires at least one match
  ::  Returns: [first=@tD rest=tape]
  ::  Fails if: input is empty or doesn't start with a letter
  ++  parse-letters-nonempty
    (plus (shim 'a' 'z'))
  ::
  ::  Parses one or more digits with +plus
  ::  Example: "123" -> ['1' "23"]
  ::  Returns: [first=@tD rest=tape]
  ::  Useful for: ensuring non-empty numeric input
  ++  parse-digits-nonempty
    (plus (shim '0' '9'))
  ::
  ::  Parses comma-separated letters, requires at least one
  ::  Example: "a,b,c" -> ['a' "bc"]
  ::  Returns: [first=@tD rest=tape]
  ::  Fails if: empty input or no letters before first comma
  ++  parse-letter-list-nonempty
    (most com (shim 'a' 'z'))
  ::
  ::  Parses comma-separated numbers, requires at least one
  ::  Example: "1,2,3" -> [1 ~[2 3]]
  ::  Returns: [first=@ud rest=(list @ud)]
  ::  Useful for: function arguments, required parameter lists
  ++  parse-number-list-nonempty
    (most com dem)
  ::
  ::  Parses comma-separated letters, accepts empty list
  ::  Example: "" -> ~, "a,b" -> "ab"
  ::  Returns: (list @tD)
  ::  Difference from +most: accepts empty input (returns ~)
  ++  parse-letter-list-optional
    (more com (shim 'a' 'z'))
  ::
  ::  Parses semicolon-separated numbers, accepts empty list
  ::  Example: "" -> ~, "1;2;3" -> ~[1 2 3]
  ::  Returns: (list @ud)
  ::  Useful for: optional configuration values, flexible input
  ++  parse-number-list-optional
    (more mic dem)
  --
::
::  Example 14: Prefix/Suffix Combinators (+pfix, +sfix)
::
::  Selective parsing: keeping only part of what you match.
::
::  Three related combinators for handling multi-part patterns:
::    +pfix - parse two things, discard first (prefix), return second
::    +sfix - parse two things, discard second (suffix), return first
::    +ifix - parse three things, discard first and last, return middle
::
::  SIGNATURES:
::    +pfix: rule rule -> rule  (prefix rule, value rule)
::    +sfix: rule rule -> rule  (value rule, suffix rule)
::    +ifix: [rule rule] rule -> rule  ([prefix suffix] value)
::
::  MECHANICS:
::    (pfix (just '$') dem)
::    - Parses '$' character (required)
::    - Then parses a number
::    - Discards the '$', returns only the number
::    - "$42" → 42
::
::    (sfix dem (just '%'))
::    - Parses a number
::    - Then parses '%' character (required)
::    - Discards the '%', returns only the number
::    - "75%" → 75
::
::    (ifix [sel ser] (star (shim 'a' 'z')))
::    - Parses '[', then letters, then ']'
::    - Discards both brackets, returns only the letters
::    - "[hello]" → "hello"
::
::  COMPARISON:
::    All three require the discarded parts to be present (they're not optional).
::    They differ only in what they discard:
::      +pfix - discards prefix only
::      +sfix - discards suffix only
::      +ifix - discards both prefix and suffix
::
::  USE CASES:
::    +pfix - Currency symbols ($100), hash prefixes (#tag), type markers (@t)
::    +sfix - Units (100kg), markers (required!), path terminators (dir/)
::    +ifix - Delimited content ("string", [list], {set})
::
::  TESTING:
::    (scan "$42" (pfix (just '$') dem))
::    → 42
::
::    (scan "75%" (sfix dem (just '%')))
::    → 75
::
::    (scan "[hello]" (ifix [sel ser] (star (shim 'a' 'z'))))
::    → "hello"
::
++  ex14
  |%
  ::  Parse a dollar amount, discarding the '$' prefix
  ::  Example: "$100" → 100
  ::  Returns: @ud (just the number)
  ::  Fails if: no '$' prefix or invalid number
  ++  parse-dollar-amount
    ;~(pfix (just '$') dem)
  ::
  ::  Parse a percentage, discarding the '%' suffix
  ::  Example: "75%" → 75
  ::  Returns: @ud (just the number)
  ::  Fails if: no '%' suffix or invalid number
  ++  parse-percentage-pfix
    ;~(sfix dem (just '%'))
  ::
  ::  Parse a hex color code, discarding the '#' prefix
  ::  Example: "#ff00ff" → 'ff00ff'
  ::  Returns: @t (hex string without the hash)
  ::  Useful for: CSS colors, HTML attributes
  ++  parse-hex-color
    %+  cook  crip
    ;~(pfix hax (star ;~(pose (shim '0' '9') (shim 'a' 'f') (shim 'A' 'F'))))
  ::
  ::  Parse a file size with unit, discarding the unit suffix
  ::  Example: "100MB" → 100, "512KB" → 512
  ::  Returns: @ud (just the number)
  ::  Demonstrates: +sfix with choice of suffixes
  ++  parse-file-size
    ;~  sfix  dem
      ;~  pose
        (jest 'KB')
        (jest 'MB')
        (jest 'GB')
      ==
    ==
  ::
  ::  Parse a required field marker, discarding the '!' suffix
  ::  Example: "username!" → 'username'
  ::  Returns: @t (field name without marker)
  ::  Useful for: validation schemas, form definitions
  ++  parse-required-field
    %+  cook  crip
    ;~(sfix (star (shim 'a' 'z')) (just '!'))
  ::
  ::  Parse a bracketed identifier, discarding brackets
  ::  Example: "[variable]" → 'variable'
  ::  Returns: @t
  ::  Demonstrates: +ifix (we already used in ex7, but comparing here)
  ++  parse-bracketed-id
    %+  cook  crip
    %+  ifix  [sel ser]
    (star (shim 'a' 'z'))
  ::
  ::  Parse a path segment with trailing slash, discard slash
  ::  Example: "home/" → 'home'
  ::  Returns: @t (directory name)
  ::  Useful for: URL parsing, filesystem paths
  ++  parse-dir-name
    %+  cook  crip
    ;~(sfix (star (shim 'a' 'z')) fas)
  ::
  ::  Parse a positive number with '+' prefix (prefix required!)
  ::  Example: "+42" → 42
  ::  Returns: @ud
  ::  Contrast with ex20 where we'll see optional patterns
  ++  parse-positive-number
    ;~(pfix (just '+') dem)
  --
::
::  Example 15: Advanced Number Parsing (+bass, +bin)
::
::  Base conversion and advanced numeric parsing.
::
::  +bass - converts a list of digits to a number in a given base
::  +bin  - parses binary digits
::  +dem  - parses decimal digits (we've used this extensively)
::  +hex  - parses hexadecimal digits
::
::  SIGNATURES:
::    +bass: base=@ud -> rule  (takes base, returns parser for that base)
::    +bin: rule  (parses binary digits)
::
::  MECHANICS OF +bass:
::    (bass 16 (star (shim '0' '9')))
::    - Parses digits 0-9 using (star (shim '0' '9'))
::    - Interprets them as base-16 (hexadecimal)
::    - "ff" → 255 (even though it only parsed '0'-'9' digits!)
::
::    The magic: +bass wraps a parser and converts its list output to a number.
::    Input: list of character codes (like ~['1' '0' '1'])
::    Output: number in specified base (101 in base 2 = 5 in decimal)
::
::  COMMON BASES:
::    Base 2  (binary)      - 0b1010 = 10
::    Base 8  (octal)       - 0o12 = 10
::    Base 10 (decimal)     - 10 = 10
::    Base 16 (hexadecimal) - 0xa = 10
::
::  TESTING:
::    Binary:
::      (scan "1010" ;~(pfix (jest '0b') (bass 2 (star (shim '0' '1')))))
::      → 10
::
::    Octal:
::      (scan "0o12" ;~(pfix (jest '0o') (bass 8 (star (shim '0' '7')))))
::      → 10
::
::    Hexadecimal:
::      (scan "0xff" ;~(pfix (jest '0x') (bass 16 (star ;~(pose (shim '0' '9') (shim 'a' 'f'))))))
::      → 255
::
::  USE CASES:
::    - Parsing Bitcoin addresses (base58)
::    - Parsing hexadecimal color codes
::    - Parsing binary literals in programming languages
::    - Parsing octal file permissions
::
++  ex15
  |%
  ::  IMPORTANT: +bass requires numeric digits (0-9), not ASCII characters ('0'-'9')
  ::  ASCII '0' has value 48, but +bass needs numeric 0
  ::  Solution: Use +cook to convert: (cook |=(a=@ (sub a '0')) (shim '0' '9'))
  ::  For hex: lowercase 'a' → (sub a 87), uppercase 'A' → (sub a 55)
  ::
  ::  Parse binary number with 0b prefix
  ::  Example: "0b1010" → 10
  ::  Returns: @ud
  ::  Technique: +bass with ASCII-to-numeric conversion via +cook
  ++  parse-binary
    ;~(pfix (jest '0b') (bass 2 (plus (cook |=(a=@ (sub a '0')) (shim '0' '1')))))
  ::
  ::  Parse octal number with 0o prefix
  ::  Example: "0o755" → 493
  ::  Returns: @ud
  ::  Common in Unix file permissions
  ::  Technique: (cook |=(a=@ (sub a '0')) (shim '0' '7'))
  ++  parse-octal
    ;~(pfix (jest '0o') (bass 8 (plus (cook |=(a=@ (sub a '0')) (shim '0' '7')))))
  ::
  ::  Parse hexadecimal number with 0x prefix (lowercase only)
  ::  Example: "0xff" → 255
  ::  Returns: @ud
  ::  Note: Only accepts lowercase a-f
  ::  Technique: 'a' → (sub 'a' 87) = 10, 'f' → (sub 'f' 87) = 15
  ++  parse-hex-lower
    ;~(pfix (jest '0x') (bass 16 (plus ;~(pose (cook |=(a=@ (sub a '0')) (shim '0' '9')) (cook |=(a=@ (sub a 87)) (shim 'a' 'f'))))))
  ::
  ::  Parse hexadecimal number with 0x prefix (case-insensitive)
  ::  Example: "0xFF" → 255, "0xff" → 255
  ::  Returns: @ud
  ::  Accepts both uppercase and lowercase
  ::  Technique: 'A' → (sub 'A' 55) = 10, 'F' → (sub 'F' 55) = 15
  ++  parse-hex-any
    ;~(pfix (jest '0x') (bass 16 (plus ;~(pose (cook |=(a=@ (sub a '0')) (shim '0' '9')) (cook |=(a=@ (sub a 87)) (shim 'a' 'f')) (cook |=(a=@ (sub a 55)) (shim 'A' 'F'))))))
  ::
  ::  Parse Bitcoin-style hex string (even number of hex digits, no prefix)
  ::  Example: "deadbeef" → 3.735.928.559
  ::  Returns: @ux (hex atom)
  ::  Common in Bitcoin for hashes, addresses, transactions
  ++  parse-bitcoin-hex
    (cook |=(a=@ `@ux`a) (bass 16 (plus ;~(pose (cook |=(a=@ (sub a '0')) (shim '0' '9')) (cook |=(a=@ (sub a 87)) (shim 'a' 'f')) (cook |=(a=@ (sub a 55)) (shim 'A' 'F'))))))
  ::
  ::  Parse a number in any specified base (2-36)
  ::  Example: (parse-in-base 7) applied to "123" → 66 (1*49 + 2*7 + 3*1)
  ::  Returns: gate that takes text and returns @ud
  ::  Demonstrates: +bass with variable base
  ++  parse-in-base
    |=  base=@ud
    ^-  $-(nail edge)
    ?>  &((gte base 2) (lte base 36))
    =/  max-digit=@t
      ?:  (lte base 10)
        (add '0' (dec base))
      '9'
    =/  max-letter=@t
      ?:  (lte base 10)
        '0'  ::  Won't be used
      (add 'a' (sub base 11))
    (bass base (star ;~(pose (shim '0' max-digit) (shim 'a' max-letter))))
  ::
  ::  Parse Unix file permission in octal
  ::  Example: "0755" → 493
  ::  Returns: @ud
  ::  Note: Leading 0 indicates octal (common Unix convention)
  ++  parse-unix-permission
    ;~(pfix (just '0') (bass 8 (plus (cook |=(a=@ (sub a '0')) (shim '0' '7')))))
  ::
  ::  Parse RGB color as three hex bytes
  ::  Example: "ff0080" → [255 0 128]
  ::  Returns: [r=@ud g=@ud b=@ud]
  ::  Demonstrates: combining +bass with structure
  ::  Note: Simplified version - parses exactly 6 hex digits as three 2-digit hex numbers
  ++  parse-rgb
    =/  hex-digit
      ;~  pose
        (cook |=(a=@ (sub a '0')) (shim '0' '9'))
        (cook |=(a=@ (sub a 87)) (shim 'a' 'f'))
        (cook |=(a=@ (sub a 55)) (shim 'A' 'F'))
      ==
    %+  cook
      |=  [r=@ g=@ b=@]
      [r g b]
    ;~  plug
      (bass 16 (stun [2 2] hex-digit))
      (bass 16 (stun [2 2] hex-digit))
      (bass 16 (stun [2 2] hex-digit))
    ==
  --
::
::  Example 16: Character Classes (Stdlib Idioms)
::
::  The Hoon stdlib provides many pre-built character class parsers in section 4i.
::  These are more idiomatic and efficient than manually building character ranges.
::
::  Common stdlib parsers:
::    - +alf: alphabetic (a-z, A-Z)
::    - +nud: numeric digit (0-9)
::    - +hex: hexadecimal (0-9, a-f, A-F)
::    - +low: lowercase (a-z)
::    - +hig: uppercase (A-Z)
::    - +alp: alphanumeric (combines +alf and +nud)
::    - +prn: printable ASCII
::    - +ace: space character
::
::  Use cases:
::    - Parsing identifiers and variable names
::    - Validating input formats
::    - Tokenizing source code
::    - Processing configuration files
::
++  ex16
  |%
  ::  Parse a simple identifier (letter followed by alphanumerics)
  ::  Example: "myVar123" → 'myVar123'
  ::  Returns: @t
  ::  Pattern: common in programming languages
  ++  parse-identifier
    (cook crip ;~(plug alf (star alp)))
  ::
  ::  Parse a lowercase identifier (snake_case style)
  ::  Example: "my_variable" → 'my_variable'
  ::  Returns: @t
  ::  Pattern: Python, Ruby convention
  ++  parse-snake-case
    (cook crip ;~(plug low (star ;~(pose low nud (just '_')))))
  ::
  ::  Parse an uppercase constant name
  ::  Example: "MAX_SIZE" → 'MAX_SIZE'
  ::  Returns: @t
  ::  Pattern: C, Java constants
  ++  parse-constant-name
    (cook crip ;~(plug hig (star ;~(pose hig nud (just '_')))))
  ::
  ::  Parse a hex color code without #
  ::  Example: "ff00aa" → 'ff00aa'
  ::  Returns: @t
  ::  Uses: character range for hex digits (0-9, a-f, A-F)
  ++  parse-hex-color-code
    (cook crip (stun [6 6] ;~(pose (shim '0' '9') (shim 'a' 'f') (shim 'A' 'F'))))
  ::
  ::  Parse alphanumeric string (no special chars)
  ::  Example: "Hello123" → 'Hello123'
  ::  Returns: @t
  ::  Uses: +alp (combines +alf and +nud)
  ++  parse-alphanumeric
    (cook crip (plus alp))
  ::
  ::  Parse a numeric string (one or more digits)
  ::  Example: "12345" → 12.345
  ::  Returns: @ud
  ::  Uses: +nud and +dem for conversion
  ++  parse-number-string
    dem
  ::
  ::  Parse camelCase identifier
  ::  Example: "myVariable" → 'myVariable'
  ::  Returns: @t
  ::  Pattern: JavaScript, Java convention
  ++  parse-camel-case
    %+  cook  crip
    ;~  plug
      low
      (star ;~(pose low hig nud))
    ==
  --
::
--

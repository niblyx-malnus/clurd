:: Text utilities library for demonstration
::
|%
:: Extract words from tape (split on spaces)
::
++  words
  |=  text=tape
  ^-  (list tape)
  ?~  text  ~
  =/  result=(list tape)  ~
  =/  current=tape  ~
  =/  remaining=tape  text
  |-  ^-  (list tape)
  ?~  remaining
    ?~  current  result
    (weld result ~[(flop current)])
  ?:  =(' ' i.remaining)
    ?~  current
      $(remaining t.remaining)
    $(remaining t.remaining, result (weld result ~[(flop current)]), current ~)
  $(remaining t.remaining, current [i.remaining current])
:: Count words in a tape
::
++  word-count
  |=  text=tape
  ^-  @ud
  (lent (words text))
:: Reverse a tape
::
++  reverse
  |=  text=tape
  ^-  tape
  (flop text)
:: Check if tape is palindrome
::
++  palindrome
  |=  text=tape
  ^-  ?
  =/  clean=tape  (turn text |=(c=@tD ?:((gth c 'Z') (sub c 32) c)))
  =(clean (flop clean))
:: Capitalize first letter of each word
::
++  title-case
  |=  text=tape
  ^-  tape
  =/  word-list=(list tape)  (words text)
  %-  zing
  %+  turn  word-list
  |=  word=tape
  ?~  word  " "
  =/  first=@tD  i.word
  =/  capitalized=@tD  ?:((gte first 'a') (sub first 32) first)
  (weld [capitalized t.word] " ")
--
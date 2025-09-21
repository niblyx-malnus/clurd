:: Enhanced naked generator - math operations
:: Usage: +add [%add 5 3], +add [%mul 4 6], +add [%sub 10 3]
::
|=  [op=?(%add %mul %sub %div) a=@ud b=@ud]
^-  @ud
?-  op
  %add  (add a b)
  %mul  (mul a b)
  %sub  ?:((gte a b) (sub a b) 0)
  %div  ?:(=(0 b) 0 (div a b))
==
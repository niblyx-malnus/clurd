::  :increment|multi 5
::  :increment|multi 3, =times 2
::  Example showing optional arguments pattern (like ahoy)
::
:-  %say
|=  $:  ^
        [count=@ud ~]
        [times=@ud ~]
    ==
::  Note: actual increment agent only supports [%increment ~]
::  This shows the argument pattern for educational purposes
[%increment-action [%increment ~]]
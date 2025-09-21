::  :increment|set-value 42
::  Example of agent-specific generator with arguments (demo only)
::  Note: actual increment agent only supports [%increment ~]
::
:-  %say
|=  $:  ^
        [n=@ud ~]
        ~
    ==
[%increment-action [%increment ~]]
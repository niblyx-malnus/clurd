/-  *increment
/+  default-agent, dbug
|%
+$  versioned-state
  $%  state-0
  ==
+$  state-0  [%0 value=@ud]
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
++  on-init
  ^-  (quip card _this)
  ~&  >  "increment: starting with value 0"
  [~ this(value 0)]
++  on-save
  ^-  vase
  !>(state)
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
  [~ this]
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ~&  >  "increment: got poke with mark {<mark>}"
  ?+  mark  !!
    %increment-action
    =/  act  !<(action vase)
    ?-  -.act
      %increment
      ~&  >  "incrementing from {<value>} to {<+(value)>}"
      [~ this(value +(value))]
    ==
  ==
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-agent  on-agent:def
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  ~
    [%x %value ~]
    ``noun+!>(value)
  ==
--

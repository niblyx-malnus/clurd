:: Simple increment agent for testing demonstration
::
/+  default-agent, dbug, text-utils
|%
+$  versioned-state
  $%  [%0 =counter]
  ==
+$  state-0  [counter=@ud]
+$  counter  @ud
+$  card  card:agent:gall
::
+$  action
  $%  [%inc ~]
      [%dec ~]
      [%reset ~]
      [%set value=@ud]
  ==
--
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
::
++  on-init
  ^-  (quip card _this)
  ~&  >  '%increment initialized'
  `this
::
++  on-save
  ^-  vase
  !>([%0 counter])
::
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state old-state)
  ?-  -.old
    %0  `this(counter counter.old)
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
    %increment-action
      =/  act  !<(action vase)
      ?-  -.act
        %inc
          =/  new-counter=@ud  +(counter)
          :_  this(counter new-counter)
          ~[[%give %fact ~[/counter] %atom !>(new-counter)]]
        ::
        %dec
          =/  new-counter=@ud  ?:(=(0 counter) 0 (dec counter))
          :_  this(counter new-counter)
          ~[[%give %fact ~[/counter] %atom !>(new-counter)]]
        ::
        %reset
          :_  this(counter 0)
          ~[[%give %fact ~[/counter] %atom !>(0)]]
        ::
        %set
          :_  this(counter value.act)
          ~[[%give %fact ~[/counter] %atom !>(value.act)]]
      ==
    ::
    %noun
      =/  value  !<(@ud vase)
      :_  this(counter value)
      ~[[%give %fact ~[/counter] %atom !>(value)]]
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  path  (on-watch:def path)
    [%counter ~]
      :_  this
      ~[[%give %fact ~ %atom !>(counter)]]
    ::
    [%words ~]
      =/  counter-words=(list tape)  (words:text-utils (scow %ud counter))
      :_  this
      ~[[%give %fact ~ %noun !>(counter-words)]]
  ==
::
++  on-leave
  |=  =path
  ^-  (quip card _this)
  `this
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %counter ~]     ``atom+!>(counter)
    [%x %words ~]
      =/  counter-words=(list tape)  (words:text-utils (scow %ud counter))
      ``noun+!>(counter-words)
    [%x %word-count ~]  ``atom+!>((word-count:text-utils (scow %ud counter)))
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  `this
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  `this
::
++  on-fail
  |=  [=term =tang]
  ^-  (quip card _this)
  (on-fail:def term tang)
--
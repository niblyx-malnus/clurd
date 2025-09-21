/-  *clibox
/+  *command-parser, shoe, verb, dbug, default-agent
|%
+$  versioned-state
  $%  state-0
  ==
+$  state-0  [%0 data]
+$  card  card:shoe
+$  sole-id  sole-id:shoe
++  print-green-cards
  |=  =wain
  ^-  (list card)
  %+  turn  wain
  |=  =cord
  [%shoe ~ %sole %klr [[~ ~ [~ %g]] [cord]~]~]
--
=|  state-0
=*  state  -
%-  agent:dbug
%+  verb  |
^-  agent:gall
%-  (agent:shoe command)
^-  (shoe:shoe command)
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
    des   ~(. (default:shoe this command) bowl)
::
++  on-init   on-init:def
::
++  on-save  !>(state)
::
++  on-load
  |=  ole=vase
  ^-  (quip card _this)
  =/  old=state-0  !<(state-0 ole)
  [~ this(state old)]
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  (on-poke:def mark vase)
      %clibox-action
    =/  axn  !<(action vase)
    ?-    -.axn
        %do-a-thing
      ~&  "Do a thing..."
      `this
        %do-another
      ~&  "Do another..."
      `this
        %add-a-ship
      ~&  "Adding ship..."
      `this(ships [ship.axn ships])
    ==
  ==
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-peek   on-peek:def
++  on-agent  on-agent:def
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
::
++  command-parser
  |=  =sole-id
  ^+  |~(nail *(like [? command]))  
  %+  stag  |
  (^command-parser bowl +.state)
::
++  tab-list
  |=  =sole-id
  ^-  (list [@t tank])
  ^tab-list
::
++  on-command
  |=  [=sole-id =command]
  ^-  (quip card _this)
  =;  cards=(list card)
    [cards this]
  ?-    -.command
      %do-a-thing
    [%pass / %agent [our dap]:bowl %poke clibox-action+!>(command)]~
    ::
      %do-another
    [%pass / %agent [our dap]:bowl %poke clibox-action+!>(command)]~
    ::
      %list-ships
    (print-green-cards (turn ships |=(=ship (scot %p ship))))
    ::
      %add-a-ship
    [%pass / %agent [our dap]:bowl %poke clibox-action+!>(command)]~
  ==
::
++  can-connect  |=(=sole-id `?`=(our.bowl src.bowl))
++  on-connect      on-connect:des
++  on-disconnect   on-disconnect:des
--

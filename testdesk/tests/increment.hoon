:: Tests for increment agent using monadic framework
::
/+  *test, *test-agent
/=  agent  /app/increment
|%
++  dap  %increment-test
:: Mock scry for testing
::
++  scries
  |=  =path
  ^-  (unit vase)
  ~
::
:: Test agent initialization
::
++  test-init
  %-  eval-mare
  =/  m  (mare ,~)
  ^-  form:m
  ;<  ~                bind:m  (set-scry-gate scries)
  ;<  caz=(list card)  bind:m  (do-init dap agent)
  ;<  ~                bind:m  (ex-cards caz ~)
  ;<  state=vase       bind:m  get-save
  %+  ex-equal  !>([%0 0])  state
::
:: Test basic increment operations
::
++  test-increment-pokes
  %-  eval-mare
  =/  m  (mare ,~)
  ^-  form:m
  ;<  ~                bind:m  (set-scry-gate scries)
  ;<  caz=(list card)  bind:m  (do-init dap agent)
  ;<  ~                bind:m  (ex-cards caz ~)
  :: Test increment action
  ;<  caz=(list card)  bind:m  (do-poke %increment-action !>([%inc ~]))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(1))])
  :: Test another increment
  ;<  caz=(list card)  bind:m  (do-poke %increment-action !>([%inc ~]))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(2))])
  :: Test decrement
  ;<  caz=(list card)  bind:m  (do-poke %increment-action !>([%dec ~]))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(1))])
  :: Verify final state
  ;<  state=vase       bind:m  get-save
  %+  ex-equal  !>([%0 1])  state
::
:: Test reset and set operations
::
++  test-reset-and-set
  %-  eval-mare
  =/  m  (mare ,~)
  ^-  form:m
  ;<  ~                bind:m  (set-scry-gate scries)
  ;<  caz=(list card)  bind:m  (do-init dap agent)
  ;<  ~                bind:m  (ex-cards caz ~)
  :: Increment to 5
  ;<  caz=(list card)  bind:m  (do-poke %increment-action !>([%set 5]))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(5))])
  :: Test reset to 0
  ;<  caz=(list card)  bind:m  (do-poke %increment-action !>([%reset ~]))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(0))])
  :: Verify final state
  ;<  state=vase       bind:m  get-save
  %+  ex-equal  !>([%0 0])  state
::
:: Test subscription functionality
::
++  test-subscriptions
  %-  eval-mare
  =/  m  (mare ,~)
  ^-  form:m
  ;<  ~                bind:m  (set-scry-gate scries)
  ;<  caz=(list card)  bind:m  (do-init dap agent)
  ;<  ~                bind:m  (ex-cards caz ~)
  :: Set counter to 42 first
  ;<  caz=(list card)  bind:m  (do-poke %increment-action !>([%set 42]))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(42))])
  :: Test subscription to /counter path
  ;<  caz=(list card)  bind:m  (do-watch /counter)
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~ %atom !>(42))])
  :: Test subscription to /words path
  ;<  caz=(list card)  bind:m  (do-watch /words)
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~ %noun !>(~["42"]))])
  :: Test leaving subscription
  ;<  caz=(list card)  bind:m  (do-leave /counter)
  ;<  ~                bind:m  (ex-cards caz ~)
  (pure:m ~)
::
:: Test scry endpoints
::
++  test-scry
  %-  eval-mare
  =/  m  (mare ,~)
  ^-  form:m
  ;<  ~                bind:m  (set-scry-gate scries)
  ;<  caz=(list card)  bind:m  (do-init dap agent)
  ;<  ~                bind:m  (ex-cards caz ~)
  :: Set counter to 123
  ;<  caz=(list card)  bind:m  (do-poke %increment-action !>([%set 123]))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(123))])
  :: Test scry for counter value
  ;<  ~                bind:m  (ex-scry-result /x/counter !>(123))
  :: Test scry for words representation
  ;<  ~                bind:m  (ex-scry-result /x/words !>(~["123"]))
  :: Test scry for word count
  ;<  ~                bind:m  (ex-scry-result /x/word-count !>(1))
  (pure:m ~)
::
:: Test noun poke interface
::
++  test-noun-poke
  %-  eval-mare
  =/  m  (mare ,~)
  ^-  form:m
  ;<  ~                bind:m  (set-scry-gate scries)
  ;<  caz=(list card)  bind:m  (do-init dap agent)
  ;<  ~                bind:m  (ex-cards caz ~)
  :: Test noun poke with value 99
  ;<  caz=(list card)  bind:m  (do-poke %noun !>(99))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(99))])
  :: Verify final state
  ;<  state=vase       bind:m  get-save
  %+  ex-equal  !>([%0 99])  state
::
:: Test underflow protection
::
++  test-underflow
  %-  eval-mare
  =/  m  (mare ,~)
  ^-  form:m
  ;<  ~                bind:m  (set-scry-gate scries)
  ;<  caz=(list card)  bind:m  (do-init dap agent)
  ;<  ~                bind:m  (ex-cards caz ~)
  :: Try to decrement from 0 (should stay at 0)
  ;<  caz=(list card)  bind:m  (do-poke %increment-action !>([%dec ~]))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(0))])
  :: Verify state is still 0
  ;<  state=vase       bind:m  get-save
  %+  ex-equal  !>([%0 0])  state
::
:: Test multi-ship scenario
::
++  test-multi-ship
  %-  eval-mare
  =/  m  (mare ,~)
  ^-  form:m
  ;<  ~                bind:m  (set-scry-gate scries)
  ;<  caz=(list card)  bind:m  (do-init dap agent)
  ;<  ~                bind:m  (ex-cards caz ~)
  :: Set source to ~dev and increment
  ;<  ~                bind:m  (set-src ~dev)
  ;<  caz=(list card)  bind:m  (do-poke %increment-action !>([%inc ~]))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(1))])
  :: Set source to ~bus and increment again
  ;<  ~                bind:m  (set-src ~bus)
  ;<  caz=(list card)  bind:m  (do-poke %increment-action !>([%inc ~]))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(2))])
  :: Verify final state (both ships incremented same counter)
  ;<  state=vase       bind:m  get-save
  %+  ex-equal  !>([%0 2])  state
::
:: Test integration with text-utils library
::
++  test-text-utils-integration
  %-  eval-mare
  =/  m  (mare ,~)
  ^-  form:m
  ;<  ~                bind:m  (set-scry-gate scries)
  ;<  caz=(list card)  bind:m  (do-init dap agent)
  ;<  ~                bind:m  (ex-cards caz ~)
  :: Set counter to a multi-digit number
  ;<  caz=(list card)  bind:m  (do-poke %increment-action !>([%set 1.234]))
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~[/counter] %atom !>(1.234))])
  :: Test /words subscription (should get words of "1234")
  ;<  caz=(list card)  bind:m  (do-watch /words)
  ;<  ~                bind:m  (ex-cards caz ~[(ex-fact ~ %noun !>(~["1.234"]))])
  :: Test scry for word count (should be 1 word)
  ;<  ~                bind:m  (ex-scry-result /x/word-count !>(1))
  (pure:m ~)
--
/-  spider
/+  io=strandio
=,  strand=strand:spider
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
^-  form:m
::  Usage: -tedtest!increment-n-times 5
::  Increments the increment agent 5 times and returns final value
::
=+  !<([~ n=@ud] arg)
~&  >>  "🔄 Incrementing {<n>} times..."
;<  beg=@ud  bind:m  (scry:io @ud /gx/increment/value/noun)
~&  >>  "📊 Starting value: {<beg>}"
=|  i=@ud
|-  ^-  form:m
?:  =(i n)
  ;<  end=@ud  bind:m  (scry:io @ud /gx/increment/value/noun)
  ~&  >>  "✅ Final value: {<end>} (increased by {<(sub end beg)>})"
  (pure:m !>(end))
~&  >  "🔄 Increment #{<+(i)>}..."
=/  =cage  increment-action+!>([%increment ~])
;<  ~  bind:m  (poke-our:io %increment cage)
$(i +(i))
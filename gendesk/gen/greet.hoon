:: %ask generator - interactive greeting
:: Usage: +greet
::
/-  sole
/+  generators
=,  [sole generators]
:-  %ask
|=  *
^-  (sole-result (cask tang))
%+  print    leaf+"What is your name?"
%+  prompt   [%& %prompt "name: "]
|=  t=tape
%+  produce  %tang
:~  leaf+"Hello, {t}!"
    leaf+"Nice to meet you."
==
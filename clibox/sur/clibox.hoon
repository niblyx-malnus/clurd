|%
+$  data  ships=(list ship)
::
+$  action
  $%  [%do-a-thing ~]
      [%do-another ~]
      [%add-a-ship =ship]
  ==
::
+$  command
  $?  [%do-a-thing ~]
      [%do-another ~]
      [%list-ships ~]
      [%add-a-ship =ship]
  ==
::
++  tab-list
  ^-  (list [@t tank])
  :~  ['dat' leaf+"do a thing"]
      ['dan' leaf+"do another"]
      ['lis' leaf+"list ships"]
      ['add' leaf+"add a ship"]
  ==
--

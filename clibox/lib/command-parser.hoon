/-  *clibox
|%
++  command-parser
  |=  [=bowl:gall =data]
  ;~  pose
    parse-do-a-thing
    parse-do-another
    parse-list-ships
    parse-add-a-ship
  ==
::    
++  parse-do-a-thing  (cold [%do-a-thing ~] (jest 'dat'))
++  parse-do-another  (cold [%do-another ~] (jest 'dan'))
++  parse-list-ships  (cold [%list-ships ~] (jest 'lis'))
++  parse-add-a-ship
  ;~  (glue ace)
    (cold %add-a-ship (jest 'add'))
    ;~(pfix sig fed:ag)
  ==
--

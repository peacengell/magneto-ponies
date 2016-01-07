#! /bin/bash

# will.parsons@rackspace.co.uk

STRACE_ARGS="-s4096 -tt  -e trace=sendto,connect,write,open"

echo -ne  "\n You are in $PWD. Is this the DocumentRoot? [y/n] : "

read a
if [[ $a == "Y" || $a == "y" || $a = "yes" ]]; then
        echo "Good."
else
  echo -e "\n That would be a good start.\n"
  exit 0
fi

echo -ne  "\nEnter the HTTP_HOST (full domain name this site uses) : "
read HTTP_HOST
if [ -z "$HTTP_HOST" ]; then
   echo "Empty host will usually redirect immediately.
   curl -I localhost    might help\n\n:
   "
   curl -I localhost 2>/dev/null | egrep -i '30[12]|location'
   exit 0
   
fi

echo -ne  "\nEnter the REQUEST_URI (including the slash) : "
read REQUEST_URI

if [ -z "$REQUEST_URI" ]; then
   echo "Defaulting to homepage / "
fi



echo -ne  "\nStrace output file name (leave blank for default /home/rack/<date>.strace) : "
read STRACE_OUTPUT
if [ -z "$STRACE_OUTPUT" ]; then
   DATE=$(date +%Y%m%d%H%M%S)
   STRACE_OUTPUT=/home/rack/${DATE}.strace
   echo "Defaulting to $STRACE_OUTPUT "
fi


time strace $STRACE_ARGS -o $STRACE_OUTPUT php index.php

echo -e "\n\n Strace output saved to $STRACE_OUTPUT \n"

echo "

Analysis examples:

How many SELECT queries? : grep -c SELECT $STRACE_OUTPUT
Show all SELECT queries  : cat $STRACE_OUTPUT | egrep -o 'SELECT.*\ =\ '
Show all PHP file opens  : cat $STRACE_OUTPUT | egrep -o 'open.*php'

Examples for Magento: 

- Show PHP file opens, excluding the usual Magento base classes.
- Use the timings to see which modules might be slow:
cat $STRACE_OUTPUT | egrep 'open.*php' | egrep -v 'Mage\/|Zend|Varien|lib64|etc/php|license' | uniq -c



- Show number of queries after each PHP file open, excluding base classes:
cat $STRACE_OUTPUT | egrep -o  'open.*php|SELECT' | egrep -v 'Mage\/|Zend|Varien|lib64|etc/php|license' | uniq -c

- ...and only show those which were more than 10 SELECTS (likely to cause slow performance)
cat $STRACE_OUTPUT | egrep -o  'open.*php|SELECT' | egrep -v 'Mage\/|Zend|Varien|lib64|etc/php|license' | uniq -c | egrep -B1 '[0-9][0-9] SELECT' 

"

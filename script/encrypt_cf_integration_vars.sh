#!/bin/sh

# argument is the path to the script that sets all the vars
source $1

for var in `grep -v '^#' $1 | cut -d= -f1`
do
  value=`eval echo "\\$$var"`;
  echo \#$var
  encrypted=`travis encrypt $var=$value 2>/dev/null`
  echo "- secure: $encrypted"
  echo
done

echo "*****************"
echo "paste these into .travis.yml in place of the ones that are already there"
echo "remember to remove those pesky newlines"
echo "*****************"

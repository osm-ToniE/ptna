#!/bin/bash

PATH=$PWD/../bin:$PATH

ERRORS=0

for script in *.script
do
    bash ./$script
    
    ERRORS=$(( $ERRORS + $? ))
done

echo ""
echo "Tests ended with $ERRORS errors"
exit $ERRORS


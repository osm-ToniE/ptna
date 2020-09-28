#!/bin/bash

PATH=$PWD/../bin:$PATH

perl -c ../bin/ptna-routes.pl

if [ "$?" = "0" ]
then
    ERRORS=0

    for infile in *.osm *.xml
    do
        TEST=$(basename $infile .osm)
        TEST=$(basename $TEST   .xml)

        if [ "$TEST" != '*' ]
        then
            if [ -e "$TEST.script" ]
            then
                bash ./$TEST.script $infile
            else
                bash ./generic.script $infile
            fi

            ERRORS=$(( $ERRORS + $? ))
        fi
    done

    echo ""
    echo "Tests ended with $ERRORS errors"
    exit $ERRORS
else
    echo ""
    echo "Test ended with syntax errors in ptna-routes.pl"
fi

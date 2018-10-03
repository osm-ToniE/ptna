#!/bin/bash

#
# analyze ÖPNV networks
#

WD=$PWD

PATH=$PWD/bin:$PATH

with_upload=$(echo $* | fgrep -c 'u')

if [ "$with_upload" = '1' ]
then
    wiki-page.pl --pull --page="User:ToniE/analyze-routes" --file=Networks/analyze-routes.wiki
    today=$(date '+%d.%m.%Y')
    sed -i -e "s/| Auswertung vom [0123][0-9]\.[01][0-9]\.2[0-9][0-9][0-9]/| Auswertung vom $today/" \
           -e 's/bgcolor=.* <!-- analysis-status=new --> //'                                           Networks/analyze-routes.wiki
fi

for A in  Networks/[A-Z]*
do
    echo
    echo $(date "+%Y-%m-%d %H:%M:%S") "$A"
    echo
    
    if [ -d $A ]
    then
        cd $A
    
        analyze-network.sh $*
    
        cd $WD
    fi
    
done

if [ "$with_upload" = '1' ]
then
    wiki-page.pl --push --page="User:ToniE/analyze-routes" --file=Networks/analyze-routes.wiki --summary="Update by automated analysis"
fi




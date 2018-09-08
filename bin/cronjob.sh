#!/bin/bash

#
# analyze ÖPNV networks via cronjob
#

# source the .bashrc file in HOME directory to import variables which should not be in the source code
#
# $TARGET_HOST      target host: user@host for sftp command; authentication via private/public ssh keys             (TARGET_HOST=user@example.com)
# $TARGET_LOC       target loc: directory, where to store the data with the sftp command                            (TARGET_LOC=analyze-routes)
# $TARGET_URL       target url: $TARGET_URL/$TARGET_LOC are the location where all the analysis files can be found  (TARGET_URL=https://example.com/OSM)
# $WIKI_USERNAME    user name to use for authentication to OSM wiki                                                 (tool used: ./bin/wiki-page.pl)
# $WIKI_PASSWORD    password to use for authentication to OSM wiki                                                  (tool used: ./bin/wiki-page.pl)
#

source $HOME/.bashrc


export LANG=C

PATH=$HOME/bin:$PWD/bin:$PATH

LOGFILE=analyze-all-networks.txt

analyze-all-networks.sh -oau > $LOGFILE 2>&1 < /dev/null

emptyxml=$(ls -l Networks/*/*.xml | fgrep -c " 0 $(date '+%b %d') ")

if [ "$emptyxml" -gt 0 -a "$emptyxml" -lt 10 ]
then
    # most of the analysis succeeded, let's try a second time for the others
    
    sleep 300
    
    analyze-all-networks.sh -Oau >> $LOGFILE 2>&1 < /dev/null
fi

if [ -n "$TARGET_HOST" -a -n "$TARGET_LOC" ]
then
    echo -e "put $LOGFILE $TARGET_LOC/\nchmod 644 $TARGET_LOC/$LOGFILE" | sftp -b - $TARGET_HOST
fi



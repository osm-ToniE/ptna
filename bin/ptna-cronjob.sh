#!/bin/bash

#
# Public Transport Network Analysis via cronjob
#

# we can we find all the executables of PTNA

export PTNA_BIN="$HOME/ptna/bin"

# location on the server or local location where the results will be copied to

export PTNA_TARGET_LOC="/srv/www/htdocs"

# this is the location below $PTNA_TARGETLOC, where the results will bes stored (in sub directories)

export PTNA_RESULTS_LOC="results"

# this is the location on the web server for the PTNA pages

export PTNA_WEB_BASE_LOC=""

# this is the file with the overview of the date(s) of the analysis, manipulated by the tool
# remotely: sftp $PTNA_TARGET_HOST; get $PTNA_TARGET_LOC$PTNA_RESULTS_HTML; put $PTNA_RESULTS_HTML $PTNA_TARGET_LOC
# locally:  $PTNA_TARGET_LOC$PTNA_RESULTS_HTML

export PTNA_RESULTS_HTML="results.html"

# this is the base directory, where we can find all the "settings.sh" files for the networks

export PTNA_NETWORKS_LOC="$HOME/tmp/ptna/networks"

# this is the base directory, where we store all result files (working base)

export PTNA_WORK_LOC="$HOME/tmp/ptna/work"



# source $HOME/.ptna-config to overwrite the settings above
# and mybe to set some perl related variables (copied from .bashrc)

[ -f $HOME/.ptna-config ] && source $HOME/.ptna-config


###################################################################################

if [ -n "$PTNA_BIN" ]
then
    export PATH="$PTNA_BIN:$PATH"
fi

# check if PTNA_WORK_LOC exists and 'cd' there

if [ -n "$PTNA_WORK_LOC" ]
then
    if [ ! -d "$PTNA_WORK_LOC" ]
    then
        mkdir -p $PTNA_WORK_LOC
    fi
else
    echo "directory for working location 'PTNA_WORK_LOC' is not specified ... terminating"
    exit 1
fi

if [ -d "$PTNA_NETWORKS_LOC" ]
then
    if [ -n "$1" ]
    then
        PTNA_NETWORKS_LOC="$PTNA_NETWORKS_LOC/$1"
        LOGFILE_SUFFIX="-$1"
    fi
fi


if [ -d "$PTNA_NETWORKS_LOC" ]
then
    if [ -d "$PTNA_WORK_LOC" ]
    then

        cd $PTNA_WORK_LOC

        LOGFILE=${PTNA_WORK_LOC}/log/ptna-all-networks$LOGFILE_SUFFIX.log

        # c == clean the work area
        # C == clean the XML file

        ptna-all-networks.sh -cC > $LOGFILE 2>&1 < /dev/null

        # o == do the overpassapi query and download the data (to work area)
        # g == get the OSM-Wiki data for the routes
        # a == do the analysis (in work area)
        # u == update the result from the work area to the location of the web service

        if [ "$1" = "UTC+01" ]
        then
            # for timezone UTC+01 run jobs in parallel using also a more powerful overpass-api server
            ptna-all-networks-parallel.sh -ogau >> $LOGFILE 2>&1 < /dev/null
        else
            # for other timezones it is OK to run sequentially and using standard overpass-api server
            ptna-all-networks.sh -ogau >> $LOGFILE 2>&1 < /dev/null
        fi

        emptyxml=$(find ${PTNA_WORK_LOC} -name '*.xml' -size 0 | wc -l)

        if [ "$emptyxml" -gt 0 -a "$emptyxml" -lt 90 ]
        then
            # most (> 50%) of the analysis succeeded, let's try a second time for the others

            sleep 300

            # O == do the overpassapi query only if the downloaded XML data is empty, otherwise skip the rest
            #      g == get the OSM-Wiki data for the routes
            #      a == do the analysis (in work area)
            #      u == update the result from the work area to the location of the web service

            # run this sequentially using standard overpass-api server
            ptna-all-networks.sh -Ogau >> $LOGFILE 2>&1 < /dev/null
        fi


        # c == clean the work area
        # C == clean the XML file

        if [ "$(date '+%u')" = "1" ]    # = Monday
        then
            # on Mondays, do not delete the downloaded XML data

            ptna-all-networks.sh -c >> $LOGFILE 2>&1 < /dev/null
        else
            ptna-all-networks.sh -cC >> $LOGFILE 2>&1 < /dev/null
        fi

    else
        echo "directory $PTNA_WORK_LOC does not exist ... terminating"
        exit 2
    fi
else
    echo "directory $PTNA_NETWORKS_LOC does not exist ... terminating"
    exit 3
fi

#!/bin/bash

#
# Public Transport Network Analysis for a timezone
#

# where can we find all the executables of PTNA

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
        LOGFILE_SUFFIX="$(echo $1 | sed -e 's/\//-/g')"
    fi
fi


if [ -d "$PTNA_NETWORKS_LOC" ]
then
    if [ -d "$PTNA_WORK_LOC" ]
    then

        cd $PTNA_WORK_LOC

        LOGFILE=${PTNA_WORK_LOC}/log/ptna-all-networks-$LOGFILE_SUFFIX.log

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start Cron Job"                >  $LOGFILE

        if [ "$1" = "UTC+01" -a "$(date '+%H')" = "02" ]
        then
            # for timezone UTC+01 and if running in the night at 2 AM
            # run jobs in parallel using also a more powerful overpass-api server
            # no longer use "overpass.kumi.systems" they are not up-to-date
            export PTNA_OVERPASS_API_SERVER=""
         else
            # for other timezones and other time it is OK to run sequentially and using standard overpass-api server
            export PTNA_OVERPASS_API_SERVER=""
        fi

        # L == delete old 'network' specific log files (do that here, to keep log files as long as possible)
        # c == clean the work area
        # C == clean the XML file (do that here, some 'network' will reuse XML files, so 'C' togehter with 'o' spoils that)
        #   e == use planet extracts instead of overpass api query (if not configured or it failed, there's a fall-back to 'o')
        #   o == do the overpass api query and download the data (to work area)
        # i == inject GTFS data into OSM-Wiki routes data (read raw, inject, write back)
        # g == get the OSM-Wiki data for the routes (read parsed)
        # a == do the analysis (in work area)
        # u == update the result from the work area to the location of the web service

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start clean-up"                       >> $LOGFILE
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"        >> $LOGFILE
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"                   >> $LOGFILE

        # option 'C' will delete also downloaded (overpass) and/or extracted (planet) data

        ptna-all-networks-parallel.sh -LcC                                          >> $LOGFILE 2>&1 < /dev/null

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start extracts and main analysis"     >> $LOGFILE
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"        >> $LOGFILE
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"                   >> $LOGFILE

        # now it is safe to download (o = overpass) or extract (e = planet) data and start analysis

        ptna-all-networks-parallel.sh -leigau                                       >> $LOGFILE 2>&1 < /dev/null

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"        >> $LOGFILE
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"                   >> $LOGFILE

        emptyxml=$(find ${PTNA_WORK_LOC} -name '*.xml' -size 0 | wc -l)

        if [ "$emptyxml" -gt 0 -a "$emptyxml" -lt 130 ]
        then
            # most of the analysis succeeded,
            # let's try a second time for the others
            # using the selected overpass api server

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$emptyxml analysis runs have failed (size of XML == 0). Let's wait 5 minutes and then try again." >> $LOGFILE

            sleep 300

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start catch-up with selected overpass api server '$PTNA_OVERPASS_API_SERVER' for '$emptyxml' networks (single execution)" >> $LOGFILE
            find ${PTNA_WORK_LOC} -name '*.xml' -size 0        >> $LOGFILE
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "End of list" >> $LOGFILE

            # l == log (append) to 'network' specific logfile
            # O == do the overpassapi query only if the downloaded XML data is empty, otherwise skip the rest
            #      i == inject GTFS data into OSM-Wiki routes data (read raw, inject, write back)
            #      g == get the OSM-Wiki data for the routes (read parsed)
            #      a == do the analysis (in work area)
            #      u == update the result from the work area to the location of the web service

            # run this again using the selected overpass-api server
            ptna-all-networks-parallel.sh -lOigau >> $LOGFILE 2>&1 < /dev/null
        elif [ "$emptyxml" -gt 0 ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "No catch-up with selected overpass api server '$PTNA_OVERPASS_API_SERVER, there are too many failed downloads ($emptyxml)'" >> $LOGFILE
            find ${PTNA_WORK_LOC} -name '*.xml' -size 0        >> $LOGFILE
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "End of list" >> $LOGFILE
        fi

        if [ -n "$PTNA_OVERPASS_API_SERVER" ]
        then
            # if we did not use the the standard overpass api server,
            # let's check again for empty XML files and
            # restart analysis with standard overpass api server

            emptyxml=$(find ${PTNA_WORK_LOC} -name '*.xml' -size 0 | wc -l)

            # if [ "$emptyxml" -gt 0 -a "$emptyxml" -lt 130 ]
            # then
                # most (> 50%) of the analysis succeeded,
                # let's try a third time for the others
                # now using the standard overpass api server

                export PTNA_OVERPASS_API_SERVER=""

                sleep 300

                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start catch-up with standard overpass api server for '$emptyxml' networks (single execution)" >> $LOGFILE
                find ${PTNA_WORK_LOC} -name '*.xml' -size 0        >> $LOGFILE
                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "End of list" >> $LOGFILE

                # l == log (append) to 'network' specific logfile
                # O == do the overpassapi query only if the downloaded XML data is empty, otherwise skip the rest
                #      i == inject GTFS data into OSM-Wiki routes data (read raw, inject, write back)
                #      g == get the OSM-Wiki data for the routes (read parsed)
                #      a == do the analysis (in work area)
                #      u == update the result from the work area to the location of the web service

                # run this again using the standard overpass-api server
                ptna-all-networks-parallel.sh -lOigau >> $LOGFILE 2>&1 < /dev/null
            # fi
        fi


        # l == log (append) to 'network' specific logfile
        # c == clean the work area
        # C == clean the XML file

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start clean-up" >> $LOGFILE

        if [ "$(date '+%u')" = "7" ]    # = Sunday
        then
            # on Sundays, do not delete the downloaded XML data

            ptna-all-networks-parallel.sh -lc  >> $LOGFILE 2>&1 < /dev/null
        else
            ptna-all-networks-parallel.sh -lcC >> $LOGFILE 2>&1 < /dev/null
        fi

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"    >> $LOGFILE
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"               >> $LOGFILE
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Cron Job finished"                >> $LOGFILE

    else
        echo "directory $PTNA_WORK_LOC does not exist ... terminating"
        exit 2
    fi
else
    echo "directory $PTNA_NETWORKS_LOC does not exist ... terminating"
    exit 3
fi

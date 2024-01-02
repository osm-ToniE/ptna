#!/bin/bash

#
# Public Transport Network Analysis of a single network
#

PTNA_NETWORK_CALL_TIME=$(date --utc "+%s")
PTNA_NETWORK_OPTIONS="$@"

echo $(date "+%Y-%m-%d %H:%M:%S") "Start: ptna-networks.sh $PTNA_NETWORK_OPTIONS"

if [ -z "$PTNA_TARGET_LOC"     -o \
     -z "$PTNA_RESULTS_LOC"    -o \
     -z "$PTNA_NETWORKS_LOC"   -o \
     -z "$PTNA_WORK_LOC"            ]
then
    echo " ...unset global variable(s)"
    [ -z "$PTNA_TARGET_LOC"       ] && echo "Please specify: PTNA_TARGET_LOC as environment variable outside the tools"
    [ -z "$PTNA_RESULTS_LOC"      ] && echo "Please specify: PTNA_RESULTS_LOC as environment variable outside the tools"
    [ -z "$PTNA_NETWORKS_LOC"     ] && echo "Please specify: PTNA_NETWORKS_LOC as environment variable outside the tools"
    [ -z "$PTNA_WORK_LOC"         ] && echo "Please specify: PTNA_WORK_LOC as environment variable outside the tools"
    echo "... terminating"
    exit 1
fi


SETTINGS_DIR="."


TEMP=$(getopt -o acCfgGhLmoOpPuwWS: --long analyze,clean-created,clean-downloaded,get-routes,get-talk,force-download,help,log-delete,modiify-routes-data,overpass-query,overpass-query-on-zero-xml,push-routes,push-talk,update-result,watch-routes,watch-talk,settings-dir: -n 'ptna-network.sh' -- "$@")

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 2 ; fi

eval set -- "$TEMP"

while true ; do
    case "$1" in
        -a|--analyze)                       analyze=true                ; shift ;;
        -c|--clean-created)                 cleancreated=true           ; shift ;;
        -C|--clean-downloaded)              cleandownloaded=true        ; shift ;;
        -f|--force-download)                forcedownload=true          ; shift ;;
        -g|--get-routes)                    getroutes=true              ; shift ;;
        -G|--get-talk)                      gettalk=true                ; shift ;;
        -h|--help)                          help=true                   ; shift ;;
        -L|--log-delete)                    deletelog=true              ; shift ;;
        -m|--modify-routes-data)            modify=true                 ; shift ;;
        -o|--overpass-query)                overpassquery=true  ; overpassqueryonzeroxml=false ; shift ;;
        -O|--overpass-query-on-zero-xml)    overpassqueryonzeroxml=true  ; overpassquery=false ; shift ;;
        -p|--push-routes)                   pushroutes=true             ; shift ;;
        -P|--push-talk)                     pushtalk=true               ; shift ;;
        -u|--update-result)                 updateresult=true           ; shift ;;
        -w|--watch-routes)                  watchroutes=true            ; shift ;;
        -W|--watch-talk)                    watchtalk=true              ; shift ;;
        -S|--settings_dir)                  SETTINGS_DIR=$2             ; shift 2 ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 3 ;;
    esac
done


#
#
#

if [ -f "$SETTINGS_DIR/settings.sh" -a -r "$SETTINGS_DIR/settings.sh" ]
then
    . $SETTINGS_DIR/settings.sh              # source the settings.sh and 'import' shell network specific variables
else
    echo "$SETTINGS_DIR/settings.sh: file not found ... terminating"
    exit 4
fi


if [ -z "$PREFIX"          -o \
     -z "$OVERPASS_QUERY"  -o \
     -z "$ANALYSIS_OPTIONS"     ]
then
    echo "$SETTINGS_DIR/settings.sh file: unset variables(s)"
    [ -z "$PREFIX"           ] && echo "Please specify: PREFIX"
    [ -z "$OVERPASS_QUERY"   ] && echo "Please specify: OVERPASS_QUERY"
    [ -z "$ANALYSIS_OPTIONS" ] && echo "Please specify: ANALYSIS_OPTIONS"
    echo "... terminating"
    exit 5
fi

# on the web and in the work directory, the data will be stored in sub-directories
# PREFIX=DE-BY-MVV --> stored in SUB_DIR=DE/BY
# PREFIX=DE-BW-DING-SWU --> stored in SUB_DIR=DE/BW
# PREFIX=FR-IDF-entre-seine-et-foret --> stored in SUB_DIR=FR/IDF
# PREFIX=EU-Flixbus --> stored in SUB_DIR=EU

# PREFIX=FR-IDF-entre-seine-et-foret --> changed into in SUB_DIR=FR/IDF-entre-seine-et-foret
SUB_DIR=${PREFIX/-//}
# SUB_DIR=FR/IDF-entre-seine-et-foret --> changed into in SUB_DIR=FR/IDF/entre-seine-et-foret
SUB_DIR=${SUB_DIR/-//}
# SUB_DIR=FR/IDF/entre-seine-et-foret --> changed into in SUB_DIR=FR/IDF
SUB_DIR="${SUB_DIR%/*}"

COUNTRY_DIR="${PREFIX%%-*}"

WORK_LOC="$PTNA_WORK_LOC/$SUB_DIR"

ROUTES_FILE="$PREFIX-Routes.txt"
SETTINGS_FILE="settings.sh"
TALK_FILE="$PREFIX-Talk.wiki"

HTML_FILE="$PREFIX-Analysis.html"
DIFF_FILE="$PREFIX-Analysis.html.diff"
DIFF_HTML_FILE="$PREFIX-Analysis.diff.html"
SAVE_FILE="$PREFIX-Analysis.html.save"
DETAILS_FILE="$PREFIX-Analysis-details.txt"
STATISTICS_DB="$PREFIX-Analysis-statistics.db"
SQ_OPTIONS="-init /dev/null"

if [ "$OVERPASS_REUSE_ID" ]
then
    OSM_XML_FILE_ABSOLUTE="$PTNA_WORK_LOC/$OVERPASS_REUSE_ID-Data.xml"
else
    OSM_XML_FILE_ABSOLUTE="$WORK_LOC/$PREFIX-Data.xml"
fi

CALL_PARAMS="--server-response --read-timeout=1200 --tries=2 --wait=10 --random-wait --no-verbose"

#
#
#

if [ ! -d "$WORK_LOC" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Creating directory $WORK_LOC"
    mkdir -p $WORK_LOC
fi

if [ -d "$WORK_LOC" ]
then
   echo $(date "+%Y-%m-%d %H:%M:%S") "Init Statistics DB $WORK_LOC/$STATISTICS_DB"

    ptna_columns="id INTEGER PRIMARY KEY AUTOINCREMENT, start INTEGER DEFAULT 0, stop INTEGER DEFAULT 0, options TEXT DEFAULT ''"
    sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "CREATE TABLE IF NOT EXISTS ptna ($ptna_columns);"

    download_columns="id INTEGER PRIMARY KEY, start INTEGER DEFAULT 0, stop INTEGER DEFAULT 0, wget_ret INTEGER DEFAULT 0, success INTEGER DEFAULT 0, attempt INTEGER DEFAULT 1, size INTEGER DEFAULT 0, osm_data INTEGER DEFAULT 0"
    sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "CREATE TABLE IF NOT EXISTS download ($download_columns);"
    sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "CREATE TABLE IF NOT EXISTS retry_download ($download_columns);"

    routes_columns="id INTEGER PRIMARY KEY, start INTEGER DEFAULT 0, stop INTEGER DEFAULT 0, ret INTEGER DEFAULT 0, modified INTEGER DEFAULT 0, location TEXT DEFAULT '', size INTEGER DEFAULT 0"
    sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "CREATE TABLE IF NOT EXISTS routes ($routes_columns);"

    analysis_columns="id INTEGER PRIMARY KEY, start INTEGER DEFAULT 0, stop INTEGER DEFAULT 0, size INTEGER DEFAULT 0"
    sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "CREATE TABLE IF NOT EXISTS analysis ($analysis_columns);"

    updateresult_columns="id INTEGER PRIMARY KEY, start INTEGER DEFAULT 0, stop INTEGER DEFAULT 0, updated INTEGER DEFAULT 0, diff_lines INTEGER DEFAULT 0, html_changes INTEGER DEFAULT 0"
    sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "CREATE TABLE IF NOT EXISTS updateresult ($updateresult_columns);"

    sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO ptna (start,options) VALUES ($PTNA_NETWORK_CALL_TIME,'$PTNA_NETWORK_OPTIONS');"
    PTNA_NETWORK_DB_ID=$(sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "SELECT seq FROM sqlite_sequence WHERE name='ptna';")
    echo $(date "+%Y-%m-%d %H:%M:%S") "Statistic entries with id = $PTNA_NETWORK_DB_ID"
fi

#
#
#

if [ "$deletelog" = "true" ]
then
    rm -f $WORK_LOC/$HTML_FILE.log
fi

#
#
#

if [ "$cleancreated" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Removing temporary files"
    rm -f $WORK_LOC/$HTML_FILE $WORK_LOC/$DIFF_FILE $WORK_LOC/$DIFF_HTML_FILE $WORK_LOC/$SAVE_FILE $OSM_XML_FILE_ABSOLUTE.part.*
    [ -d $OSM_XML_FILE_ABSOLUTE.lock ] && rmdir $OSM_XML_FILE_ABSOLUTE.lock
fi

#
#
#

if [ "$cleandownloaded" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Removing XML and Routes file"
    rm -f $OSM_XML_FILE_ABSOLUTE $OSM_XML_FILE_ABSOLUTE.part.* $WORK_LOC/$ROUTES_FILE
    [ -d $OSM_XML_FILE_ABSOLUTE.lock ] && rmdir $OSM_XML_FILE_ABSOLUTE.lock
fi

#
#
#

if [ "$forcedownload" = "true" ]
then
    overpassquery="true"

elif [ "$overpassquery" = "true" ]
then
    if [ "$OVERPASS_REUSE_ID" -a -f $OSM_XML_FILE_ABSOLUTE -a -s $OSM_XML_FILE_ABSOLUTE ]
    then
        last_mod=$(stat -c '%Y' $OSM_XML_FILE_ABSOLUTE)
        now=$(date '+%s')
        age=$(( $now - $last_mod ))

        if [ "$age" -lt 5400 ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S") "Skipping download via Overpass Query API to $OSM_XML_FILE_ABSOLUTE"
            echo $(date "+%Y-%m-%d %H:%M:%S") "Age of file: $age seconds is less than 5400 seconds = 1.5 hours"
            echo $(date "+%Y-%m-%d %H:%M:%S") "Use option -f if you want to force the download"
            overpassquery="false"
        fi
    fi
fi

#
#
#

if [ "$overpassqueryonzeroxml" = "true" ]
then
    if [ -f $OSM_XML_FILE_ABSOLUTE -a -s $OSM_XML_FILE_ABSOLUTE ]
    then
        if [ $OSM_XML_FILE_ABSOLUTE -nt $WORK_LOC/$HTML_FILE ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S") "File '$OSM_XML_FILE_ABSOLUTE' exists and is newer than '$WORK_LOC/$HTML_FILE', starting analysis if requested"
       else
            echo $(date "+%Y-%m-%d %H:%M:%S") "File '$OSM_XML_FILE_ABSOLUTE' exists and is older than '$WORK_LOC/$HTML_FILE', no further analysis required, terminating"
            PTNA_NETWORK_STOP_TIME=$(date --utc "+%s")
            sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "UPDATE ptna SET stop=$(date --utc "+%s") WHERE id=$PTNA_NETWORK_DB_ID;"
            exit 0
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "File '$OSM_XML_FILE_ABSOLUTE' does not exist or is empty, starting download"
        overpassquery="true"
    fi
fi

#
#
#

if [ "$overpassquery" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Calling Overpass-API for '$PREFIX'"

    if [ -d "$WORK_LOC" ]
    then
        OSM_XML_LOC=$(dirname $OSM_XML_FILE_ABSOLUTE)

        if [ ! -d "$OSM_XML_LOC" ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S") "Creating directory $OSM_XML_LOC"
            mkdir -p $OSM_XML_LOC
        fi

        if [ -d "$OSM_XML_LOC" ]
        then
            mkdir $OSM_XML_FILE_ABSOLUTE.lock
            if [ $? -ne 0 ]
            then
                # semaphore/mutex (directory) exists already: a parallel job is currently downloading the same data for a reuse
                # wait for that job to finish the download before skipping the own download
                # wait max 60 * 10 seconds = 10 minutes

                loops=100
                echo $(date "+%Y-%m-%d %H:%M:%S") "Another job is downloading the data in parallel, waiting for the completion"
                while [ -d $OSM_XML_FILE_ABSOLUTE.lock ]
                do
                    if [ $loops -le 0 ]
                    then
                        echo $(date "+%Y-%m-%d %H:%M:%S") "... waited too long for the completion"
                        break
                    fi
                    sleep 10
                    loops=$(( loops -1))
                done
                if [ $loops -gt 0 ]
                then
                    echo $(date "+%Y-%m-%d %H:%M:%S") "... proceeding without own download"
                fi
            else
                rm -f $OSM_XML_FILE_ABSOLUTE
                if [ -n "$PTNA_OVERPASS_API_SERVER" ]
                then
                    if [ $(echo "$OVERPASS_QUERY" | fgrep -c 'poly:') -eq 0 ]
                    then
                        # the alternative Overpass-API server has some problems with areas defined by a polygon and needs a larger timeout value than the default (180)
                        OVERPASS_QUERY=$(echo $OVERPASS_QUERY | \
                                        sed -e "s/overpass-api\.de/$PTNA_OVERPASS_API_SERVER/" \
                                            -e 's/http:/https:/'                               \
                                            -e 's/data=area/data=[timeout:900];area/')
                        echo $(date "+%Y-%m-%d %H:%M:%S") "Overpass-API Query changed to '$OVERPASS_QUERY'"
                    fi
                fi

                START_DOWNLOAD=$(date "+%Y-%m-%d %H:%M:%S %Z")
                start=$(date --utc "+%s")
                DOWNLOAD_TRIES=1
                wget $CALL_PARAMS --user-agent="PTNA script on https://ptna.openstreetmap.de" "$OVERPASS_QUERY" -O $OSM_XML_FILE_ABSOLUTE.part.$$
                wget_ret=$?
                END_DOWNLOAD=$(date "+%Y-%m-%d %H:%M:%S %Z")
                stop=$(date --utc "+%s")
                echo $(date "+%Y-%m-%d %H:%M:%S") "wget returns $wget_ret"

                fsize=$(stat -c '%s' $OSM_XML_FILE_ABSOLUTE.part.$$)
                if [ "$fsize" -gt 0 ]
                then
                    if [ "$fsize" -ge 1000 ]
                    then
                        echo $(date "+%Y-%m-%d %H:%M:%S") "File '$OSM_XML_FILE_ABSOLUTE' first 10 lines:"
                        head -10 $OSM_XML_FILE_ABSOLUTE.part.$$
                        OSM_BASE=$(head -10 $OSM_XML_FILE_ABSOLUTE.part.$$ | fgrep -m 1 '<meta osm_base' | sed -e 's/^.*osm_base="//' -e 's/".*$//')
                        if [ -n "$OSM_BASE" ]
                        then
                            OSM_BASE=$(date --date "$OSM_BASE" "+%Y-%m-%d %H:%M:%S %Z")

                            OSM_BASE_SEC=$(date --utc --date "$OSM_BASE" "+%s")
                            NOW_SEC=$(date --utc "+%s")
                            OSM_AGE=$(( $NOW_SEC - $OSM_BASE_SEC ))
                            MAX_AGE=$(( 6 * 3600 ))
                            if [ $OSM_AGE -gt $MAX_AGE ]
                            then
                                echo $(date "+%Y-%m-%d %H:%M:%S") "OSM ($OSM_BASE) data is quite old : older than 6 hours"
                                echo $(date "+%Y-%m-%d %H:%M:%S") "Simulating failure for '$OSM_XML_FILE_ABSOLUTE': zero size"
                                sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO download (id,start,stop,wget_ret,success,attempt,size,osm_data) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,$wget_ret,0,1,$fsize,$OSM_BASE_SEC);"
                                rm    $OSM_XML_FILE_ABSOLUTE.part.$$
                                touch $OSM_XML_FILE_ABSOLUTE.part.$$
                            else
                                sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO download (id,start,stop,wget_ret,success,attempt,size,osm_data) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,$wget_ret,1,1,$fsize,$OSM_BASE_SEC);"
                            fi
                        fi
                    else
                        echo $(date "+%Y-%m-%d %H:%M:%S") "File '$OSM_XML_FILE_ABSOLUTE' is quite small: error during download?"
                        sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO download (id,start,stop,wget_ret,success,attempt,size,osm_data) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,$wget_ret,0,1,$fsize,0);"
                        cat $OSM_XML_FILE_ABSOLUTE.part.$$
                        echo $(date "+%Y-%m-%d %H:%M:%S") "Simulating failure for '$OSM_XML_FILE_ABSOLUTE': zero size"
                        rm    $OSM_XML_FILE_ABSOLUTE.part.$$
                        touch $OSM_XML_FILE_ABSOLUTE.part.$$
                    fi
                else
                    echo $(date "+%Y-%m-%d %H:%M:%S") "Failure for wget for '$PREFIX'"
                    sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO download (id,start,stop,wget_ret,success,attempt,size,osm_data) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,$wget_ret,0,1,$fsize,0);"
                fi

                fsize=$(stat -c '%s' $OSM_XML_FILE_ABSOLUTE.part.$$)
                if [ "$fsize" -eq 0 ]
                then
                    echo $(date "+%Y-%m-%d %H:%M:%S") "Calling wget for '$PREFIX' a second time in 1 minute"
                    # try a second, but only a second time
                    sleep 60
                    START_DOWNLOAD=$(date "+%Y-%m-%d %H:%M:%S %Z")
                    start=$(date --utc "+%s")
                    DOWNLOAD_TRIES=2
                    wget $CALL_PARAMS --user-agent="PTNA script on https://ptna.openstreetmap.de" "$OVERPASS_QUERY" -O $OSM_XML_FILE_ABSOLUTE.part.$$
                    wget_ret=$?
                    END_DOWNLOAD=$(date "+%Y-%m-%d %H:%M:%S %Z")
                    stop=$(date --utc "+%s")
                    echo $(date "+%Y-%m-%d %H:%M:%S") "wget returns $wget_ret"

                    fsize=$(stat -c '%s' $OSM_XML_FILE_ABSOLUTE.part.$$)
                    if [ "$fsize" -gt 0 ]
                    then
                        if [ "$fsize" -ge 1000 ]
                        then
                            echo $(date "+%Y-%m-%d %H:%M:%S") "File '$OSM_XML_FILE_ABSOLUTE' first 10 lines:"
                            head -10 $OSM_XML_FILE_ABSOLUTE.part.$$
                            OSM_BASE=$(head -10 $OSM_XML_FILE_ABSOLUTE.part.$$ | fgrep -m 1 '<meta osm_base' | sed -e 's/^.*osm_base="//' -e 's/".*$//')
                            if [ -n "$OSM_BASE" ]
                            then
                                OSM_BASE=$(date --date "$OSM_BASE" "+%Y-%m-%d %H:%M:%S %Z")

                                OSM_BASE_SEC=$(date --utc --date "$OSM_BASE" "+%s")
                                NOW_SEC=$(date --utc "+%s")
                                OSM_AGE=$(( $NOW_SEC - $OSM_BASE_SEC ))
                                MAX_AGE=$(( 6 * 3600 ))
                                if [ $OSM_AGE -gt $MAX_AGE ]
                                then
                                    echo $(date "+%Y-%m-%d %H:%M:%S") "OSM ($OSM_BASE) data is quite old : older than 6 hours"
                                    echo $(date "+%Y-%m-%d %H:%M:%S") "Simulating failure for '$OSM_XML_FILE_ABSOLUTE': zero size"
                                    sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO retry_download (id,start,stop,wget_ret,success,attempt,size,osm_data) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,$wget_ret,0,$DOWNLOAD_TRIES,$fsize,$OSM_BASE_SEC);"
                                    rm    $OSM_XML_FILE_ABSOLUTE.part.$$
                                    touch $OSM_XML_FILE_ABSOLUTE.part.$$
                                else
                                    sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO retry_download (id,start,stop,wget_ret,success,attempt,size,osm_data) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,$wget_ret,1,$DOWNLOAD_TRIES,$fsize,$OSM_BASE_SEC);"
                                fi
                            fi
                        else
                            echo $(date "+%Y-%m-%d %H:%M:%S") "File '$OSM_XML_FILE_ABSOLUTE' is quite small: error during download?"
                            sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO retry_download (id,start,stop,wget_ret,success,attempt,size,osm_data) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,$wget_ret,0,$DOWNLOAD_TRIES,$fsize,0);"
                            cat $OSM_XML_FILE_ABSOLUTE.part.$$
                            echo $(date "+%Y-%m-%d %H:%M:%S") "Simulating failure for '$OSM_XML_FILE_ABSOLUTE': zero size"
                            rm    $OSM_XML_FILE_ABSOLUTE.part.$$
                            touch $OSM_XML_FILE_ABSOLUTE.part.$$
                        fi
                    else
                        echo $(date "+%Y-%m-%d %H:%M:%S") "Failure for wget for '$PREFIX'"
                        sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO retry_download (id,start,stop,wget_ret,success,attempt,size,osm_data) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,$wget_ret,0,$DOWNLOAD_TRIES,$fsize,0);"
                    fi
                fi

                mv $OSM_XML_FILE_ABSOLUTE.part.$$ $OSM_XML_FILE_ABSOLUTE
                echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $OSM_XML_FILE_ABSOLUTE)
                rmdir $OSM_XML_FILE_ABSOLUTE.lock
            fi
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") "Work dir $OSM_XML_LOC does not exist/could not be created"
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "Work dir $WORK_LOC does not exist/could not be created"
    fi
fi

#
#
#

if [ "$getroutes" = "true" ]
then
    if [ -d "$WORK_LOC" ]
    then
        start=$(date --utc "+%s")

        rm -f "$WORK_LOC/$ROUTES_FILE"
        if [ -n "$WIKI_ROUTES_PAGE" ]
        then
            location="$WIKI_ROUTES_PAGE"
            echo $(date "+%Y-%m-%d %H:%M:%S") "Reading Routes Wiki page '$WIKI_ROUTES_PAGE' to file '$WORK_LOC/$ROUTES_FILE'"
            log=$(ptna-wiki-page.pl --pull --page=$WIKI_ROUTES_PAGE --file=$WORK_LOC/$ROUTES_FILE 2>&1)
            ret=$?
            echo $log | sed -e 's/ \([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] \)/\n\1/g'
            echo $(date "+%Y-%m-%d %H:%M:%S") "ptna-wiki-page.pl returned $ret"
            if [ -f "$WORK_LOC/$ROUTES_FILE" ]
            then
                ROUTES_SIZE="$(stat -c '%s' $WORK_LOC/$ROUTES_FILE)"
                ROUTES_TIMESTAMP_UTC="$(echo $log | fgrep "timestamp =" | sed -e 's/.*timestamp\s*=\s*\(20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z\).*/\1/')"
                ROUTES_TIMESTAMP_LOC="$(date --date "$ROUTES_TIMESTAMP_UTC" '+%Y-%m-%d %H:%M:%S %Z' | sed -e 's/ \([+-][0-9]*\)$/ UTC\1/')"
                modified="$(date --utc --date "$ROUTES_TIMESTAMP_UTC" '+%s')"
                echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $WORK_LOC/$ROUTES_FILE)
            else
                ROUTES_SIZE=-1
                modified=0
                echo $(date "+%Y-%m-%d %H:%M:%S") "Downloading '$ROUTES_FILE' failed"
            fi
        else
            location=""$SETTINGS_DIR/$ROUTES_FILE""
            if [ -f "$SETTINGS_DIR/$ROUTES_FILE" ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S") "'$ROUTES_FILE' provided by GitHub, copy to $WORK_LOC"
                cp $SETTINGS_DIR/$ROUTES_FILE $WORK_LOC/$ROUTES_FILE
                ret=$?
                ROUTES_SIZE="$(stat -c '%s' $WORK_LOC/$ROUTES_FILE)"
                ROUTES_TIMESTAMP_UTC="$(stat -c '%y' $SETTINGS_DIR/$ROUTES_FILE)"
                ROUTES_TIMESTAMP_LOC="$(date --date "$ROUTES_TIMESTAMP_UTC" '+%Y-%m-%d %H:%M:%S %Z' | sed -e 's/ \([+-][0-9]*\)$/ UTC\1/')"
                modified="$(date --utc --date "$ROUTES_TIMESTAMP_UTC" '+%s')"
                echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $WORK_LOC/$ROUTES_FILE)
            else
                ROUTES_SIZE=0
                modified=0
                ret=0
                echo $(date "+%Y-%m-%d %H:%M:%S") "no file: '$ROUTES_FILE'"
            fi
        fi
        stop=$(date --utc "+%s")
        sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO routes (id,start,stop,ret,modified,location,size) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,$ret,$modified,'$location',$ROUTES_SIZE);"
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "Work dir $WORK_LOC does not exist/could not be created"
    fi
fi

#
#
#

if [ "$modify" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Modifying Routes Data"

    if [ -d "$WORK_LOC" ]
    then
        if [ -n "$WIKI_ROUTES_PAGE" ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S") "Reading Routes Wiki page '$WIKI_ROUTES_PAGE' to file '$WORK_LOC/$ROUTES_FILE'"
            ptna-wiki-page.pl --pull --page=$WIKI_ROUTES_PAGE --file=$WORK_LOC/$ROUTES_FILE
            echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $WORK_LOC/$ROUTES_FILE)

            # put the code to modify the data here (sed, awk, perl, ... calls)

            #sed -i -e 's/ref;type;comment;from;to;operator;gtfs-feed;gtfs-route-id/&;gtfs-release-date/' $WORK_LOC/$ROUTES_FILE

            #sed -i -e 's/Hinweis auf eine "route_id" in den GTFS-Daten, die zu dieser Line gehört/&\n#\n# gtfs-release-date kann leer sein\n#                       == Hinweis auf eine spezielle Version der GTFS-Daten, die zu dieser Linie gehört (z.B. "2020-05-15")/' $WORK_LOC/$ROUTES_FILE

            #sed -i -e 's/Reference to a "route_id" in the GTFS data that belongs to this route/&\n#\n# gtfs-release-date can be empty\n#                       == Reference to special release of the GTFS data (e.g.: "2020-08-18")/' $WORK_LOC/$ROUTES_FILE

            #sed -i -e 's/Référence à un "route_id" dans les données GTFS qui appartient à cette route/&\n#\n# gtfs-release-date peut être vide\n#                       == Référence à une version spécial des données GTFS (par example : "2020-08-18")/' $WORK_LOC/$ROUTES_FILE

            # end of code here

            echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $WORK_LOC/$ROUTES_FILE)
        else
            if [ -f "$SETTINGS_DIR/$ROUTES_FILE" ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S") "'$ROUTES_FILE' provided by GitHub,"
                echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $SETTINGS_DIR/$ROUTES_FILE)

                # put the code to modify the data here (sed, awk, perl, ... calls)

                #sed -i -e 's/ref;type;comment;from;to;operator;gtfs-feed;gtfs-route-id/&;gtfs-release-date/' $SETTINGS_DIR/$ROUTES_FILE

                #sed -i -e 's/Hinweis auf eine "route_id" in den GTFS-Daten, die zu dieser Line gehört/&\n#\n# gtfs-release-date kann leer sein\n#                       == Hinweis auf eine spezielle Version der GTFS-Daten, die zu dieser Linie gehört (z.B. "2020-05-15")/' $SETTINGS_DIR/$ROUTES_FILE

                #sed -i -e 's/Reference to a "route_id" in the GTFS data that belongs to this route/&\n#\n# gtfs-release-date can be empty\n#                       == Reference to special release of the GTFS data (e.g.: "2020-08-18")/' $SETTINGS_DIR/$ROUTES_FILE

                #sed -i -e 's/Référence à un "route_id" dans les données GTFS qui appartient à cette route/&\n#\n# gtfs-release-date peut être vide\n#                       == Référence à une version spécial des données GTFS (par example : "2020-08-18")/' $SETTINGS_DIR/$ROUTES_FILE

                # end of code here

                echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $SETTINGS_DIR/$ROUTES_FILE)
            else
                echo $(date "+%Y-%m-%d %H:%M:%S") "no file: '$ROUTES_FILE'"
            fi
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "Work dir $WORK_LOC does not exist/could not be created"
    fi

fi

#
#
#

if [ "$gettalk" = "true" ]
then
    if [ -d "$WORK_LOC" ]
    then
        if [ -n "$ANALYSIS_TALK" ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S") "Reading Analysis Talk Wiki page '$ANALYSIS_TALK' to file '$WORK_LOC/$TALK_FILE'"
            ptna-wiki-page.pl --pull --page=$ANALYSIS_TALK --file=$WORK_LOC/$TALK_FILE
            echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $WORK_LOC/$TALK_FILE)
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "Work dir $WORK_LOC does not exist/could not be created"
    fi
fi

#
#
#

if [ "$analyze" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S")  "Analyze $PREFIX"

    if [ -d "$WORK_LOC" ]
    then
        if [ -f $OSM_XML_FILE_ABSOLUTE ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $OSM_XML_FILE_ABSOLUTE)

            if [ -s $OSM_XML_FILE_ABSOLUTE ]
            then
                rm -f $WORK_LOC/$DIFF_FILE.diff

                if [ -f "$WORK_LOC/$HTML_FILE" -a -s "$WORK_LOC/$HTML_FILE" ]
                then
                    mv $WORK_LOC/$HTML_FILE $WORK_LOC/$SAVE_FILE
                fi
                start=$(date --utc "+%s")
                START_ANALYSIS=$(date --date @$start "+%Y-%m-%d %H:%M:%S %Z")
                ptna-routes.pl --v\
                                --title="$PREFIX" \
                                --network-guid=$PREFIX \
                                $ANALYSIS_OPTIONS \
                                --expect-network-short-as="$EXPECT_NETWORK_SHORT_AS" \
                                --expect-network-short-for="$EXPECT_NETWORK_SHORT_FOR" \
                                --expect-network-long-as="$EXPECT_NETWORK_LONG_AS" \
                                --expect-network-long-for="$EXPECT_NETWORK_LONG_FOR" \
                                --network-long-regex="$NETWORK_LONG" \
                                --network-short-regex="$NETWORK_SHORT" \
                                --operator-regex="$OPERATOR_REGEX" \
                                --routes-file=$WORK_LOC/$ROUTES_FILE \
                                --osm-xml-file=$OSM_XML_FILE_ABSOLUTE \
                                2>&1 > $WORK_LOC/$HTML_FILE | tee $WORK_LOC/$HTML_FILE.log
                stop=$(date --utc "+%s")
                END_ANALYSIS=$(date --date @$stop "+%Y-%m-%d %H:%M:%S %Z")

                if [ -s "$WORK_LOC/$HTML_FILE" ]
                then
                    echo $(date "+%Y-%m-%d %H:%M:%S") "Analysis succeeded, '$WORK_LOC/$HTML_FILE' created"
                    echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $WORK_LOC/$HTML_FILE)

                    if [ -f "$WORK_LOC/$SAVE_FILE" -a -s "$WORK_LOC/$SAVE_FILE" ]
                    then
                        diff $WORK_LOC/$SAVE_FILE $WORK_LOC/$HTML_FILE > $WORK_LOC/$DIFF_FILE
                        echo $(date "+%Y-%m-%d %H:%M:%S") "Diff size:  " $(ls -l $WORK_LOC/$DIFF_FILE | awk '{print $5 " " $9}')
                        echo $(date "+%Y-%m-%d %H:%M:%S") "Diff lines: " $(wc -l $WORK_LOC/$DIFF_FILE)
                    else
                        rm -f $WORK_LOC/$SAVE_FILE
                    fi
                else
                    echo $(date "+%Y-%m-%d %H:%M:%S") "'$WORK_LOC/$HTML_FILE' is empty"
                fi
                size="$(stat -c '%s' $WORK_LOC/$HTML_FILE)"
                sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO analysis (id,start,stop,size) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,$size);"
            else
                echo $(date "+%Y-%m-%d %H:%M:%S") "'$OSM_XML_FILE_ABSOLUTE' is empty"
                if [ -f "$WORK_LOC/$HTML_FILE" ]
                then
                    echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $WORK_LOC/$HTML_FILE)
                fi
            fi
         else
            echo $(date "+%Y-%m-%d %H:%M:%S") "'$OSM_XML_FILE_ABSOLUTE' does not exist"
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "Work dir $WORK_LOC does not exist/could not be created"
    fi
fi

#
#
#

if [ "$updateresult" = "true" ]
then
    if [ -d "$WORK_LOC" ]
    then
        RESULTS_LOC="$PTNA_TARGET_LOC/$PTNA_RESULTS_LOC/$SUB_DIR"

        echo $(date "+%Y-%m-%d %H:%M:%S") "Creating analysis details file '$WORK_LOC/$DETAILS_FILE'"
        echo "REGION_NAME=$PTNA_WWW_REGION_NAME"                            >  $WORK_LOC/$DETAILS_FILE
        echo "REGION_LINK=$PTNA_WWW_REGION_LINK"                            >> $WORK_LOC/$DETAILS_FILE
        echo "NETWORK_NAME=$PTNA_WWW_NETWORK_NAME"                          >> $WORK_LOC/$DETAILS_FILE
        echo "NETWORK_LINK=$PTNA_WWW_NETWORK_LINK"                          >> $WORK_LOC/$DETAILS_FILE
        echo "DISCUSSION_NAME=$PTNA_WWW_DISCUSSION_NAME"                    >> $WORK_LOC/$DETAILS_FILE
        echo "DISCUSSION_LINK=$PTNA_WWW_DISCUSSION_LINK"                    >> $WORK_LOC/$DETAILS_FILE
        echo "ROUTES_NAME=$PTNA_WWW_ROUTES_NAME"                            >> $WORK_LOC/$DETAILS_FILE
        echo "ROUTES_LINK=$PTNA_WWW_ROUTES_LINK"                            >> $WORK_LOC/$DETAILS_FILE
        echo "ROUTES_SIZE=$ROUTES_SIZE"                                     >> $WORK_LOC/$DETAILS_FILE
        echo "ROUTES_TIMESTAMP_UTC=$ROUTES_TIMESTAMP_UTC"                   >> $WORK_LOC/$DETAILS_FILE
        echo "ROUTES_TIMESTAMP_LOC=$ROUTES_TIMESTAMP_LOC"                   >> $WORK_LOC/$DETAILS_FILE
        echo "TZ=${PTNA_TIMEZONE}"                                          >> $WORK_LOC/$DETAILS_FILE
        echo "TZSHORT=$(TZ=${PTNA_TIMEZONE:-Europe/Berlin} date '+%Z')"     >> $WORK_LOC/$DETAILS_FILE
        echo "UTC=UTC$(TZ=${PTNA_TIMEZONE:-Europe/Berlin} date '+%:::z')"   >> $WORK_LOC/$DETAILS_FILE
        echo "OVERPASS_QUERY=$OVERPASS_QUERY"                               >> $WORK_LOC/$DETAILS_FILE
        echo "CALL_PARAMS=$CALL_PARAMS"                                     >> $WORK_LOC/$DETAILS_FILE
        echo "START_DOWNLOAD=$START_DOWNLOAD"                               >> $WORK_LOC/$DETAILS_FILE
        echo "END_DOWNLOAD=$END_DOWNLOAD"                                   >> $WORK_LOC/$DETAILS_FILE
        echo "DOWNLOAD_TRIES=$DOWNLOAD_TRIES"                               >> $WORK_LOC/$DETAILS_FILE
        if [ -f $OSM_XML_FILE_ABSOLUTE ]
        then
            echo "OSM_BASE=$OSM_BASE"                                                                          >> $WORK_LOC/$DETAILS_FILE
            echo "OSM_XML_FILE=$OSM_XML_FILE_ABSOLUTE"                                                         >> $WORK_LOC/$DETAILS_FILE
            echo "OSM_XML_FILE_SIZE=$(ls -s --format=single-column $OSM_XML_FILE_ABSOLUTE | awk '{print $1}')" >> $WORK_LOC/$DETAILS_FILE
            echo "OSM_XML_FILE_SIZE_BYTE=$(stat -c '%s' $OSM_XML_FILE_ABSOLUTE)"                               >> $WORK_LOC/$DETAILS_FILE
        fi
        echo "START_ANALYSIS=$START_ANALYSIS"            >> $WORK_LOC/$DETAILS_FILE
        echo "END_ANALYSIS=$END_ANALYSIS"                >> $WORK_LOC/$DETAILS_FILE
        echo "analysis-options=$ANALYSIS_OPTIONS"        >> $WORK_LOC/$DETAILS_FILE
        echo "expect-network-short-as=$EXPECT_NETWORK_SHORT_AS"    >> $WORK_LOC/$DETAILS_FILE
        echo "expect-network-short-for=$EXPECT_NETWORK_SHORT_FOR"  >> $WORK_LOC/$DETAILS_FILE
        echo "expect-network-long-as=$EXPECT_NETWORK_LONG_AS"      >> $WORK_LOC/$DETAILS_FILE
        echo "expect-network-long-for=$EXPECT_NETWORK_LONG_FOR"    >> $WORK_LOC/$DETAILS_FILE
        echo "network-long-regex=$NETWORK_LONG"          >> $WORK_LOC/$DETAILS_FILE
        echo "network-short-regex=$NETWORK_SHORT"        >> $WORK_LOC/$DETAILS_FILE
        echo "operator-regex=$OPERATOR_REGEX"            >> $WORK_LOC/$DETAILS_FILE

        echo $(date "+%Y-%m-%d %H:%M:%S")  "Updating '$WORK_LOC/$HTML_FILE' to '$RESULTS_LOC'"

        if [ -f $WORK_LOC/$HTML_FILE ]
        then
            if [ -s $WORK_LOC/$HTML_FILE ]
            then
                # DIFF_LINES_BASE defines how many diff lines we have to tollerate in order to skip the
                # different time strings of the analysis
                # only diffs in the analysis result count

                NEW_OSM_Base_Time="$(awk '/OSM-Base Time : .* UTC/ { print $4 "T" $5 "Z"; }' $WORK_LOC/$HTML_FILE)"
                NEW_Local_OSM_Base_Time="$(TZ=${PTNA_TIMEZONE:-Europe/Berlin} date --date "$NEW_OSM_Base_Time" '+%Y-%m-%d %H:%M:%S %Z' | sed -e 's/ \([+-][0-9]*\)$/ UTC\1/')"

                echo "NEW_DATE_UTC=$NEW_OSM_Base_Time"       >> $WORK_LOC/$DETAILS_FILE
                echo "NEW_DATE_LOC=$NEW_Local_OSM_Base_Time" >> $WORK_LOC/$DETAILS_FILE

                if [ $(echo $OVERPASS_QUERY | egrep -c '(data=area)|(data=\[timeout:[0-9]+\];area)') = 1 ]
                then
                    # Overpass-API query includes an area(...), so AREA Time is included in HTML
                    # this is the case for most 'network' analyzes
                    DIFF_LINES_BASE=8
                else
                    # Overpass-API query includes definition of a poly('...'), so no AREA Time is included in HTML
                    # this is the case for EU-Flixbus and one or two others
                    DIFF_LINES_BASE=4
                fi

                if [ ! -d "$RESULTS_LOC" ]
                then
                    echo $(date "+%Y-%m-%d %H:%M:%S") "Creating directory $RESULTS_LOC"
                    mkdir -p $RESULTS_LOC
                fi

                if [ -d "$RESULTS_LOC" ]
                then
                    start=$(date --utc "+%s")
                    echo $(date "+%Y-%m-%d %H:%M:%S")  "Copying '$RESULTS_LOC/$HTML_FILE' to '$WORK_LOC/$SAVE_FILE'"
                    if [ -f $RESULTS_LOC/$HTML_FILE ]
                    then
                        cp $RESULTS_LOC/$HTML_FILE $WORK_LOC/$SAVE_FILE
                    else
                        # if there is no *.html file on the Web server side, the we delete also the local *.save file, so that a copy will take place
                        rm -f $WORK_LOC/$SAVE_FILE
                    fi

                    if [ -f "$WORK_LOC/$SAVE_FILE" ]
                    then
                        OLD_OSM_Base_Time="$(awk '/OSM-Base Time : .* UTC/ { print $4 "T" $5 "Z"; }' $WORK_LOC/$SAVE_FILE)"
                        OLD_Local_OSM_Base_Time="$(TZ=${PTNA_TIMEZONE:-Europe/Berlin} date --date "$OLD_OSM_Base_Time" '+%Y-%m-%d %H:%M:%S %Z' | sed -e 's/ \([+-][0-9]*\)$/ UTC\1/')"

                        if [ "$NEW_OSM_Base_Time" = "$OLD_OSM_Base_Time" ]
                        then
                            # we analyzed the same XML data again, so every diff line counts
                            DIFF_LINES_BASE=0
                        fi

                        diff $WORK_LOC/$SAVE_FILE $WORK_LOC/$HTML_FILE > $WORK_LOC/$DIFF_FILE
                        DIFF_LINES=$(cat $WORK_LOC/$DIFF_FILE | wc -l)
                        echo $(date "+%Y-%m-%d %H:%M:%S") "Diff size:  " $(ls -l $WORK_LOC/$DIFF_FILE | awk '{print $5 " " $9}')
                        echo $(date "+%Y-%m-%d %H:%M:%S") "Diff lines: " $DIFF_LINES $WORK_LOC/$DIFF_FILE
                    else
                        DIFF_LINES=$(($DIFF_LINES_BASE + 1))
                        rm -f $WORK_LOC/$DIFF_FILE
                    fi

                    if [ "$DIFF_LINES" -gt "$DIFF_LINES_BASE" ]
                    then
                        echo $(date "+%Y-%m-%d %H:%M:%S")  "Copying '$WORK_LOC/$HTML_FILE' to '$RESULTS_LOC'"
                        cp $WORK_LOC/$HTML_FILE $RESULTS_LOC

                        if [ -n "$(which htmldiff.pl)" ]
                        then
                            if [ -f "$WORK_LOC/$SAVE_FILE" ]
                            then
                                htmldiff.pl -c $WORK_LOC/$SAVE_FILE $WORK_LOC/$HTML_FILE > $WORK_LOC/$DIFF_HTML_FILE
                                HTML_DIFF=$(fgrep -c 'class="diff-' $WORK_LOC/$DIFF_HTML_FILE)
                                echo $(date "+%Y-%m-%d %H:%M:%S") "HTML diff:  '$HTML_DIFF'"
                                echo "HTML_DIFF=$HTML_DIFF" >> $WORK_LOC/$DETAILS_FILE
                            else
                                htmldiff.pl -c $WORK_LOC/$HTML_FILE $WORK_LOC/$HTML_FILE > $WORK_LOC/$DIFF_HTML_FILE
                                HTML_DIFF=0
                            fi

                            echo $(date "+%Y-%m-%d %H:%M:%S") "Copying '$WORK_LOC/$DIFF_HTML_FILE' to '$RESULTS_LOC'"
                            cp $WORK_LOC/$DIFF_HTML_FILE $RESULTS_LOC

                            echo $(date "+%Y-%m-%d %H:%M:%S") "Updating analysis details file '$WORK_LOC/$DETAILS_FILE' old date = new"
                            echo "OLD_DATE_UTC=$NEW_OSM_Base_Time"       >> $WORK_LOC/$DETAILS_FILE
                            echo "OLD_DATE_LOC=$NEW_Local_OSM_Base_Time" >> $WORK_LOC/$DETAILS_FILE
                            echo "OLD_OR_NEW=new"                        >> $WORK_LOC/$DETAILS_FILE
                        else
                            echo $(date "+%Y-%m-%d %H:%M:%S") "no htmldiff.pl tool: no HTML-Diff Analysis page '$HTMLDIFF_FILE'"
                            HTML_DIFF=0

                            echo $(date "+%Y-%m-%d %H:%M:%S") "Updating analysis details file '$WORK_LOC/$DETAILS_FILE' old date = empty"
                            echo "OLD_DATE_UTC="  >> $WORK_LOC/$DETAILS_FILE
                            echo "OLD_DATE_LOC="  >> $WORK_LOC/$DETAILS_FILE
                            echo "OLD_OR_NEW=old" >> $WORK_LOC/$DETAILS_FILE
                        fi
                        stop=$(date --utc "+%s")
                        sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO updateresult (id,start,stop,updated,diff_lines,html_changes) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,1,$DIFF_LINES,$HTML_DIFF);"
                    else
                        echo $(date "+%Y-%m-%d %H:%M:%S") "No relevant changes on '$HTML_FILE'"

                        echo $(date "+%Y-%m-%d %H:%M:%S") "Updating analysis details file '$WORK_LOC/$DETAILS_FILE' old date = old"
                        echo "OLD_DATE_UTC=$OLD_OSM_Base_Time"       >> $WORK_LOC/$DETAILS_FILE
                        echo "OLD_DATE_LOC=$OLD_Local_OSM_Base_Time" >> $WORK_LOC/$DETAILS_FILE
                        echo "OLD_OR_NEW=old"                        >> $WORK_LOC/$DETAILS_FILE
                        stop=$(date --utc "+%s")
                        sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "INSERT INTO updateresult (id,start,stop,updated,diff_lines,html_changes) VALUES ($PTNA_NETWORK_DB_ID,$start,$stop,0,$DIFF_LINES,0);"
                    fi
                else
                    echo $(date "+%Y-%m-%d %H:%M:%S") "Target location $RESULTS_LOC does not exist/could not be created"
                fi
            else
                echo $(date "+%Y-%m-%d %H:%M:%S") $WORK_LOC/$HTML_FILE is empty
                echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $WORK_LOC/$HTML_FILE)
            fi
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") $WORK_LOC/$HTML_FILE does not exist
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "Work dir $WORK_LOC does not exist/could not be created"
    fi
fi

#
#
#

if [ "$pushroutes" = "true" ]
then
    if [ -n "$WIKI_ROUTES_PAGE" ]
    then
        if [ -f $WORK_LOC/$ROUTES_FILE ]
        then
            if [ -s $WORK_LOC/$ROUTES_FILE ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S") "Writing Routes file '$WORK_LOC/$ROUTES_FILE' to Wiki page '$WIKI_ROUTES_PAGE'"
                ptna-wiki-page.pl --push --page=$WIKI_ROUTES_PAGE --file=$WORK_LOC/$ROUTES_FILE --summary="update by PTNA"
            else
                echo $(date "+%Y-%m-%d %H:%M:%S") $WORK_LOC/$ROUTES_FILE is empty
            fi
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") $WORK_LOC/$ROUTES_FILE does not exist
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "'$ROUTES_FILE' stored in GitHub"
    fi
fi

#
#
#

if [ "$pushtalk" = "true" ]
then
    if [ -n "$ANALYSIS_TALK" ]
    then
        if [ -f $WORK_LOC/$TALK_FILE ]
        then
            if [ -s $WORK_LOC/$TALK_FILE ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S") "Writing Analysis Talk file '$WORK_LOC/$TALK_FILE' to Wiki page '$ANALYSIS_TALK'"
                ptna-wiki-page.pl --push --page=$ANALYSIS_TALK --file=$WORK_LOC/$TALK_FILE --summary="update by PTNA"
            else
                echo $(date "+%Y-%m-%d %H:%M:%S") $WORK_LOC/$TALK_FILE is empty
            fi
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") $WORK_LOC/$TALK_FILE does not exist
        fi
    fi
fi

#
#
#

if [ "$watchroutes" = "true" ]
then
    if [ -n "$WIKI_ROUTES_PAGE" ]
    then
        echo $(date "+%Y-%m-%d %H:%M:%S") "Setting 'watch' on Wiki page '$WIKI_ROUTES_PAGE'"
        ptna-wiki-page.pl --watch --page=$WIKI_ROUTES_PAGE
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "'$ROUTES_FILE' provided by GitHub"
    fi
fi

#
#
#

if [ "$watchtalk" = "true" ]
then
    if [ -n "$ANALYSIS_TALK" ]
    then
        echo $(date "+%Y-%m-%d %H:%M:%S") "Setting 'watch' on Wiki page '$ANALYSIS_TALK'"
        ptna-wiki-page.pl --watch --page=$ANALYSIS_TALK
    fi
fi

if [ -d "$WORK_LOC" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Handling Statistics DB $WORK_LOC/$STATISTICS_DB"

    sqlite3 $SQ_OPTIONS $WORK_LOC/$STATISTICS_DB "UPDATE ptna SET stop=$(date --utc '+%s') WHERE id=$PTNA_NETWORK_DB_ID;"

else
    echo $(date "+%Y-%m-%d %H:%M:%S") "Work dir $WORK_LOC does not exist/could not be created"
fi

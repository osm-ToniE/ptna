#!/bin/bash

# source $HOME/.ptna-config to set the variables
# and maybe to set some perl related variables (copied from .bashrc)

[ -f $HOME/.ptna-config ] && source $HOME/.ptna-config

# where can we find all the executables of PTNA

if [ -z "$PTNA_BIN" ]
then
    PTNA_BIN="$HOME/ptna/bin"
    export PATH="$PTNA_BIN:$HOME/bin:$PATH"
fi

# where can we find config files for osmium to split the planet file into pieces

PTNA_NETWORKS_LOC="${PTNA_NETWORKS_LOC:-/osm/ptna/ptna-networks}"

# we are working in PTNA_WORK_LOC

PTNA_WORK_LOC="${PTNA_WORK_LOC:-/osm/ptna/work}"

ANALYSIS_QUEUE="$PTNA_WORK_LOC/ptna-analysis-queue-sqlite.db"

EXECUTION_MUTEX="$PTNA_WORK_LOC/ptna-analysis-queue-sqlite-MUTEX.lock"

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start 'ptna-cron-analysis-queue.sh'"

mkdir $EXECUTION_MUTEX 2> /dev/null
if [ $? -ne 0 ]
then
    LOCKED_AT=$(stat -c "%w" $EXECUTION_MUTEX)
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Execution has been locked by another task using MUTEX '$EXECUTION_MUTEX', locked at '$LOCKED_AT'"
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "... terminating"
    exit 99
fi

# LOCKED_AT=$(stat -c "%w" $EXECUTION_MUTEX)
# echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Execution is now locked using MUTEX '$EXECUTION_MUTEX', locked at $LOCKED_AT"

###############################################################
#
# start working
#
###############################################################

SQ_OPTIONS="-init /dev/null -noheader -csv"

if [ ! -f "$ANALYSIS_QUEUE" ]
then
    sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "CREATE TABLE queue (id INTEGER DEFAULT 1 PRIMARY KEY, network TEXT DEFAULT '', status TEXT DEFAULT '', queued INTEGER DEFAULT 0, started INTEGER DEFAULT 0, finished INTEGER DEFAULT 0, changes INTEGER DEFAULT 0, ip TEXT DEFAULT '');"
    chmod 666 $ANALYSIS_QUEUE
    chmod 777 $(dirname $ANALYSIS_QUEUE)
fi

if [ -f $ANALYSIS_QUEUE ]
then
    sqlite3 $SQ_OPTIONS -header $ANALYSIS_QUEUE "SELECT id,network,status,queued,started,finished,changes FROM queue WHERE status='queued' OR status='started';"

    started_count=$(sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "SELECT COUNT(*) FROM queue WHERE status='started';")

    if [ $started_count -eq 0 ]
    then
        queue_count=$(sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "SELECT COUNT(*) FROM queue WHERE status='queued';")

        if [ $queue_count -gt 0 ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

            while [ $queue_count -gt 0 ]
            do
                id=$(sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "SELECT id FROM queue WHERE status='queued' ORDER BY queued ASC LIMIT 1;")
                if [ -n "$id" ]
                then
                    network=$(sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "SELECT network FROM queue WHERE id=$id;")

                    settings_dir=$(find $PTNA_NETWORKS_LOC -type d -name "$network")
                    if [ -n "$settings_dir" ]
                    then
                        sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "UPDATE queue SET status='started'      WHERE id=$id;"
                        sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "UPDATE queue SET started=$(date '+%s') WHERE id=$id;"

                        cd $settings_dir
                        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start 'ptna-network.sh -LcCoigau' for network '$network'"
                        ptna-network.sh -LcCoigau
                        ret_code=$?
                        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "'ptna-network.sh -LcCoigau' returned with '$ret_code'"

                        if [ $ret_code -eq 0 ]
                        then
                            sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "UPDATE queue SET status='outdated' WHERE network='$network' AND status='finished';"
                            sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "UPDATE queue SET status='finished'  WHERE id=$id;"
                            details_file=$(find $PTNA_WORK_LOC -type f -name "$network-Analysis-details.txt")
                            if [ -n "$details_file" ]
                            then
                                htmldiff=$(grep "HTML_DIFF" $details_file | sed -e 's/^.*=//' | egrep '^[0-9]+$')
                                if [ -n "$htmldiff" ]
                                then
                                    sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "UPDATE queue SET changes=$htmldiff WHERE id=$id;"
                                fi
                            fi
                        elif [ $ret_code -eq 99 ]
                        then
                            sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "UPDATE queue SET status='locked'           WHERE id=$id;"
                        else
                            sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "UPDATE queue SET status='failed $ret_code' WHERE id=$id;"
                        fi
                        sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "UPDATE queue SET finished=$(date '+%s') WHERE id=$id;"
                    else
                        sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "UPDATE queue SET status='failed dir'   WHERE id=$id;"
                    fi
                else
                    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "sqlite3 DB '$ANALYSIS_QUEUE' could not get 'id' of task to be started"
                    break
                fi
                queue_count=$(sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "SELECT COUNT(*) FROM queue WHERE status='queued';")
            done
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"
        fi
    else
        started=$(sqlite3 $SQ_OPTIONS $ANALYSIS_QUEUE "SELECT network FROM queue WHERE status='started';")
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Another task is analyzing 'network' = '$started'"
    fi
else
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "sqlite3 DB '$ANALYSIS_QUEUE' could not be created"
fi

if [ -d "$EXECUTION_MUTEX" ]
then
#    LOCKED_AT=$(stat -c "%w" $EXECUTION_MUTEX)
#    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Release MUTEX '$EXECUTION_MUTEX', has been locked at '$LOCKED_AT'"
    rmdir $EXECUTION_MUTEX
fi
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Stop 'ptna-cron-analysis-queue.sh'"

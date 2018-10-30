#!/bin/bash

#
# Public Transport Network Analysis of a single network
#

if [ -z "$PTNA_TARGET_LOC"     -o \
     -z "$PTNA_RESULTS_LOC"    -o \
     -z "$PTNA_WEB_HOST"       -o \
     -z "$PTNA_NETWORKS_LOC"   -o \
     -z "$PTNA_RESULTS_HTML"   -o \
     -z "$PTNA_WORK_LOC"            ]
then
    echo " ...unset global variable(s)"
    [ -z "$PTNA_TARGET_LOC"       ] && echo "Please specify: PTNA_TARGET_LOC as environment variable outside the tools"
    [ -z "$PTNA_RESULTS_LOC"      ] && echo "Please specify: PTNA_RESULTS_LOC as environment variable outside the tools"
    [ -z "$PTNA_WEB_HOST"         ] && echo "Please specify: PTNA_WEB_HOST as environment variable outside the tools"
    [ -z "$PTNA_RESULTS_HTML"     ] && echo "Please specify: PTNA_RESULTS_HTML as environment variable outside the tools"
    [ -z "$PTNA_NETWORKS_LOC"     ] && echo "Please specify: PTNA_NETWORKS_LOC as environment variable outside the tools"
    [ -z "$PTNA_WORK_LOC"         ] && echo "Please specify: PTNA_WORK_LOC as environment variable outside the tools"
    echo "... terminating"
    exit 1
fi


SETTINGS_DIR="."


TEMP=$(getopt -o acghoOpuwS --long analyze,clean,get-routes,help,overpass-query,overpass-query-on-zero-xml,push-routes,update-result,watch-routes,settings-dir -n 'ptna-network.sh' -- "$@")

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 2 ; fi

eval set -- "$TEMP"

while true ; do
    case "$1" in
        -a|--analyze)                       analyze=true                ; shift ;;
        -c|--clean)                         clean=true                  ; shift ;;
        -g|--get-routes)                    getroutes=true              ; shift ;;
        -h|--help)                          help=true                   ; shift ;;
        -o|--overpass-query)                overpassquery=true  ; overpassqueryonzeroxml=false ; shift ;;
        -O|--overpass-query-on-zero-xml)    overpassqueryonzeroxml=true  ; overpassquery=false ; shift ;;
        -p|--push-routes)                   pushroutes=true             ; shift ;;
        -u|--update-result)                 updateresult=true           ; shift ;;
        -w|--watch-routes)                  watchroutes=true            ; shift ;;
        -S|--settings_dir)                  shift; SETTINGS_DIR=$1      ; shift ;;
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


if [ -z "$PREFIX"              -o \
     -z "$OVERPASS_QUERY"      -o \
     -z "$WIKI_ROUTES_PAGE"    -o \
     -z "$ANALYSIS_OPTIONS"    -o \
     -z "$WIKI_ROUTES_PAGE"         ]
then
    echo "$SETTINGS_DIR/settings.sh file: unset variables(s)"
    [ -z "$PREFIX"           ] && echo "Please specify: PREFIX"
    [ -z "$OVERPASS_QUERY"   ] && echo "Please specify: OVERPASS_QUERY"
    [ -z "$ANALYSIS_OPTIONS" ] && echo "Please specify: ANALYSIS_OPTIONS"
    [ -z "$WIKI_ROUTES_PAGE" ] && echo "Please specify: WIKI_ROUTES_PAGE"
    echo "... terminating"
    exit 5
fi

# on the web and in the work directory, the data will be stored in sub-directories
# PREFIX=DE-BY-MVV --> stored in DE/BY/

SUB_DIR="${PREFIX%-*}"
SUB_DIR="${SUB_DIR//-//}"

WEB_LOC="$PTNA_SUB_DIR"
[ -n "$PTNA_WEB_BASE_LOC" ] && WEB_LOC="$PTNA_WEB_BASE_LOC/$WEB_LOC"

WORK_LOC="$PTNA_WORK_LOC/$SUB_DIR"

RESULTS_LOC="$PTNA_TARGET_LOC/$PTNA_RESULTS_LOC/$SUB_DIR"

ROUTES_FILE="$PREFIX-Routes.txt"
SETTINGS_FILE="settings.sh"

OSM_XML_FILE="$PREFIX-Data.xml"
HTML_FILE="$PREFIX-Analysis.html"
DIFF_FILE="$PREFIX-Analysis.html.diff"
DIFF_HTML_FILE="$PREFIX-Analysis.diff.html"
SAVE_FILE="$PREFIX-Analysis.html.save"


#
# 
#

if [ "$clean" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Removing temporary files"
    rm -f $WORK_LOC/$OSM_XML_FILE $WORK_LOC/$HTML_FILE $WORK_LOC/$DIFF_FILE $WORK_LOC/$DIFF_HTML_FILE $WORK_LOC/$SAVE_FILE
fi

#
# 
#

if [ "$overpassqueryonzeroxml" = "true" ]
then
    if [ -f $WORK_LOC/$OSM_XML_FILE -a -s $WORK_LOC/$OSM_XML_FILE ]
    then
        echo $(date "+%Y-%m-%d %H:%M:%S") "File '$WORK_LOC/$OSM_XML_FILE' exists, no further analysis required, terminating"
        exit 0
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "File '$WORK_LOC/$OSM_XML_FILE' does not exist or is empty, starting download"
        overpassquery="true"
    fi
fi

#
# 
#

if [ "$overpassquery" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Calling wget for '$PREFIX'"
    
    if [ ! -d "$WORK_LOC" ] 
    then
        echo $(date "+%Y-%m-%d %H:%M:%S") "Creating directory $WORK_LOC"
        mkdir -p $WORK_LOC
    fi
       
    if [ -d "$WORK_LOC" ]
    then
        wget "$OVERPASS_QUERY" -O $WORK_LOC/$OSM_XML_FILE
        echo $(date "+%Y-%m-%d %H:%M:%S") "wget returns $?"
        
        if [ -s $WORK_LOC/$OSM_XML_FILE ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S") "Success for wget for '$PREFIX'"
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") "Calling wget for '$PREFIX' a second time"
            # try a second, but only a second time
            sleep 60    
            wget "$OVERPASS_QUERY" -O $WORK_LOC/$OSM_XML_FILE
            echo $(date "+%Y-%m-%d %H:%M:%S") "wget returns $?"
            
            if [ -s $WORK_LOC/$OSM_XML_FILE ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S") "Success for wget for '$PREFIX'"
            else
                echo $(date "+%Y-%m-%d %H:%M:%S") "Failure for wget for '$PREFIX'"
            fi
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
    echo $(date "+%Y-%m-%d %H:%M:%S") "Reading Routes Wiki page '$WIKI_ROUTES_PAGE' to file '$SETTINGS_DIR/$ROUTES_FILE'"
    ptna-wiki-page.pl --pull --page=$WIKI_ROUTES_PAGE --file=$SETTINGS_DIR/$ROUTES_FILE
    echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $SETTINGS_DIR/$ROUTES_FILE)
fi

#
# 
#

if [ "$analyze" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S")  "Analyze $PREFIX"
    
    if [ -f $SETTINGS_DIR/$ROUTES_FILE -a -f $WORK_LOC/$OSM_XML_FILE ]
    then
        if [ -s $SETTINGS_DIR/$ROUTES_FILE -a -s $WORK_LOC/$OSM_XML_FILE ]
        then
            rm -f $WORK_LOC/$DIFF_FILE.diff

            if [ -f "$WORK_LOC/$HTML_FILE" -a -s "$WORK_LOC/$HTML_FILE" ]
            then
                mv $WORK_LOC/$HTML_FILE $WORK_LOC/$SAVE_FILE
            fi
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
                           --routes-file=$SETTINGS_DIR/$ROUTES_FILE \
                           --osm-xml-file=$WORK_LOC/$OSM_XML_FILE \
                           > $WORK_LOC/$HTML_FILE
    
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
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") "'$SETTINGS_DIR/$ROUTES_FILE' or '$WORK_LOC/$OSM_XML_FILE' is empty"
            echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $WORK_LOC/$HTML_FILE)
       fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "'$SETTINGS_DIR/$ROUTES_FILE' or '$WORK_LOC/$OSM_XML_FILE' does not exist"
    fi
fi

#
# 
#

if [ "$updateresult" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S")  "Updating '$WORK_LOC$HTML_FILE' to '$RESULTS_LOC'"
    
    if [ -f $WORK_LOC/$HTML_FILE ]
    then 
        if [ -s $WORK_LOC/$HTML_FILE ]
        then
            if [ $(echo $OVERPASS_QUERY | fgrep -c 'data=area') = 1 ]
            then
                DIFF_LINES_BASE=8
            else
                DIFF_LINES_BASE=4
            fi
            
            if [ ! -d "$RESULTS_LOC" ] 
            then
                echo $(date "+%Y-%m-%d %H:%M:%S") "Creating directory $RESULTS_LOC"
                mkdir -p $RESULTS_LOC
            fi
               
            if [ -d "$RESULTS_LOC" ]
            then
            
                echo $(date "+%Y-%m-%d %H:%M:%S")  "Copying '$RESULTS_LOC/$HTML_FILE' to '$WORK_LOC/$SAVE_FILE'"
                if [ -f $RESULTS_LOC/$HTML_FILE ]
                then
                    cp $RESULTS_LOC/$HTML_FILE $WORK_LOC/$SAVE_FILE
                fi
    
                if [ -f "$WORK_LOC/$SAVE_FILE" ]
                then
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
                        if [ -f "$WORK_LOC/$DIFF_FILE" ]
                        then
                            htmldiff.pl -c $WORK_LOC/$SAVE_FILE $WORK_LOC/$HTML_FILE > $WORK_LOC/$DIFF_HTML_FILE 
                        else
                            htmldiff.pl -c $WORK_LOC/$HTML_FILE $WORK_LOC/$HTML_FILE > $WORK_LOC/$DIFF_HTML_FILE 
                        fi
    
                        echo $(date "+%Y-%m-%d %H:%M:%S") "Copying '$WORK_LOC/$DIFF_HTML_FILE' to '$RESULTS_LOC'"
                        cp $WORK_LOC/$DIFF_HTML_FILE $RESULTS_LOC
    
                        if [ -n "$PTNA_RESULTS_HTML" -a -f "$PTNA_TARGET_LOC/$PTNA_RESULTS_HTML" ]
                        then
                            echo $(date "+%Y-%m-%d %H:%M:%S") "Updating results HTML file '$PTNA_TARGET_LOC/$PTNA_RESULTS_HTML'"
                            
                            NEW_OSM_Base_Time="$(awk '/OSM-Base Time : .* UTC/ { print $4 "T" $5 "Z"; }' $WORK_LOC/$HTML_FILE)"
                            NEW_Local_OSM_Base_Time="$(date --date="$NEW_OSM_Base_Time" '+%d.%m.%Y %H:%M:%S')"
    
                            sed -i -e "s/^\(.*$PREFIX-datadate.*\)<time .*\(<.time>.*\)$/\1<time datetime='$NEW_OSM_Base_Time'>$NEW_Local_OSM_Base_Time\2/" \
                                   -e "s/^\(.*$PREFIX-analyzed.*\)<time .*\(<.time>.*\)$/\1<time datetime='$NEW_OSM_Base_Time'>$NEW_Local_OSM_Base_Time\2/" \
                                   -e "s/^\(.*$PREFIX-analyzed.*class=.\)results-analyzed-...\(\".*\)$/\1results-analyzed-new\2/" \
                                   $PTNA_TARGET_LOC/$PTNA_RESULTS_HTML
                        fi
                    else
                        echo $(date "+%Y-%m-%d %H:%M:%S") "no htmldiff.pl tool: no HTML-Diff Analysis page '$HTMLDIFF_FILE'"
                        echo $(date "+%Y-%m-%d %H:%M:%S") "Updating results HTML file '$PTNA_TARGET_LOC/$PTNA_RESULTS_HTML'"

                        if [ -n "$PTNA_RESULTS_HTML" -a -f "$PTNA_TARGET_LOC/$PTNA_RESULTS_HTML" ]
                        then
                            NEW_OSM_Base_Time="$(awk '/OSM-Base Time : / { print $4 "T" $5 "Z"; }' $WORK_LOC/$HTML_FILE)"
                            NEW_Local_OSM_Base_Time="$(date --date="$NEW_OSM_Base_Time" '+%d.%m.%Y %H:%M:%S')"
    
                            sed -i -e "s/^\(.*$PREFIX-datadate.*\)<time .*\(<.time>.*\)$/\1<time datetime='$NEW_OSM_Base_Time'>$NEW_Local_OSM_Base_Time\2/" \
                                   -e "s/^\(.*$PREFIX-analyzed.*\)<a .*<.a>\(.*\)$/\1\&nbsp;\2/" \
                                   -e "s/^\(.*$PREFIX-analyzed.*class=.\)results-analyzed-...\(\".*\)$/\1results-analyzed-old\2/" \
                                   $PTNA_TARGET_LOC/$PTNA_RESULTS_HTML
                        fi
                    fi
                else
                    echo $(date "+%Y-%m-%d %H:%M:%S") "No relevant changes on '$HTML_FILE'"
                    echo $(date "+%Y-%m-%d %H:%M:%S") "Updating results HTML file '$PTNA_TARGET_LOC/$PTNA_RESULTS_HTML'"

                    if [ -n "$PTNA_RESULTS_HTML" -a -f "$PTNA_TARGET_LOC/$PTNA_RESULTS_HTML" ]
                    then
                        NEW_OSM_Base_Time="$(awk '/OSM-Base Time : / { print $4 "T" $5 "Z"; }' $WORK_LOC/$HTML_FILE)"
                        NEW_Local_OSM_Base_Time="$(date --date="$NEW_OSM_Base_Time" '+%d.%m.%Y %H:%M:%S')"
    
                        sed -i -e "s/^\(.*$PREFIX-datadate.*\)<time .*\(<.time>.*\)$/\1<time datetime='$NEW_OSM_Base_Time'>$NEW_Local_OSM_Base_Time\2/" \
                               -e "s/^\(.*$PREFIX-analyzed.*class=.\)results-analyzed-...\(\".*\)$/\1results-analyzed-old\2/" \
                               $PTNA_TARGET_LOC/$PTNA_RESULTS_HTML
                    fi
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
fi

#
# 
#

if [ "$pushroutes" = "true" ]
then
    if [ -f $ROUTES_FILE ]
    then
        if [ -s $ROUTES_FILE ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S") "Writing Routes file '$ROUTES_FILE' to Wiki page '$WIKI_ROUTES_PAGE'"
            ptna-wiki-page.pl --push --page=$WIKI_ROUTES_PAGE --file=$SETTINGS_DIR/$ROUTES_FILE --summary="update by PTNA"
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") $SETTINGS_DIR/$ROUTES_FILE is empty
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") $SETTINGS_DIR/$ROUTES_FILE does not exist
    fi
fi

#
# 
#

if [ "$watchroutes" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Setting 'watch' on Wiki page '$WIKI_ROUTES_PAGE'"
    ptna-wiki-page.pl --watch --page=$WIKI_ROUTES_PAGE
fi





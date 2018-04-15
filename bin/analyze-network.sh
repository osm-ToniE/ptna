#!/bin/bash

#
# analyze ÖPNV network and their routes
#

if [ -f settings.sh -a -r settings.sh ]
then
    . settings.sh              # source the settings.sh and 'import' shell variables
else
    echo "'settings.sh' file not found ... terminating"
    exit 1
fi

if [ -z "$PREFIX"              -o \
     -z "$OVERPASS_QUERY"      -o \
     -z "$ANALYSIS_PAGE"       -o \
     -z "$WIKI_ROUTES_PAGE"    -o \
     -z "$FILE_DIFF"           -o \
     -z "$TARGET_HOST"         -o \
     -z "$ANALYSIS_OPTIONS"        ]
then
    echo "'settings.sh' file: some variables are unset"
    echo "Please specify: PREFIX, OVERPASS_QUERY, ANALYSIS_PAGE, WIKI_ROUTES_PAGE, FILE_DIFF, TARGET_HOST, ANALYSIS_OPTIONS"
    echo "... terminating"
    exit 2
fi

ROUTES_FILE="$PREFIX-Routes.txt"
OSM_XML_FILE="$PREFIX-Data.xml"
HTML_FILE="$PREFIX-Analysis.html"

TARGET_LOC="analyze-routes"

#
# 
#

TEMP=$(getopt -o acghopuw --long analyze,clean,get-routes,help,overpass-query,push-routes,upload-result,watch-routes -n 'analyze-network.sh' -- "$@")

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"

while true ; do
    case "$1" in
        -a|--analyze)           analyze=true        ; shift ;;
        -c|--clean)             clean=true          ; shift ;;
        -g|--get-routes)        getroutes=true      ; shift ;;
        -h|--help)              help=true           ; shift ;;
        -o|--overpass-query)    overpassquery=true  ; shift ;;
        -p|--push-routes)       pushroutes=true     ; shift ;;
        -u|--upload-result)     uploadresult=true   ; shift ;;
        -w|--watch-routes)      watchroutes=true    ; shift ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

#
# 
#

if [ "$clean" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Removing temporary files"
    rm -f $OSM_XML_FILE $HTML_FILE $HTML_FILE.* xx*
fi

#
# 
#

if [ "$overpassquery" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Calling wget for '$PREFIX'"
    wget "$OVERPASS_QUERY" -O $OSM_XML_FILE
fi

#
# 
#

if [ "$getroutes" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Reading Routes Wiki page '$WIKI_ROUTES_PAGE' to file '$ROUTES_FILE'"
    wiki-page.pl --pull --page=$WIKI_ROUTES_PAGE --file=$ROUTES_FILE
    echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $ROUTES_FILE)
fi

#
# 
#

if [ "$analyze" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S")  "Analyze $PREFIX"
    
    if [ -f $ROUTES_FILE -a -f $OSM_XML_FILE ]
    then
        if [ -s $ROUTES_FILE -a -s $OSM_XML_FILE ]
        then
            rm -f $HTML_FILE.diff

            if [ -f "$HTML_FILE" -a -s "$HTML_FILE" ]
            then
                mv $HTML_FILE $HTML_FILE.save
            fi
            analyze-routes.pl --v\
                              $ANALYSIS_OPTIONS \
                              --expect-network-short-for="$EXPECT_NETWORK_SHORT_FOR" \
                              --expect-network-long-for="$EXPECT_NETWORK_LONG_FOR" \
                              --network-long-regex="$NETWORK_LONG" \
                              --network-short-regex="$NETWORK_SHORT" \
                              --operator-regex="$OPERATOR_REGEX" \
                              --routes-file=$ROUTES_FILE \
                              --osm-xml-file=$OSM_XML_FILE \
                              > $HTML_FILE
    
            if [ -s "$HTML_FILE" ]
            then
                if [ $(cat "$HTML_FILE" | fgrep -c '<!-- split here for table of contents -->') -eq 2 ]
                then
                    rm -f xx00 xx01 xx02
                    echo $(date "+%Y-%m-%d %H:%M:%S") "Inserting TOC into '$HTML_FILE'"
                    csplit --silent $HTML_FILE '/<!-- split here for table of contents -->/' '{1}'
                    if [ -f xx00 -a -f xx01 -a -f xx02 ]
                    then
                        cat xx00 xx02 xx01 | fgrep -v '<!-- split here for table of contents -->' > $HTML_FILE
                        rm -f xx*
                    fi
                fi 
                echo $(date "+%Y-%m-%d %H:%M:%S") "Analysis succeeded, '$HTML_FILE' created"
                echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $HTML_FILE)

                if [ -f "$HTML_FILE.save" -a -s "$HTML_FILE.save" ]
                then                
                    diff $HTML_FILE $HTML_FILE.save > $HTML_FILE.diff
                    echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $HTML_FILE.diff)
                else
                    rm -f $HTML_FILE.save
                fi
            else
                echo $(date "+%Y-%m-%d %H:%M:%S") "'$HTML_FILE' is empty"
            fi
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") "'$ROUTES_FILE' or '$OSM_XML_FILE' is empty"
            echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $HTML_FILE)
       fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "'$ROUTES_FILE' or '$OSM_XML_FILE' does not exist"
    fi
fi

#
# 
#

if [ "$uploadresult" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S")  "Upload '$HTML_FILE' to '$ANALYSIS_PAGE'"

    if [ -f $HTML_FILE ]
    then 
        if [ -s $HTML_FILE ]
        then
            if [ -f "$HTML_FILE.save" ]
            then
                diff $HTML_FILE $HTML_FILE.save > $HTML_FILE.diff
            
                echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $HTML_FILE.diff)
            
                diffsize=$(ls -l $HTML_FILE.diff 2> /dev/null | awk '{print $5}')
            else
                diffsize=100000
                rm -f $HTML_FILE.diff
            fi
        
            if [ "$diffsize" -gt "$FILE_DIFF" ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S") "Writing new Analysis page '$HTML_FILE'"
                echo -e "put $HTML_FILE $TARGET_LOC/\nchmod 644 $TARGET_LOC/$HTML_FILE" | sftp -b - $TARGET_HOST
            else
                echo $(date "+%Y-%m-%d %H:%M:%S") "No changes"
            fi
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") $HTML_FILE is empty
            echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $HTML_FILE)
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") $HTML_FILE does not exist
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
            wiki-page.pl --push --page=$WIKI_ROUTES_PAGE --file=$ROUTES_FILE --summary="update by analyze-routes"
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") $ROUTES_FILE is empty
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") $ROUTES_FILE does not exist
    fi
fi

#
# 
#

if [ "$watchroutes" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Setting 'watch' on Wiki page '$WIKI_ROUTES_PAGE'"
    wiki-page.pl --watch --page=$WIKI_ROUTES_PAGE
fi





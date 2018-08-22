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
     -z "$TARGET_LOC"         -o \
     -z "$ANALYSIS_OPTIONS"        ]
then
    [ -z "$TARGET_HOST"      ] && echo "Please specify: TARGET_HOST as environment variable outside the tools"
    [ -z "$TARGET_LOC"       ] && echo "Please specify: TARGET_LOC as environment variable outside the tools"
    echo "'settings.sh' file: unset variable(s)"
    [ -z "$PREFIX"           ] && echo "Please specify: PREFIX"
    [ -z "$OVERPASS_QUERY"   ] && echo "Please specify: OVERPASS_QUERY"
    [ -z "$ANALYSIS_PAGE"    ] && echo "Please specify: ANALYSIS_PAGE"
    [ -z "$WIKI_ROUTES_PAGE" ] && echo "Please specify: WIKI_ROUTES_PAGE"
    [ -z "$FILE_DIFF"        ] && echo "Please specify: FILE_DIFF"
    [ -z "$ANALYSIS_OPTIONS" ] && echo "Please specify: ANALYSIS_OPTIONS"
    echo "... terminating"
    exit 2
fi

ROUTES_FILE="$PREFIX-Routes.txt"
OSM_XML_FILE="$PREFIX-Data.xml"
HTML_FILE="$PREFIX-Analysis.html"

#
# 
#

TEMP=$(getopt -o acghoOpuw --long analyze,clean,get-routes,help,overpass-query,overpass-query-on-zero-xml,push-routes,upload-result,watch-routes -n 'analyze-network.sh' -- "$@")

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"

while true ; do
    case "$1" in
        -a|--analyze)                       analyze=true        ; shift ;;
        -c|--clean)                         clean=true          ; shift ;;
        -g|--get-routes)                    getroutes=true      ; shift ;;
        -h|--help)                          help=true           ; shift ;;
        -o|--overpass-query)                overpassquery=true  ; overpassqueryonzeroxml=false ; shift ;;
        -O|--overpass-query-on-zero-xml)    overpassqueryonzeroxml=true  ; overpassquery=false ; shift ;;
        -p|--push-routes)                   pushroutes=true     ; shift ;;
        -u|--upload-result)                 uploadresult=true   ; shift ;;
        -w|--watch-routes)                  watchroutes=true    ; shift ;;
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
    rm -f $OSM_XML_FILE $HTML_FILE $HTML_FILE.*
fi

#
# 
#

if [ "$overpassqueryonzeroxml" = "true" ]
then
    if [ -f $OSM_XML_FILE -a -s $OSM_XML_FILE ]
    then
        echo $(date "+%Y-%m-%d %H:%M:%S") "File '$OSM_XML_FILE' exists, no further analysis required, terminating"
        exit
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "File '$OSM_XML_FILE' does not exist or is empty, starting download"
        overpassquery="true"
    fi
fi

#
# 
#

if [ "$overpassquery" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Calling wget for '$PREFIX'"
    wget "$OVERPASS_QUERY" -O $OSM_XML_FILE
    echo $(date "+%Y-%m-%d %H:%M:%S") "wget returns $?"
    
    if [ -s $OSM_XML_FILE ]
    then
        echo $(date "+%Y-%m-%d %H:%M:%S") "Success for wget for '$PREFIX'"
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "Calling wget for '$PREFIX' a second time"
        # try a second, but only a second time
        sleep 60    
        wget "$OVERPASS_QUERY" -O $OSM_XML_FILE
        echo $(date "+%Y-%m-%d %H:%M:%S") "wget returns $?"
        
        if [ -s $OSM_XML_FILE ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S") "Success for wget for '$PREFIX'"
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") "Failure for wget for '$PREFIX'"
        fi
    fi

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
                              --routes-file=$ROUTES_FILE \
                              --osm-xml-file=$OSM_XML_FILE \
                              > $HTML_FILE
    
            if [ -s "$HTML_FILE" ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S") "Analysis succeeded, '$HTML_FILE' created"
                echo $(date "+%Y-%m-%d %H:%M:%S") $(ls -l $HTML_FILE)

                if [ -f "$HTML_FILE.save" -a -s "$HTML_FILE.save" ]
                then                
                    diff $HTML_FILE.save $HTML_FILE > $HTML_FILE.diff
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
    echo $(date "+%Y-%m-%d %H:%M:%S")  "Upload '$HTML_FILE' to '$TARGET_LOC/$HTML_FILE'"

    if [ -f $HTML_FILE ]
    then 
        if [ -s $HTML_FILE ]
        then
            if [ -f "$HTML_FILE.save" ]
            then
                diff $HTML_FILE.save $HTML_FILE > $HTML_FILE.diff
            
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





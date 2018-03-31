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
     -z "$WIKI_ANALYSIS_PAGE"  -o \
     -z "$WIKI_ROUTES_PAGE"    -o \
     -z "$WIKI_FILE_DIFF"      -o \
     -z "$ANALYSIS_OPTIONS"        ]
then
    echo "'settings.sh' file: some variables are unset"
    echo "Please specify: PREFIX, OVERPASS_QUERY, WIKI_ANALYSIS_PAGE, WIKI_ROUTES_PAGE, WIKI_FILE_DIFF, ANALYSIS_OPTIONS"
    echo "... terminating"
    exit 2
fi

ROUTES_FILE="$PREFIX-Routes.txt"
OSM_XML_FILE="$PREFIX-Data.xml"
WIKI_FILE="$PREFIX-Analysis.wiki"

#
# 
#

TEMP=$(getopt -o acghopuw --long analyze,clean,get-routes,help,overpass-query,push-routes,upload-to-wiki,watch-routes -n 'analyze-network.sh' -- "$@")

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
        -u|--upload-to-wiki)    uploadtowiki=true   ; shift ;;
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
    rm -f $OSM_XML_FILE $WIKI_FILE $WIKI_FILE.old $WIKI_FILE.diff
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

if [ "$analyze" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S")  "Analyze $PREFIX"
    
    if [ -f $ROUTES_FILE -a -f $OSM_XML_FILE ]
    then
        if [ -s $ROUTES_FILE -a -s $OSM_XML_FILE ]
        then
        
            analyze-routes.pl $ANALYSIS_OPTIONS --network-long-regex="$NETWORK_LONG" --network-short-regex="$NETWORK_SHORT" --routes-file=$ROUTES_FILE --osm-xml-file=$OSM_XML_FILE > $WIKI_FILE
    
            if [ -s "$WIKI_FILE" ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S") "Analysis succeeded, '$WIKI_FILE' created"
            else
                echo $(date "+%Y-%m-%d %H:%M:%S") "'$WIKI_FILE' is empty"
            fi
            ls -l $WIKI_FILE
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") "'$ROUTES_FILE' or '$OSM_XML_FILE' is empty"
            ls -l $WIKI_FILE
       fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "'$ROUTES_FILE' or '$OSM_XML_FILE' does not exist"
    fi
fi

#
# 
#

if [ "$uploadtowiki" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S")  "Upload '$WIKI_FILE' to Wiki page '$WIKI_ANALYSIS_PAGE'"

    if [ -f $WIKI_FILE ]
    then 
        if [ -s $WIKI_FILE ]
        then
            filesize=$(ls -l $WIKI_FILE 2> /dev/null | awk '{print $5}')
            
            if [ "$filesize" -lt 2000000 ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S") "Reading old Wiki analysis page '$WIKI_ANALYSIS_PAGE'"
                wiki-page.pl --pull --page=$WIKI_ANALYSIS_PAGE --file=$WIKI_FILE.old
                
                diff $WIKI_FILE $WIKI_FILE.old > $WIKI_FILE.diff
                
                ls -l $WIKI_FILE.diff
                
                diffsize=$(ls -l $WIKI_FILE.diff 2> /dev/null | awk '{print $5}')
            
                if [ "$diffsize" -gt "$WIKI_FILE_DIFF" ]
                then
                    echo $(date "+%Y-%m-%d %H:%M:%S") "Writing new Wiki analysis page '$WIKI_ANALYSIS_PAGE'"
                    wiki-page.pl --push --page=$WIKI_ANALYSIS_PAGE --file=$WIKI_FILE --summary="automatic update by analyze-routes"
                else
                    echo $(date "+%Y-%m-%d %H:%M:%S") "No changes"
                fi
            else
                echo $(date "+%Y-%m-%d %H:%M:%S") "'$WIKI_FILE' is too large"
                ls -l $WIKI_FILE
            fi
        else
            echo $(date "+%Y-%m-%d %H:%M:%S") $WIKI_FILE is empty
            ls -l $WIKI_FILE
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S") $WIKI_FILE does not exist
    fi
fi

#
# 
#

if [ "$getroutes" = "true" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "Reading Routes Wiki page '$WIKI_ROUTES_PAGE' to file '%ROUTES_FILE'"
    wiki-page.pl --pull --page=$WIKI_ROUTES_PAGE --file=$ROUTES_FILE
    ls -l $ROUTES_FILE
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





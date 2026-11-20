#!/bin/bash

source ~/.ptna-config

mingigs=${1:-35}

avail=$(df | awk '$6 == "/osm" && $4 < '$mingigs' * 1024*1024 { print $4/1024/1024 }')

topicurl=https://ntfy.sh/$PTNA_NTFY_TOPIC

if [ -n "$PTNA_NTFY_TOPIC" -a -n "$avail" ]; then
  curl \
    -d "Only $avail GB available on the root disk. Better clean that up." \
    -H "Title: Low disk space alert on $(hostname)" \
    -H "Priority: high" \
    -H "Tags: warning,cd" \
    $topicurl
fi

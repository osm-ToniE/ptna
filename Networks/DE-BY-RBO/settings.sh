#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-RBO"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=5][name~'(Niederbayern|Oberpfalz)']->.L; rel(area.L)[route~'bus']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Regionalbus Ostbayern"
NETWORK_SHORT="RBO"

WIKI_ANALYSIS_PAGE="Ostbayern/Transportation/Analyse"
WIKI_ROUTES_PAGE="Ostbayern/Transportation/Analyse/DE-BY-RBO-Linien"
WIKI_FILE_DIFF="196"

ANALYSIS_OPTIONS="-v --wiki --max-error=10 --check-access --check-name --check-stop-position --check-sequence --check-version --check-wide-characters --multiple-ref-type-entries=allow --positive-notes --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


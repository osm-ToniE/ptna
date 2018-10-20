#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="EU-Flixbus"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=[timeout:900];(rel(poly:'66.6569762 -23.0736582 36.7092056 -8.9953345 35.9404351 -5.6214121 35.6139346 14.4332346 34.7008006 24.1315366 34.4389993 32.7441537 35.8614952 34.7724255 36.5499339 28.2827078 38.4530304 26.3152919 40.3714182 26.0499145 41.3793698 29.5730723 46.9807515 38.3381215 68.5976645 41.3125962 71.2893993 28.3897039')[route~'(bus|train|coach)'][~'network|operator'~'(Fernb|fernb|Flix|flix)'];rel(br);rel[type='route'](r);)->.routes;(.routes;<<;rel(r.routes);way(r.routes);node(r.routes););out;"
NETWORK_LONG="Flixbus|FlixTrain"
NETWORK_SHORT=""

ANALYSIS_PAGE="Europa/Transportation/Analyse"
WIKI_ROUTES_PAGE="Europa/Transportation/Analyse/Flixbuslinien"

ANALYSIS_OPTIONS="--allow-coach --check-access --check-name --check-stop-position --check-sequence --check-version --check-osm-separator --check-motorway-link --relaxed-begin-end-for=train --max-error=10 --multiple-ref-type-entries=analyze --positive-notes --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# 



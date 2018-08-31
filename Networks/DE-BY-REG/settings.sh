#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-REG"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=6][name='Landkreis Regen'];(rel(area)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)'];rel(br);rel[type='route'](r);)->.routes;(.routes;<<;rel(r.routes);way(r.routes);node(r.routes););out;"
NETWORK_LONG="Arberlandverkehr Landkreis Regen|waldbahn-Netz|Wanderbahn im Regental"
NETWORK_SHORT="REG|WBA"

ANALYSIS_PAGE="Regen/Transportation/Analyse"
WIKI_ROUTES_PAGE="Regen/Transportation/Analyse/DE-BY-REG-Linien"

ANALYSIS_OPTIONS="--max-error=10 --check-access --check-name --check-stop-position --check-sequence --check-version --check-osm-separator --check-motorway-link --multiple-ref-type-entries=allow --positive-notes --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


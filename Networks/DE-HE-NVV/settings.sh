#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-HE-NVV"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=6][name~'(Kassel|Werra-Meißner-Kreis|Schwalm-Eder-Kreis|Waldeck-Frankenberg|Hersfeld-Rotenburg)'];(rel(area)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)'];rel(br);rel[type='route'](r);)->.routes;(.routes;<<;rel(r.routes);way(r.routes);node(r.routes););out;"
NETWORK_LONG="Nordhessischer VerkehrsVerbund"
NETWORK_SHORT="NVV"

ANALYSIS_PAGE="Kassel/Transportation/Analyse"
WIKI_ROUTES_PAGE="Kassel/Transportation/Analyse/DE-HE-NVV-Linien"

ANALYSIS_OPTIONS="--check-access --check-name --check-stop-position --check-sequence --check-version --check-osm-separator --check-motorway-link --multiple-ref-type-entries=analyze --positive-notes --coloured-sketchline --expect-network-short --ptv1-compatibility=allow"

# --max-error=
# --check-bus-stop 
# --expect-network-long
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


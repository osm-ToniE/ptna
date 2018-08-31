#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-RBA"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=5][name~'Schwaben'];(rel(area)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)'];rel(br);rel[type='route'](r);)->.routes;(.routes;<<;rel(r.routes);way(r.routes);node(r.routes););out;"
NETWORK_LONG="Regionalbus Augsburg|Verkehrsgemeinschaft Donau-Ries|Stadtbus Donauwörth|Stadtbusse Dillingen|Regionalbus Isny|Netzwerk Bodensee und Oberschwaben|Verkehrsverbund Mittelschwaben|Landsberger Verkehrsgesellschaft"
NETWORK_SHORT="RBA|VDR|RBI|bodo|VVM|LVG"

ANALYSIS_PAGE="Region_Augsburg/Transportation/Analyse"
WIKI_ROUTES_PAGE="Region_Augsburg/Transportation/Analyse/DE-BY-RBA-Linien"

ANALYSIS_OPTIONS="--max-error=10 --check-access --check-name --check-stop-position --check-sequence --check-version --check-osm-separator --check-motorway-link --multiple-ref-type-entries=allow --positive-notes --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


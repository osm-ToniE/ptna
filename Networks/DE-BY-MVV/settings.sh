#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-MVV"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=6][name~'(Dachau|München|Ebersberg|Erding|Starnberg|Freising|Tölz|Wolfratshausen|Fürstenfeldbruck)'];(rel(area)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)'];rel(br);rel[type='route'](r);)->.routes;(.routes;<<;rel(r.routes);way(r.routes);node(r.routes););out;"
NETWORK_LONG="Münchner Verkehrs- und Tarifverbund|Münchner Linien|Grünwald|Gauting|Oberbiberg|Freising|Glonn"
NETWORK_SHORT="MVV"

ANALYSIS_PAGE="München/Transportation/Analyse"
WIKI_ROUTES_PAGE="München/Transportation/MVV-Linien-gesamt"

ANALYSIS_OPTIONS="--check-access --check-name --check-stop-position --check-sequence --check-version --check-osm-separator --check-motorway-link --positive-notes --multiple-ref-type-entries=analyze --coloured-sketchline --expect-network-long"

# --max-error=
# --check-bus-stop 
# --positive-notes
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


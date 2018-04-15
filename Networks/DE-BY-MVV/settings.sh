#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-MVV"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=6][name~'(Dachau|München|Ebersberg|Erding|Starnberg|Freising|Tölz|Wolfratshausen|Fürstenfeldbruck)']->.L; rel(area.L)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Münchner Verkehrs- und Tarifverbund|Münchner Linien|Bayerische Oberlandbahn|Meridian|Grünwald|Gauting|Oberbiberg|Freising|Glonn"
NETWORK_SHORT="MVV|BOB"

ANALYSIS_PAGE="München/Transportation/Analyse"
WIKI_ROUTES_PAGE="München/Transportation/MVV-Linien-gesamt"
FILE_DIFF="196"

ANALYSIS_OPTIONS="--check-access --check-name --check-stop-position --check-sequence --check-version --check-wide-characters --multiple-ref-type-entries=analyze --coloured-sketchline --expect-network-long"

# --max-error=
# --check-bus-stop 
# --positive-notes
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


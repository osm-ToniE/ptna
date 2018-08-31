#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-VGA"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=6][name='Landkreis Eichstätt'];(rel(area)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)'];rel(br);rel[type='route'](r);)->.routes;(.routes;<<;rel(r.routes);way(r.routes);node(r.routes););out;"
NETWORK_LONG="Verkehrsgmeinschaft Altmühltal|Jägle Verkehrsbetriebe|Regionalbus Augsburg|Ingolstädter Verkehrsgesellschaft mbH|Verkehrsverbund Großraum Nürnberg|Verkehrsgemeinschaft Landkreis Kelheim|Stadtlinie Eichstätt|Sillner|Buchberger Reisen"
NETWORK_SHORT="VGA|JVB|RBA|INVG|VGN|VLK"

ANALYSIS_PAGE="Eichstätt/Transportation/Analyse"
WIKI_ROUTES_PAGE="Eichstätt/Transportation/Analyse/DE-BY-VGA-Linien"

ANALYSIS_OPTIONS="--max-error=10 --check-access --check-name --check-stop-position --check-sequence --check-version --check-osm-separator --check-motorway-link --multiple-ref-type-entries=allow --positive-notes --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-AVV"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=(rel(poly:'48.61770452697 11.02169002533 48.58501115626 11.19953121185 48.46973480351 11.25617946625 48.21254898969 11.12709011078 48.17799160114 10.92555965424 48.10009492726 10.7775875473 48.12828883981 10.53657497406 48.44036225231 10.51700557709 48.55706881063 10.59871639252 48.66761187551 10.78685726166 48.66738513564 10.85140193939 48.61611575521 10.86376155853')[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)'];rel(br);rel[type='route'](r);)->.routes;(.routes;<<;rel(r.routes);way(r.routes);node(r.routes););out;"
NETWORK_LONG="Augsburger Verkehrs- und Tarifverbund"
NETWORK_SHORT="AVV"

ANALYSIS_PAGE="Augsburg/Transportation/Analyse"
WIKI_ROUTES_PAGE="Augsburg/Transportation/AVV-Linien-gesamt"

ANALYSIS_OPTIONS="--check-access --check-name --check-stop-position --check-sequence --check-version --check-osm-separator --check-motorway-link --multiple-ref-type-entries=analyze --positive-notes --coloured-sketchline"

# --max-error=
# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


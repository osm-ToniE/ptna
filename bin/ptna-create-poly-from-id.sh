#!/bin/bash

NAME="$1"
ID="$2"

if [ -n "$NAME" -a -n "$ID" ]
then
    curl "https://polygons.openstreetmap.fr/get_poly.py?id=$ID&params=0.20000-0.00050-0.00050" > $HOME/tmp/$NAME-large.poly
    curl "https://polygons.openstreetmap.fr/get_poly.py?id=$ID&params=0.02000-0.00500-0.00500" > $HOME/tmp/$NAME-small.poly
fi

#!/bin/bash

# Issue #17

analyze-routes.pl --max-error=10 --check-access --check-name --check-stop-position --check-sequence --check-version --check-wide-characters \
                  --multiple-ref-type-entries=allow --positive-notes --coloured-sketchline --verbose --debug \
                  --osm-xml-file RBO-6209-006-issue-17.osm > RBO-6209-006-issue-17.html 2> RBO-6209-006-issue-17.log

# 


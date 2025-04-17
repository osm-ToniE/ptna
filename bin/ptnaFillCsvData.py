#!/usr/bin/env python3

# Copyright 2025 Nitai Sasson
# Licensed under GNU GPLv3 or later

import re
import argparse
import json
from collections import Counter

def main(routes_file, template_file, out_file, show_hidden_variables):
    routes = load_routes(routes_file)
    print(f"Loaded {len(routes)} routes. Types:")
    for route_type, count in Counter(route.get('type', '(missing route type)') for route in routes).most_common():
        print(count, route_type)
    check_route_unique_ids(routes)
    process_template(template_file, out_file, routes, show_hidden_variables)
    print(f"Routes remaining: {len(routes)}." + (" Types:" if routes else ""))
    for route_type, count in Counter(route.get('type', '(missing route type)') for route in routes).most_common():
        print(count, route_type)

def load_routes(routes_file):
    with open(routes_file, encoding='utf-8') as f:
        return json.load(f)

def check_route_unique_ids(routes):
    # This used to be a function to give each route the minimal amount of information needed for it to be uniquely identified
    # However, turns out this is unnecessary, because PTNA doesn't use operator/from/to unless (ref, type) aren't unique
    # So instead we just warn about duplicate routes and routes with missing ref/type

    routes_by_id = {}

    for route in routes:
        route_id = (route.get('ref', ''), route.get('type', ''), route.get('operator', ''), route.get('from', ''), route.get('to', ''))
        routes_by_id.setdefault(route_id, []).append(route)

        if not (route.get('ref') and route.get('type')):
            print("Error: each route must have ref and type, but this route does not:")
            print(route)

    for routes_with_same_id in routes_by_id.values():
        if len(routes_with_same_id) != 1:
            print("Error: the following routes can't be differentiated by PTNA:")
            for route in routes_with_same_id:
                print(route)

def format_as_csv(output_line):
    # can't use the csv module because of the special rules about disallowed first character
    for i, v in enumerate(output_line):
        need_quote = i == 0 and v and v[0] in "#=-@+~$" # special character can't start a line
        need_quote = need_quote or '"' in v
        need_quote = need_quote or ';' in v
        need_quote = need_quote or '\n' in v
        need_quote = need_quote or v.strip() != v # better safe than sorry - quote surrounding whitespace
        if need_quote:
            output_line[i] = '"' + v.replace('"', '""') + '"'
    return ';'.join(output_line) + '\n'

def output_route(route, of, show_hidden_variables):
    csv_fields = ['ref', 'type', 'comment', 'from', 'to', 'operator', 'gtfs_feed', 'route_id', 'gtfs_release_date' ]
    output_line = [route.get(key, '') for key in csv_fields]
    # remove empty trailing items
    while not output_line[-1]:
        del output_line[-1]
    if show_hidden_variables:
        hidden_vars_strings = [f"{k}: {v!r}" for k, v in route.items() if k not in csv_fields]
        of.write("\n- " + ', '.join(hidden_vars_strings) + '\n')
    of.write(format_as_csv(output_line))

def parse_filter(filter_string):
    key, op, pattern = re.split(r'(!?[=~])', filter_string, maxsplit=1)
    assert op in ['=', '~', '!=', '!~'], f"Impossible value for op: {op}"
    if '=' in op:
        # = equality
        f = lambda route: key in route and str(route[key]) == pattern
    else:
        # ~ regex
        pattern = re.compile(pattern)
        f = lambda route: key in route and bool(pattern.search(str(route[key])))

    if '!' in op:
        # ! flip result
        g = f
        f = lambda route: not g(route)

    return f

def create_filters_function(filters):
    """parse the filters and return a function that accepts a route and returns whether it passes all the filters"""
    for i, f in enumerate(filters):
        # changes here will be visible in the closing @@ as well

        if not re.search('[=~]', f):
            # @bus -> @type=bus
            f = f"type={f}"
        assert re.search('[=~]', f)

        # @route-id=X-X -> @route_id=X-X
        f = re.split(r'([=~])', f, maxsplit=1)
        f[0] = f[0].replace('-', '_')
        f = ''.join(f)

        filters[i] = f


    filters = [parse_filter(f) for f in filters]
    return lambda r: all(f(r) for f in filters)

def output_routes_with_filters(routes, filters, of, show_hidden_variables):
    try:
        route_passes_filters = create_filters_function(filters) # modifies filters, affects output in next line
        print("Outputting routes with filters:")
        print('\n'.join(f"@{f}" for f in filters))
        used_indexes = []
        for i, route in enumerate(routes):
            if route_passes_filters(route):
                output_route(route, of, show_hidden_variables)
                used_indexes.append(i)
        # prevent repeats of printed lines
        for i in reversed(used_indexes):
            del routes[i]
        if not used_indexes:
            of.write("-\n- No routes match the filter criteria\n-\n")
        print(f"Result: {len(used_indexes)} routes")
    except re.error as err:
        print(f"Regular expression patter error: {err}, pattern: {err.pattern}")
        of.write("-\n- Error: regular expression error in filters\n")
        of.write(f"- {err}\n")
        of.write(f"- {err.pattern}\n")
        of.write(f"- {' ' * err.pos}^\n-\n") # this will not be readable in the analysis page, but I don't care

def process_template(template_file, out_file, routes, show_hidden_variables):
    with open(template_file, encoding='utf-8') as tf, open(out_file, 'w', encoding='utf-8') as of:
        for line in tf:
            stripped_line = line.strip()
            if stripped_line.startswith('@@'):
                print("Error: template end marker '@@' without preceding filters")
                of.write('@@ error: template end marker without filters\n')
            elif stripped_line.startswith('@'):
                # template filter - collect all filters until end @@, skip all non-@ lines
                line = stripped_line.removeprefix('@')
                of.write(f"@{line}\n")
                filters = [line]

                for line in tf:
                    line = line.strip()
                    if line.startswith('@@'):
                        break
                    elif line.startswith('@'):
                        line = line.removeprefix('@')
                        of.write(f"@{line}\n")
                        filters.append(line)
                    elif line.startswith('#'):
                        # preserve comments
                        of.write(line + "\n")

                output_routes_with_filters(routes, filters, of, show_hidden_variables)

                of.write(f"@@{' '.join(filters)}\n")
            else:
                # echo all other lines
                of.write(line)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-r", "--routes", required=True, help="json file containing the routes in this area")
    parser.add_argument("-t", "--template", required=True, help="PTNA CSV file, downloaded from the wiki")
    parser.add_argument("-o", "--outfile", required=True, help="output file, to be uploaded to the wiki")
    parser.add_argument("-v", "--show-hidden-variables", action='store_true', help="precede each CSV line with a text line listing its hidden variables which can be used for filtering")
    args = parser.parse_args()
    main(args.routes, args.template, args.outfile, args.show_hidden_variables)

#!/usr/bin/env python3

import re
import argparse
import json
from collections import Counter

def main(routes_file, template_file, out_file):
    routes = load_routes(routes_file)
    print(f"Loaded {len(routes)} routes. Types:")
    for route_type, count in Counter(route.get('route_type', '(missing route_type)') for route in routes).most_common():
        print(count, route_type)
    check_route_unique_ids(routes)
    process_template(template_file, out_file, routes)
    print(f"Routes remaining: {len(routes)}. Types:")
    for route_type, count in Counter(route.get('route_type', '(missing route_type)') for route in routes).most_common():
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
        route_id = (route.get('ref', ''), route.get('route_type', ''), route.get('operator', ''), route.get('from', ''), route.get('to', ''))
        routes_by_id.setdefault(route_id, []).append(route)

        if not (route.get('ref') and route.get('route_type')):
            print("Error: each route must have ref and route_type, but this route does not:")
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
            output_line[i] = f'"{v.replace('"', '""')}"'
    return ';'.join(output_line) + '\n'
    
def output_route(route, of):
    # ref; route_type; comment; from; to; operator; gtfs_feed; route_id; gtfs_release_date
    output_line = [
        route.get('ref', ''),
        route.get('route_type', ''),
        route.get('comment', ''),
        route.get('from', ''),
        route.get('to', ''),
        route.get('operator', ''),
        route.get('gtfs_feed', ''),
        route.get('route_id', ''),
        route.get('gtfs_release_date', '')
        ]
    # remove empty trailing items
    while not output_line[-1]:
        del output_line[-1]
    of.write(format_as_csv(output_line))

def route_passes_filters(route, filters):
    for f in filters:
        if not re.search('[=~]', f):
            # @bus -> @route_type=bus
            f = f"route_type={f}"
        op = re.search('!?[=~]', f).group()
        key, op, value = f.partition(op)
        if op == '=':
            if key not in route:
                return False
            if str(route[key]) != value:
                return False
        elif op == '~':
            if key not in route:
                return False
            if not re.search(value, str(route[key])):
                return False
        elif op == '!=':
            if key in route and str(route[key]) == value:
                return False
        elif op == '!~':
            if key in route and re.search(value, str(route[key])):
                return False
        else:
            raise RuntimeError(f"Impossible value for op: {op}")

    return True

def output_routes_with_filters(routes, filters, of):
    print("Outputting routes with filters:")
    print('\n'.join(f"@{f}" for f in filters))
    used_indexes = []
    for i, route in enumerate(routes):
        if route_passes_filters(route, filters):
            output_route(route, of)
            used_indexes.append(i)
    # prevent repeats of printed lines
    for i in reversed(used_indexes):
        del routes[i]
    if not used_indexes:
        of.write("- No routes match the filter criteria\n")
    print(f"Result: {len(used_indexes)} routes")

def process_template(template_file, out_file, routes):
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

                output_routes_with_filters(routes, filters, of)

                of.write(f'@@{' '.join(filters)}\n')
            else:
                # echo all other lines
                of.write(line)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-r", "--routes", required=True, help="json file containing the routes in this area")
    parser.add_argument("-t", "--template", required=True, help="PTNA CSV file, downloaded from the wiki")
    parser.add_argument("-o", "--outfile", required=True, help="output file, to be uploaded to the wiki")
    args = parser.parse_args()
    main(args.routes, args.template, args.outfile)

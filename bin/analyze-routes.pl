#!/usr/bin/perl

use warnings;
use strict;

####################################################################################################################
#
# 1.) Overpass API query to get all "route" and their "route_master" relations for bus, tram, train, subway, light_rail, trolleybus, share_taxi  from OpenStreetMap for Oberbayern and sme areas
#       http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=5][name~"Oberbayern"]->.O; area(area.O)[boundary=administrative][admin_level=6][name~"(Dachau|München|Ebersberg|Erding|Starnberg|Freising|Tölz|Wolfratshausen|Fürstenfeldbruck)"]->.L; rel(area.L)["route"~"(bus|tram|train|subway|taxi|light_rail)"]; out; rel(br); out; 
#           can be around 140.000 lines of XML, up to 6.7 MB
#
# 2.) CSV file with a (sorted) list of all route_master/route which belong to the network of interest.
#     The first column of the list corresponds to the "ref" values of those route_master / route relations
#     The order of the lines is used for an overview of the results (e.g. subway, suburban train, trams, metro bus, bus, regional bus, ... lines)
#
# 3.) 
#
####################################################################################################################

use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Getopt::Long;
use XML::Simple;
use Data::Dumper;
use Encode;

my @supported_route_types   = ( 'train', 'subway', 'light_rail', 'tram', 'trolleybus', 'bus', 'ferry', 'monorail', 'aerialway', 'funicular', 'share_taxi' );
my $regex_supported_route_types = join( '|', @supported_route_types );

my $verbose                         = undef;
my $debug                           = undef;
my $osm_xml_file                    = undef;
my $routes_file                     = undef;
my $relaxed_begin_end_for           = undef;
my $network_guid                    = undef;
my $network_long_regex              = undef;
my $network_short_regex             = undef;
my $operator_regex                  = undef;
my $check_access                    = undef;
my $check_bus_stop                  = undef;
my $check_name                      = undef;
my $check_stop_position             = undef;
my $check_platform                  = undef;
my $check_sequence                  = undef;
my $check_roundabouts               = undef;
my $check_version                   = undef;
my $check_wide_characters           = undef;
my $expect_network_long             = undef;
my $expect_network_long_for         = undef;
my $expect_network_short            = undef;
my $expect_network_short_for        = undef;
my $multiple_ref_type_entries       = "analyze";
my $show_options                    = undef;
my $strict_network                  = undef;
my $strict_operator                 = undef;
my $max_error                       = undef;
my $help                            = undef;
my $man_page                        = undef;
my $positive_notes                  = undef;
my $csv_separator                   = ';';
my $coloured_sketchline             = undef;
my $print_wiki                      = undef;
my $page_title                      = undef;


GetOptions( 'help'                          =>  \$help,                         # -h or --help                      help
            'man'                           =>  \$man_page,                     # --man                             manual pages
            'verbose'                       =>  \$verbose,                      # --verbose
            'debug'                         =>  \$debug,                        # --debug
            'check-access'                  =>  \$check_access,                 # --check-access                    check for access restrictions on highways
            'check-bus-stop'                =>  \$check_bus_stop,               # --check-bus-stop                  check for strict highway=bus_stop on nodes only
            'check-name'                    =>  \$check_name,                   # --check-name                      check for strict name conventions (name='... ref: from => to'
            'check-platform'                =>  \$check_platform,               # --check-platform                  check for bus=yes, tram=yes, ... on platforms
            'check-roundabouts'             =>  \$check_roundabouts,            # --check-roundabouts               check for roundabouts being included completely
            'check-sequence'                =>  \$check_sequence,               # --check-sequence                  check for correct sequence of stops, platforms and ways
            'check-stop-position'           =>  \$check_stop_position,          # --check-stop-position             check for bus=yes, tram=yes, ... on (stop_positions
            'check-version'                 =>  \$check_version,                # --check-version                   check for PTv2 on route_masters, ...
            'check-wide-characters'         =>  \$check_wide_characters,        # --check-wide-characters           check for wide charaters in relation tags
            'coloured-sketchline'           =>  \$coloured_sketchline,          # --coloured-sketchline             force SketchLine to print coloured icons
            'expect-network-long'           =>  \$expect_network_long,          # --expect-network-long             note if 'network' is not long form in general
            'expect-network-long-for:s'     =>  \$expect_network_long_for,      # --expect-network-long-for="Münchner Verkehrs- und Tarifverbund|Biberger Bürgerbus"         note if 'network' is not long form for ...
            'expect-network-short'          =>  \$expect_network_short,         # --expect-network-short            note if 'network' is not short form in general
            'expect-network-short-for:s'    =>  \$expect_network_short_for,     # --expect-network-short-for='BOB'        note if 'network' is not short form for ...
            'routes-file=s'                 =>  \$routes_file,                  # --routes-file=zzz                 CSV file with a list of routes of the of the network
            'max-error=i'                   =>  \$max_error,                    # --max-error=10                    limit number of templates printed for identical error messages
            'multiple-ref-type-entries=s'   =>  \$multiple_ref_type_entries,    # --multiple-ref-type-entries=analyze|ignore|allow    how to handle multiple "ref;type" in routes-file
            'network-guid=s'                =>  \$network_guid,                 # --network-guid='DE-BY-MVV'
            'network-long-regex:s'          =>  \$network_long_regex,           # --network-long-regex='Münchner Verkehrs- und Tarifverbund|Grünwald|Bayerische Oberlandbahn'
            'network-short-regex:s'         =>  \$network_short_regex,          # --network-short-regex='MVV|BOB'
            'operator-regex:s'              =>  \$operator_regex,               # --operator-regex='MVG|Münchner'
            'positive-notes'                =>  \$positive_notes,               # --positive-notes                  print positive information for notes, if e.g. something is fulfilled
            'relaxed-begin-end-for:s'       =>  \$relaxed_begin_end_for,        # --relaxed-begin-end-for=...       for train/tram/light_rail: first/last stop position does not have to be on first/last node of way, but within first/last way
            'osm-xml-file=s'                =>  \$osm_xml_file,                 # --osm-xml-file=yyy                XML output of Overpass APU query
            'separator=s'                   =>  \$csv_separator,                # --separator=';'                   separator in the CSV file
            'show-options'                  =>  \$show_options,                 # --show-options                    print a section with all options and their values
            'strict-network'                =>  \$strict_network,               # --strict-network                  do not consider empty network tags
            'strict-operator'               =>  \$strict_operator,              # --strict-operator                 do not consider empty operator tags
            'title=s'                       =>  \$page_title,                   # --title=...                       Title for the HTML page
            'wiki'                          =>  \$print_wiki,                   # --wiki                            prepare outut for WIKI instead of HTML
          );

$page_title                 = decode('utf8', $page_title )                  if ( $page_title                );
$network_guid               = decode('utf8', $network_guid )                if ( $network_guid              );
$network_long_regex         = decode('utf8', $network_long_regex )          if ( $network_long_regex        );
$network_short_regex        = decode('utf8', $network_short_regex )         if ( $network_short_regex       );
$operator_regex             = decode('utf8', $operator_regex )              if ( $operator_regex            );
$expect_network_long_for    = decode('utf8', $expect_network_long_for )     if ( $expect_network_long_for   );
$expect_network_short_for   = decode('utf8', $expect_network_short_for )    if ( $expect_network_short_for  );

if ( $verbose ) {
    printf STDERR "%s analyze-routes.pl -v\n", get_time();
    printf STDERR "%20s--title='%s'\n",                    ' ', $page_title                    if ( $page_title                  );
    printf STDERR "%20s--network-guid='%s'\n",             ' ', $network_guid                  if ( $network_guid                );
    printf STDERR "%20s--wiki\n",                          ' '                                 if ( $print_wiki                  );
    printf STDERR "%20s--check-access\n",                  ' '                                 if ( $check_access                );
    printf STDERR "%20s--check-bus-stop\n",                ' '                                 if ( $check_bus_stop              );
    printf STDERR "%20s--check-name\n",                    ' '                                 if ( $check_name                  );
    printf STDERR "%20s--check-platform\n",                ' '                                 if ( $check_platform              );
    printf STDERR "%20s--check-roundabouts\n",             ' '                                 if ( $check_roundabouts           );
    printf STDERR "%20s--check-sequence\n",                ' '                                 if ( $check_sequence              );
    printf STDERR "%20s--check-stop-position\n",           ' '                                 if ( $check_stop_position         );
    printf STDERR "%20s--check-version\n",                 ' '                                 if ( $check_version               );
    printf STDERR "%20s--check-wide-characters\n",         ' '                                 if ( $check_wide_characters       );
    printf STDERR "%20s--coloured-sketchline\n",           ' '                                 if ( $coloured_sketchline         );
    printf STDERR "%20s--expect-network-long\n",           ' '                                 if ( $expect_network_long         );
    printf STDERR "%20s--expect-network-short\n",          ' '                                 if ( $expect_network_short        );
    printf STDERR "%20s--positive-notes\n",                ' '                                 if ( $positive_notes              );
    printf STDERR "%20s--show-options\n",                  ' '                                 if ( $show_options                );
    printf STDERR "%20s--strict-network\n",                ' '                                 if ( $strict_network              );
    printf STDERR "%20s--strict-operator\n",               ' '                                 if ( $strict_operator             );
    printf STDERR "%20s--network-long-regex='%s'\n",       ' ', $network_long_regex            if ( $network_long_regex          );
    printf STDERR "%20s--network-short-regex='%s'\n",      ' ', $network_short_regex           if ( $network_short_regex         );
    printf STDERR "%20s--operator-regex='%s'\n",           ' ', $operator_regex                if ( $operator_regex              );
    printf STDERR "%20s--expect-network-long-for='%s'\n",  ' ', $expect_network_long_for       if ( $expect_network_long_for     );
    printf STDERR "%20s--expect-network-short-for='%s'\n", ' ', $expect_network_short_for      if ( $expect_network_short_for    );
    printf STDERR "%20s--multiple-ref-type-entries='%s'\n",' ', $multiple_ref_type_entries     if ( $multiple_ref_type_entries   );
    printf STDERR "%20s--max-error='%s'\n",                ' ', $max_error                     if ( $max_error                   );
    printf STDERR "%20s--relaxed-begin-end-for='%s'\n",    ' ', $relaxed_begin_end_for         if ( $relaxed_begin_end_for       );
    printf STDERR "%20s--separator='%s'\n",                ' ', $csv_separator                 if ( $csv_separator               );
    printf STDERR "%20s--routes-file='%s'\n",              ' ', decode('utf8', $routes_file )  if ( $routes_file                 );
    printf STDERR "%20s--osm-xml-file='%s'\n",             ' ', decode('utf8', $osm_xml_file ) if ( $osm_xml_file                );
}


my $routes_xml              = undef;
my @routes_csv              = ();
my %refs_of_interest        = ();
my %collected_tags          = ();
my $key                     = undef;
my $value                   = undef;
my @rest                    = ();

my $xml_has_relations       = 0;        # does the XML file include any relations? If not, we will exit
my $xml_has_ways            = 0;        # does the XML file include any ways, then we can make a big analysis
my $xml_has_nodes           = 0;        # does the XML file include any nodes, then we can make a big analysis

my %NODES                   = ();       # all ways in the XML file 
my %WAYS                    = ();       # all nodes in the XML file
my %RELATIONS               = ();       # all relations in the XML file

my %PT_relations_with_ref   = ();       # includes "positive" (the ones we are looking for) as well as "negative" (the other ones) route/route_master relations and "skip"ed relations (where 'network' or 'operator' does not fit)
my %PT_relations_without_ref= ();       # includes any route/route_master relations without 'ref' tag
my %PL_MP_relations         = ();       # includes type=multipolygon, public_transport=platform  multipolygone relations
my %NON_PL_MP_relations     = ();       # includes type=multipolygon where public_transport is not set
my %SA_relations            = ();       # includes type=public_transport, public_transport=stop_area relations (not of interest though)
my %suspicious_relations    = ();       # strange relations with suspicious tags, a simple list of Relation-IDs, more details can befound with $RELATIONS{rel-id}
my %route_ways              = ();       # all ways  of the XML file that build the route : equals to %WAYS - %platform_ways
my %platform_ways           = ();       # all ways  of the XML file that are platforms (tag: public_transport=platform)
my %platform_nodes          = ();       # all nodes of the XML file that are platforms (tag: public_transport=platform)
my %stop_nodes              = ();       # all nodes of the XML file that are stops (tag: public_transport=stop_position)
my %unused_networks         = ();       # 'network' values that did not match


my $xml_hash_ref            = undef;
my $relation_ptr            = undef;    # a pointer in Perl to a relation structure
my $relation_id             = undef;    # the OSM ID of a relation
my $way_id                  = undef;    # the OSM ID of a way
my $node_id                 = undef;    # the OSM ID of a node
my $tag                     = undef;
my $ref                     = undef;    # the value of "ref" tag of an OSM object (usually the "ref" tag of a route relation
my $route_type              = undef;    # the value of "route_master" or "route" of a relation
my $member                  = undef;
my $node                    = undef;
my $entry                   = undef;
my $type                    = undef;
my $member_index                    = 0;
my $relation_index                  = 0;
my $route_master_relation_index     = 0;    # counts the number of relation members in a 'route_master' which do not have 'role' ~ 'platform' (should be equal to $relation_index')
my $route_relation_index            = 0;    # counts the number of relation members in a 'route' which are not 'platforms' (should be zero)
my $way_index                       = 0;    # counts the number of all way members
my $route_highway_index             = 0;    # counts the number of ways members in a route which do not have 'role' ~ 'platform'
my $node_index                      = 0;    # counts the number of node members
my $role_platform_index             = 0;    # counts the number of members which have 'role' '^platform.*'
my $role_stop_index                 = 0;    # counts the number of members which have 'role' '^platform.*'
my $osm_base                        = '';
my $areas                           = '';

my %column_name             = ( 'ref'           => 'Linie (ref=)',
                                'relation'      => 'Relation (id=)',
                                'relations'     => 'Relationen',                # comma separated list of relation-IDs
                                'name'          => 'Name (name=)',
                                'network'       => 'Netz (network=)',
                                'operator'      => 'Betreiber (operator=)',
                                'from'          => 'Von (from=)',
                                'via'           => 'Über (via=)',
                                'to'            => 'Nach (to=)',
                                'issues'        => 'Fehler',
                                'notes'         => 'Anmerkungen',
                                'type'          => 'Typ (type=)',
                                'route_type'    => 'Verkehrsmittel (route(_master)=)',
                                'PTv'           => '',
                                'Comment'       => 'Kommentar',
                                'From'          => 'Von',
                                'To'            => 'Nach',
                                'Operator'      => 'Betreiber',
                              );

my %transport_types         = ( 'bus'           => 'Bus',
                                'share_taxi'    => '(Anruf-)Sammel-Taxi',
                                'train'         => 'Zug/S-Bahn',
                                'tram'          => 'Tram/Straßenbahn',
                                'subway'        => 'U-Bahn',
                                'light_rail'    => 'Light-Rail',
                                'trolleybus'    => 'Trolley Bus',
                                'ferry'         => 'Fähre',
                                'monorail'      => 'Mono-Rail',
                                'aerialway'     => 'Seilbahn',
                                'funicular'     => 'Drahtseilbahn'
                              );

my %colour_table            = ( 'black'         => '#000000',
                                'gray'          => '#808080',
                                'grey'          => '#808080',
                                'maroon'        => '#800000',
                                'olive'         => '#808000',
                                'green'         => '#008000',
                                'teal'          => '#008080',
                                'navy'          => '#000080',
                                'purple'        => '#800080',
                                'white'         => '#FFFFFF',
                                'silver'        => '#C0C0C0',
                                'red'           => '#FF0000',
                                'yellow'        => '#FFFF00',
                                'lime'          => '#00FF00',
                                'aqua'          => '#00FFFF',
                                'cyan'          => '#00FFFF',
                                'blue'          => '#0000FF',
                                'fuchsia'       => '#FF00FF',
                                'magenta'       => '#FF00FF',
                              );


#############################################################################################
# 
# read the XML file with the OSM information (might take a while)
#
#############################################################################################

if ( $osm_xml_file ) {
    printf STDERR "%s Reading %s\n", get_time(), decode('utf8', $osm_xml_file )    if ( $verbose );
    $routes_xml  = XMLin( $osm_xml_file,  ForceArray => 1 );
    printf STDERR "%s %s read\n", get_time(), decode('utf8', $osm_xml_file )       if ( $verbose );
    # print Dumper( $routes_xml )        ; #                                         if ( $debug   );

    $xml_has_relations  = 1  if ( $routes_xml->{'relation'} );   
    $xml_has_ways       = 1  if ( $routes_xml->{'way'}      );   
    $xml_has_nodes      = 1  if ( $routes_xml->{'node'}     );   
}

if ( $xml_has_relations == 0 ) {
    printf STDERR "No relations found in XML file %s - exiting\n", decode('utf8', $osm_xml_file );
    
    exit 1;
}


#############################################################################################
#
# now read the file which contains the lines of interest, CSV style file, first column corresponds to "ref", those are the "refs of interest"
#
#############################################################################################

my @pre_print   = ();
my @post_print  = ();

if ( $routes_file ) {
    
    printf STDERR "%s Reading %s\n", get_time(), decode('utf8', $routes_file )                  if ( $verbose );
    
    if ( -f $routes_file ) {
        
        if ( -r $routes_file ) {
            
            if ( open(CSV,"< $routes_file") ) {
                binmode CSV, ":utf8";
                
                while ( <CSV> ) {
                    chomp();                                        # remove NewLine
                    s/\r$//;                                        # remoce 'CR'
                    s/^\s*//;                                       # remove space at the beginning
                    s/\s*$//;                                       # remove space at the end
                    s/<pre>//;                                      # remove HTML tag if this is a copy from the Wiki-Page
                    s|</pre>||;                                     # remove HTML tag if this is a copy from the Wiki-Page
                    next    if ( !$_ );                             # ignore if line is empty
                    if ( m/^<\s*(.*)$/ ) {
                        push( @pre_print, $1 );                     # anything after '<' shall be printed before all other stuff
                        next;
                    }
                    if ( m/^>\s*(.*)$/ ) {
                        push( @post_print, $1 );                    # anything after '>' shall be printed after all other stuff
                        next;
                    }
                    push( @routes_csv, $_ );                        # store as lines of interrest
                    next    if ( m/^[=#-]/ );                       # ignore headers, text and comment lines here in this analysis
                    
                    #printf STDERR "CSV line = %s\n", $_;
                    if ( m/$csv_separator/ ) {
                        ($ref,$route_type)              = split( $csv_separator );
                        if ( $ref && $route_type ) {
                            $refs_of_interest{$ref}->{$route_type} = 0   unless ( defined($refs_of_interest{$ref}->{$route_type}) );
                            $refs_of_interest{$ref}->{$route_type}++;
                            if ( $refs_of_interest{$ref}->{$route_type} > 1 ) {
                                if ( $multiple_ref_type_entries eq 'ignore' ) {
                                    pop( @routes_csv );                             # ignore this entry, i.e. remove 2nd, 3rd, ... entry from list
                                    $refs_of_interest{$ref}->{$route_type}--;
                                } 
                            }
                            # printf STDERR "refs_of_interest{%s}->{%s}\n", $ref, $route_type      if ( $verbose );
                        }
                    }
                    elsif ( m/(\S)/ ) {
                        $refs_of_interest{$_}->{'__any__'} = 0   unless ( defined($refs_of_interest{$_}->{'__any__'}) );
                        $refs_of_interest{$_}->{'__any__'}++;
                    }
                             
                }
                close( CSV );
                printf STDERR "%s %s read\n", get_time(), decode('utf8', $routes_file )                          if ( $verbose );
                #print Dumper( @routes_csv )                                                         if ( $debug   );
            }
            else {
                printf STDERR "%s Could not open %s: %s\n", get_time(), decode('utf8', $routes_file ), $!;
            }
        }
        else {
            printf STDERR "%s No read access for file %s\n", get_time(), decode('utf8', $routes_file );
        }
    }
    else {
           printf STDERR "%s %s is not a file\n", get_time(), decode('utf8', $routes_file );
    }
}


#############################################################################################
#
# now analyze the XML data
#
# 1. the meta informatio of the data: when has this been extracted from the DB
#
#############################################################################################

if ( $routes_xml->{'meta'} ) {
    foreach my $meta ( @{$routes_xml->{'meta'}} ) {
        if ( $meta->{'osm_base'} ) {
            $osm_base = $meta->{'osm_base'};
        }
        if ( $meta->{'areas'} ) {
            $areas = $meta->{'areas'};
        }
    }
    $osm_base =~ s/T/ /g;
    $osm_base =~ s/Z/ UTC/g;
    $areas    =~ s/T/ /g;
    $areas    =~ s/Z/ UTC/g;
}

if ( $debug   ) {
    printf STDERR "OSM-Base : %s\n", $osm_base;
    printf STDERR "Areas    : %s\n", $areas;
}


#############################################################################################
#
# analyze the main part of the XML data
#
# 1. the relation information
#
# 2. way information
#
# 3. node information
#
# XML data for relations will be converted into own structure, additional data will be created also, so that analysis is more easier
#
#############################################################################################

my $status                              = undef;        # can be: 'keep', 'skip', 'keep positive' or 'keep negative'
my $section                             = undef;        # can be: 'positive', 'negative', 'skip', 'suspicious' or something else
my $number_of_relations                 = 0;
my $number_of_route_relations           = 0;
my $number_of_pl_mp_relations           = 0;
my $number_of_non_pl_mp_relations       = 0;
my $number_of_sa_relations              = 0;
my $number_of_network_relations         = 0;
my $number_of_positive_relations        = 0;
my $number_of_negative_relations        = 0;
my $number_of_skipped_relations         = 0;
my $number_of_skipped_other_relations   = 0;
my $number_of_suspicious_relations      = 0;
my $number_of_relations_without_ref     = 0;
my $number_of_ways                      = 0;
my $number_of_routeways                 = 0;
my $number_of_platformways              = 0;
my $number_of_nodes                     = 0;
my $number_of_platformnodes             = 0;
my $number_of_stop_positions            = 0;
my $number_of_unused_networks           = 0;

#
# there are relations, so lets convert them
#

printf STDERR "%s Converting relations\n", get_time()       if ( $verbose );

foreach $relation_id ( keys ( %{$routes_xml->{'relation'}} ) ) {
    
    $number_of_relations++;
    
    %collected_tags  = ();

    $xml_hash_ref   = $routes_xml->{'relation'}{$relation_id};
    
    #
    # convert XML data like <tag k='name' v='Ottobrunn' /> into: colletced_tags{'name'} = 'Ottobrunn'
    foreach $tag ( @{$xml_hash_ref->{'tag'}} ) {
        if ( $tag->{'k'} ) {
            $collected_tags{$tag->{'k'}} = $tag->{'v'};
        }
    }

    while ( ($key,$value) = each( %collected_tags ) ) {
        $RELATIONS{$relation_id}->{'tag'}->{$key} = $value;
        printf STDERR "%s RELATIONS{%s}->{'tag'}->{%s} = %s\n", get_time(), $relation_id, $key, $value    if ( $debug );
    }

    $ref        = $collected_tags{'ref'};
    $type       = $collected_tags{'type'};

    if ( $type ) {
        #
        # first analyze route_master and route relations
        #
        if ( $type eq 'route_master' || $type eq 'route' ) {
    
            $route_type = $collected_tags{$collected_tags{'type'}};
    
            if ( $route_type ) {    
            
                $number_of_route_relations++;
                #
                # if 'sort_name' is defined for the relation, then the mapper's choice will be respected for printing the Wiki lists
                # if 'sort_name' is not defined or not set, it inherits the value from 'ref_trips' and then from 'name' plus relation-id but at least is set to the relation-id
                # this shall ensure that all route are always printed in the same order for the Wiki page, even if two routes have the name
                #
                $collected_tags{'sort_name'} = $collected_tags{'ref_trips'}                                                                    unless ( $collected_tags{'sort_name'} );
                $collected_tags{'sort_name'} = ( $collected_tags{'name'}      ? $collected_tags{'name'} . '-' . $relation_id : $relation_id )  unless ( $collected_tags{'sort_name'} );
        
                $relation_ptr = undef;
                
                if ( $ref ) {
                    $status = 'keep';
            
                    # match_route_type() returns either "keep" or "suspicious" or "skip"
                    # is this route_type of general interest? 'hiking', 'bicycle', ... routes are not of interest here
                    # "keep"        route_type matches exactly the supported route types            m/^'type'$/
                    # "suspicious"  route_type does not exactly match the supported route types     m/'type'/               (typo, ...?)
                    # "skip"        route_type is not handled as PT                                 "hiking", "bicycle", ...
                    #
                    if ( $status =~ m/keep/ ) { $status = match_route_type( $route_type ); }
                    printf STDERR "%-15s: ref=%s\ttype=%s\troute_type=%s\tRelation: %d\n", $status, $ref, $type, $route_type, $relation_id   if ( $debug );
                    
                    # match_network() returns either "keep long" or "keep short" or "skip"
                    #
                    if ( $status =~ m/keep/ ) { $status = match_network(  $collected_tags{'network'} ); }
                    
                    if ( $status !~ m/keep/ ) {
                        if ( $collected_tags{'network'} ) {
                            $unused_networks{$collected_tags{'network'}}->{$relation_id} = 1;
                        }
                        else {
                            $unused_networks{'__unset_network__'}->{$relation_id} = 1;
                        }
                    }
                    
                    
                    # match_operator() returns either "keep" or "skip"
                    #
                    if ( $status =~ m/keep/ ) { $status = match_operator( $collected_tags{'operator'} ); }
                                
                    # match_ref_and_pt_type() returns "keep positive", "keep negative", "skip"
                    # "keep positive"   if $ref and $type match the %refs_of_interest (list of lines from CSV file)
                    # "keep negative"   if $ref and $type do not match
                    # "skip"            if $ref and $type are not set
                    #
                    if ( $status =~ m/keep/ ) { $status = match_ref_and_pt_type( $ref, $route_type ); }
                                
                    printf STDERR "%-15s: ref=%-10s\ttype=%15s\tnetwork=%s\toperator=%s\tRelation: %d\n", $status, $ref, $type, $collected_tags{'network'}, $collected_tags{'operator'}, $relation_id   if ( $debug );
                    
                    $section = undef;
                    if ( $status =~ m/(positive|negative|skip|suspicious)/ ) {
                        $section= $1;
                    }
                    
                    if ( $section ) {
                        if ( $section ne 'suspicious' ) {
                            my $ue_ref = $ref;
                            $PT_relations_with_ref{$section}->{$ue_ref}->{$type}->{$route_type}->{$relation_id}->{'tag'}->{'ref'}  = $ref;
                            $PT_relations_with_ref{$section}->{$ue_ref}->{$type}->{$route_type}->{$relation_id}->{'tag'}->{'type'} = $type;
                            $PT_relations_with_ref{$section}->{$ue_ref}->{$type}->{$route_type}->{$relation_id}->{'tag'}->{$type}  = $route_type;
                            $relation_ptr = $PT_relations_with_ref{$section}->{$ue_ref}->{$type}->{$route_type}->{$relation_id};
                            $number_of_positive_relations++     if ( $section eq "positive"     );
                            $number_of_negative_relations++     if ( $section eq "negative"     );
                            $number_of_skipped_relations++      if ( $section eq "skip"         );
                        }
                        else {
                            $suspicious_relations{$relation_id} = 1;
                            $number_of_suspicious_relations++;
                        }
                    }
                    elsif ( $verbose ) {
                        printf STDERR "%s Section mismatch 'status' = '%s'\n", get_time(), $status;
                    }
                }
                else {
                    $PT_relations_without_ref{$route_type}->{$relation_id}->{'tag'}->{'type'} = $type;
                    $PT_relations_without_ref{$route_type}->{$relation_id}->{'tag'}->{$type}  = $route_type;
                    $relation_ptr = $PT_relations_without_ref{$route_type}->{$relation_id};
                    $number_of_relations_without_ref++;

                    # match_network() returns either "keep long" or "keep short" or "skip" (to do: or "suspicious")
                    #
                    if ( $collected_tags{'network'} ) {
                        my $status = match_network(  $collected_tags{'network'} );
                    
                        if ( $status !~ m/keep/ ) {
                            $unused_networks{$collected_tags{'network'}}->{$relation_id} = 1;
                        }
                    }
                    else {
                        $unused_networks{'__unset_network__'}->{$relation_id} = 1;
                    }
                }
                
                if ( $relation_ptr ) {
        
                    while ( ($key,$value) = each( %collected_tags ) ) {
                        $relation_ptr->{'tag'}->{$key} = $value;
                        printf STDERR "%s relation_ptr->{'tag'}->{%s} = %s\n", get_time(), $relation_id, $key, $value    if ( $debug );
                    }
        
                    @{$relation_ptr->{'member'}}                = ();
                    @{$relation_ptr->{'relation'}}              = ();
                    @{$relation_ptr->{'route_master_relation'}} = ();
                    @{$relation_ptr->{'route_relation'}}        = ();
                    @{$relation_ptr->{'way'}}                   = ();
                    @{$relation_ptr->{'route_highway'}}         = ();
                    @{$relation_ptr->{'node'}}                  = ();
                    @{$relation_ptr->{'role_platform'}}         = ();
                    @{$relation_ptr->{'role_stop'}}             = ();
                    @{$relation_ptr->{'__issues__'}}            = ();
                    @{$relation_ptr->{'__notes__'}}             = ();
                    $member_index                    = 0;   # counts the number of all members
                    $relation_index                  = 0;   # counts the number of members which are relations (any relation: 'route' or with 'role' = 'platform', ...
                    $route_master_relation_index     = 0;   # counts the number of relation members in a 'route_master' which do not have 'role' ~ 'platform' (should be equal to $relation_index')
                    $route_relation_index            = 0;   # counts the number of relation members in a 'route' which do not have 'role' ~ 'platform' (should be zero)
                    $way_index                       = 0;   # counts the number of all way members
                    $route_highway_index             = 0;   # counts the number of ways members in a route which do not have 'role' ~ 'platform', i.e. those ways a bus really uses
                    $node_index                      = 0;   # counts the number of node members
                    $role_platform_index             = 0;   # counts the number of members which have 'role' '^platform.*'
                    $role_stop_index                 = 0;   # counts the number of members which have 'role' '^stop.*'
                    foreach $member ( @{$xml_hash_ref->{'member'}} ) {
                        if ( $member->{'type'} ) {
                            ${$relation_ptr->{'member'}}[$member_index]->{'type'} = $member->{'type'};
                            ${$relation_ptr->{'member'}}[$member_index]->{'ref'}  = $member->{'ref'};
                            ${$relation_ptr->{'member'}}[$member_index]->{'role'} = $member->{'role'};
                            $member_index++;
                            if ( $member->{'type'} eq 'relation' ) {
                                ${$relation_ptr->{'relation'}}[$relation_index]->{'ref'}  = $member->{'ref'};
                                ${$relation_ptr->{'relation'}}[$relation_index]->{'role'} = $member->{'role'};
                                $relation_index++;
                                if ( $type             eq 'route_master'     &&
                                     $member->{'role'} !~ m/^platform/    ) {
                                    ${$relation_ptr->{'route_master_relation'}}[$route_master_relation_index]->{'ref'}  = $member->{'ref'};
                                    ${$relation_ptr->{'route_master_relation'}}[$route_master_relation_index]->{'role'} = $member->{'role'};
                                    $route_master_relation_index++;
                                }
                                if ( $type             eq 'route'     &&
                                     $member->{'role'} !~ m/^platform/    ) {
                                    ${$relation_ptr->{'route_relation'}}[$route_relation_index]->{'ref'}  = $member->{'ref'};
                                    ${$relation_ptr->{'route_relation'}}[$route_relation_index]->{'role'} = $member->{'role'};
                                    $route_relation_index++;
                                }
                            }
                            elsif ( $member->{'type'} eq 'way' ) {
                                ${$relation_ptr->{'way'}}[$way_index]->{'ref'}  = $member->{'ref'};
                                ${$relation_ptr->{'way'}}[$way_index]->{'role'} = $member->{'role'};
                                $way_index++;
                                if ( $type             eq 'route'     &&
                                     $member->{'role'} !~ m/^platform/    ) {
                                    ${$relation_ptr->{'route_highway'}}[$route_highway_index]->{'ref'}  = $member->{'ref'};
                                    ${$relation_ptr->{'route_highway'}}[$route_highway_index]->{'role'} = $member->{'role'};
                                    $route_highway_index++;
                                }
                            }
                            elsif ( $member->{'type'} eq 'node' ) {
                                ${$relation_ptr->{'node'}}[$node_index]->{'ref'}  = $member->{'ref'};
                                ${$relation_ptr->{'node'}}[$node_index]->{'role'} = $member->{'role'};
                                $node_index++;
                            }
                            
                            if ( $member->{'role'} ) {
                                if ( $member->{'role'} =~ m/^platform/ ) {
                                    ${$relation_ptr->{'role_platform'}}[$role_platform_index]->{'type'} = $member->{'type'};
                                    ${$relation_ptr->{'role_platform'}}[$role_platform_index]->{'ref'}  = $member->{'ref'};
                                    ${$relation_ptr->{'role_platform'}}[$role_platform_index]->{'role'} = $member->{'role'};
                                    $role_platform_index++;
                                }
                                elsif ( $member->{'role'} =~ m/^stop/ ) {
                                    ${$relation_ptr->{'role_stop'}}[$role_stop_index]->{'type'} = $member->{'type'};
                                    ${$relation_ptr->{'role_stop'}}[$role_stop_index]->{'ref'}  = $member->{'ref'};
                                    ${$relation_ptr->{'role_stop'}}[$role_stop_index]->{'role'} = $member->{'role'};
                                    $role_stop_index++;
                                }
                            }
                        }
                    }
                }
                elsif ( $verbose ) {
                    ; #printf STDERR "%s relation_ptr not set for relation id %s\n", get_time(), $relation_id;
                }
            }
            else {
                printf STDERR "%s Suspicious: unset '%s' for relation id %s\n", get_time(), $type, $relation_id;
                $suspicious_relations{$relation_id} = 1;
                $number_of_suspicious_relations++;
            }
        }
        elsif ( $type eq 'multipolygon' ){
            #
            # secondly analyze multipolygon relations
            #
            if ( $collected_tags{'public_transport'}               &&
                 $collected_tags{'public_transport'} eq 'platform'    ) {
                while ( ($key,$value) = each( %collected_tags ) ) {
                    $PL_MP_relations{$relation_id}->{'tag'}->{$key} = $value;
                    printf STDERR "%s PL_MP_relation->{'tag'}->{%s} = %s\n", get_time(), $relation_id, $key, $value    if ( $debug );
                }
                $number_of_pl_mp_relations++;
            }
            else {
                printf STDERR "%s Suspicious: wrong type=multipolygon (not public_transport=platform) for relation id %s\n", get_time(), $relation_id;
                $suspicious_relations{$relation_id} = 1;
                $number_of_suspicious_relations++;
            }
        }
        elsif ($type eq 'public_transport' ) {
            #
            # thirdly analyze public_transport relations (stop_area, stop_area_group), not of interest though for the moment
            #
            if ( $collected_tags{'public_transport'}               &&
                 $collected_tags{'public_transport'} eq 'stop_area'    ) {
                while ( ($key,$value) = each( %collected_tags ) ) {
                    $SA_relations{$relation_id}->{'tag'}->{$key} = $value;
                    printf STDERR "%s SA_relation->{'tag'}->{%s} = %s\n", get_time(), $relation_id, $key, $value    if ( $debug );
                }
                $number_of_sa_relations++;
            }
            else {
                printf STDERR "%s Suspicious: wrong type=public_transport (not public_transport=stop_area) for relation id %s\n", get_time(), $relation_id;
                $suspicious_relations{$relation_id} = 1;
                $number_of_suspicious_relations++;
            }
        }
        elsif ($type eq 'network' ) {
            #
            # fourthly collect network relations (collection of public_transport relations), not of interes though for the moment and against the rule (relations are not categories)
            #
            # to do: collect network relations
            $suspicious_relations{$relation_id} = 1;
            $number_of_suspicious_relations++;
        }
        else {
            printf STDERR "%s Suspicious: unhandled type '%s' for relation id %s\n", get_time(), $type, $relation_id;
            $suspicious_relations{$relation_id} = 1;
            $number_of_suspicious_relations++;
        }
        
    }
    else {
        if ( $verbose ) {
            printf STDERR "%s Suspicious: unset 'type' for relation id %s\n", get_time(), $relation_id;
        }
        $suspicious_relations{$relation_id} = 1;
        $number_of_suspicious_relations++;
    }
}   

if ( $verbose ) {
    printf STDERR "%s Relations converted: %d, route_relations: %d, platform_mp_relations: %d, non_platform_mp_relations: %d, stop_area_relations: %d, network_relations: %d, positive: %d, negative: %d, skipped unmatched: %d, skipped other: %d, w/o ref: %d, suspicious: %d\n", 
                   get_time(),             
                   $number_of_relations, 
                   $number_of_route_relations,
                   $number_of_pl_mp_relations,
                   $number_of_non_pl_mp_relations,
                   $number_of_sa_relations,
                   $number_of_network_relations,
                   $number_of_positive_relations,
                   $number_of_negative_relations,
                   $number_of_skipped_relations,
                   $number_of_skipped_other_relations,
                   $number_of_relations_without_ref,
                   $number_of_suspicious_relations;
}


#############################################################################################
#
# if there are ways, lets convert them
#
#############################################################################################

if ( $xml_has_ways ) {
    printf STDERR "%s Converting ways\n", get_time()       if ( $verbose );
    
    foreach $way_id ( keys ( %{$routes_xml->{'way'}} ) ) {
        
        $number_of_ways++;
        
        $xml_hash_ref   = $routes_xml->{'way'}{$way_id};
        
        #
        # convert XML data like "<tag k='name' v='Ottobrunn' />" into: $WAYS{$way_id}->{'name'} = 'Ottobrunn'
        #
        foreach $tag ( @{$xml_hash_ref->{'tag'}} ) {
            if ( $tag->{'k'} ) {
                $WAYS{$way_id}->{'tag'}->{$tag->{'k'}} = $tag->{'v'};
                printf STDERR "%s WAYS{%s}->{'tag'}->{%s} = %s\n", get_time(), $way_id, $tag->{'k'}, $tag->{'v'}    if ( $debug );
            }
        }
        
        @{$WAYS{$way_id}->{'node_array'}} = ();
        #
        # push XML data like "<nd ref="3124033278"/>" to the array: $WAYS{$way_id}->{'node_array'}
        # mark ref="3124033278" as being found in an extra hash: $WAYS{$way_id}->{'node_hash'}
        #
        foreach $node ( @{$xml_hash_ref->{'nd'}} ) {
            if ( $node->{'ref'} ) {
                push( @{$WAYS{$way_id}->{'node_array'}}, $node->{'ref'} );
                printf STDERR "%s push( WAYS{%s}->{'node_array'}, %s )\n", get_time(), $way_id, $node->{'ref'}    if ( $debug );
                if ( $WAYS{$way_id}->{'node_hash'}->{$node->{'ref'}} ) {
                    $WAYS{$way_id}->{'node_hash'}->{$node->{'ref'}}++;
                }
                else {
                    $WAYS{$way_id}->{'node_hash'}->{$node->{'ref'}} = 1;
                }
                $WAYS{$way_id}->{'first_node'} = $node->{'ref'}     unless ( $WAYS{$way_id}->{'first_node'} );
                $WAYS{$way_id}->{'last_node'}  = $node->{'ref'};
            }
        }
        
        #
        # lets categorize the way as member or route or platform or ...
        #
        if ( $WAYS{$way_id}->{'tag'}->{'public_transport'}               && 
             $WAYS{$way_id}->{'tag'}->{'public_transport'} eq 'platform'    ) {
            $platform_ways{$way_id} = $WAYS{$way_id};
            $number_of_platformways++;
            $platform_ways{$way_id}->{'is_area'}   = 1 if ( $platform_ways{$way_id}->{'tag'}->{'area'} && $platform_ways{$way_id}->{'tag'}->{'area'} eq 'yes' );
            #printf STDERR "WAYS{%s} is a platform\n", $way_id;
        }
        else { #if ( ($WAYS{$way_id}->{'tag'}->{'highway'}                && 
               #  $WAYS{$way_id}->{'tag'}->{'highway'} ne 'platform')                               ||
               # ($WAYS{$way_id}->{'tag'}->{'railway'}                && 
               #  $WAYS{$way_id}->{'tag'}->{'railway'} =~ m/^rail|tram|subway|construction|razed$/) ||
               # ($WAYS{$way_id}->{'tag'}->{'route'}                  && 
               #  $WAYS{$way_id}->{'tag'}->{'route'} =~ m/^ferry$/)                                     ) {
            $route_ways{$way_id} = $WAYS{$way_id};
            $number_of_routeways++;
            $route_ways{$way_id}->{'is_roundabout'}   = 1   if ( $route_ways{$way_id}->{'first_node'} == $route_ways{$way_id}->{'last_node'} );
            #printf STDERR "WAYS{%s} is a highway\n", $way_id;
        }
        #else {
        #    printf STDERR "Unmatched way type for way: %s\n", $way_id;
        #}
    }

    if ( $verbose ) {
        printf STDERR "%s Ways converted: %d, route_ways: %d, platform_ways: %d\n", 
                       get_time(), $number_of_ways, $number_of_routeways, $number_of_platformways;
    }
}


#############################################################################################
#
# if there are nodes, lets convert them
#
#############################################################################################

if ( $xml_has_nodes ) {
    printf STDERR "%s Converting nodes\n", get_time()       if ( $verbose );
    
    foreach $node_id ( keys ( %{$routes_xml->{'node'}} ) ) {
        
        $number_of_nodes++;
        
        $xml_hash_ref   = $routes_xml->{'node'}{$node_id};
        
        #
        # convert XML data like "<tag k='name' v='Ottobrunn' />" into: $NODES{$node_id}->{'tag'}->{'name'} = 'Ottobrunn'
        foreach $tag ( @{$xml_hash_ref->{'tag'}} ) {
            if ( $tag->{'k'} ) {
                $NODES{$node_id}->{'tag'}->{$tag->{'k'}} = $tag->{'v'};
                printf STDERR "%s NODES{%s}->{'tag'}->{%s} = %s\n", get_time(), $node_id, $tag->{'k'}, $tag->{'v'}    if ( $debug );
            }
        }

        #
        # lets categorize the node as stop_position or platform or ...
        #
        if ( $NODES{$node_id}->{'tag'}->{'public_transport'}                    && 
             $NODES{$node_id}->{'tag'}->{'public_transport'} eq 'platform'    ) {
            $platform_nodes{$node_id} = $NODES{$node_id};
            $number_of_platformnodes++;
        }
        elsif ( $NODES{$node_id}->{'tag'}->{'public_transport'}                    && 
                $NODES{$node_id}->{'tag'}->{'public_transport'} eq 'stop_position'    ) {
            $stop_nodes{$node_id} = $NODES{$node_id};
            $number_of_stop_positions++;
        }
        else {
            ; # printf STDERR "Other type for node: %s\n", $node_id if ( $debug );
        }
    }

    if ( $verbose ) {
        printf STDERR "%s Nodes converted: %d, platform_nodes: %d, stop_positions: %d\n", 
                       get_time(), $number_of_nodes, $number_of_platformnodes, $number_of_stop_positions;
    }
}


#############################################################################################
# 
# output section begins here
#
#############################################################################################

printInitialHeader( $page_title, $osm_base, $areas  ); 


#############################################################################################
#
# now we print the list of all lines according to the list given by a CSV file
#
#############################################################################################

printf STDERR "%s Printing positives\n", get_time()       if ( $verbose );
$number_of_positive_relations= 0;

if ( $routes_file ) {
    
    $section = 'positive';
    
    my $table_headers_printed           = 0;
    my $working_on_entry                = '';
    my @route_types                     = ();
    my $relations_for_this_route_type   = 0;
    my $ExpectedRef                     = undef;
    my $ExpectedRouteType               = undef;
    my $ExpectedComment                 = undef;
    my $ExpectedFrom                    = undef;
    my $ExpectedTo                      = undef;
    my $ExpectedOperator                = undef;

    printTableInitialization( 'name', 'type', 'relation', 'PTv', 'issues', 'notes' );
    
    foreach $entry ( @routes_csv ) {
        next if ( $entry !~ m/\S/ );
        next if ( $entry =~ m/^#/ );
        if ( $entry =~ m/^=/ ) {
            printTableFooter()              if ( $table_headers_printed ); 
            printHeader( $entry );
            $table_headers_printed = 0;
            next;
        }
        elsif ( $entry =~ m/^-/ ) {
            if ( $table_headers_printed ) {
                printf STDERR "%s ignoring text inside table: %s\n", get_time(), $entry;
            }
            else {
                printText( $entry );
            }
            next;
        }

        if ( $table_headers_printed == 0 ) {
            printTableHeader();
            $table_headers_printed++;
            $working_on_entry = '';     # we start a new table, such as if there hasn't been any entry yet
        }
        $ExpectedRef                        =  $entry;
        $ExpectedRef                        =~ s/$csv_separator.*//;
        (undef,$ExpectedRouteType,@rest)    =  split( $csv_separator, $entry );
        $ExpectedComment  = $rest[0];
        $ExpectedFrom     = $rest[1];
        $ExpectedTo       = $rest[2];
        $ExpectedOperator = $rest[3];
        
        if ( $ExpectedRef ) {
            if ( $PT_relations_with_ref{$section}->{$ExpectedRef} ) {
                $relations_for_this_route_type = ($ExpectedRouteType) 
                                                    ? scalar(keys(%{$PT_relations_with_ref{$section}->{$ExpectedRef}->{'route_master'}->{$ExpectedRouteType}})) + 
                                                      scalar(keys(%{$PT_relations_with_ref{$section}->{$ExpectedRef}->{'route'}->{$ExpectedRouteType}})) 
                                                    : scalar(keys(%{$PT_relations_with_ref{$section}->{$ExpectedRef}}));
                if ( $relations_for_this_route_type ) {
                    foreach $type ( 'route_master', 'route' ) {
                        if ( $PT_relations_with_ref{$section}->{$ExpectedRef}->{$type} ) {
                            if ( $ExpectedRouteType ) {
                                @route_types = ( $ExpectedRouteType );
                            }
                            else {
                                @route_types = sort( keys( %{$PT_relations_with_ref{$section}->{$ExpectedRef}->{$type}} ) );
                            }
                            foreach $ExpectedRouteType ( @route_types ) {
                                foreach $relation_id ( sort( { $PT_relations_with_ref{$section}->{$ExpectedRef}->{$type}->{$ExpectedRouteType}->{$a}->{'tag'}->{'sort_name'} cmp 
                                                               $PT_relations_with_ref{$section}->{$ExpectedRef}->{$type}->{$ExpectedRouteType}->{$b}->{'tag'}->{'sort_name'}     } 
                                                             keys(%{$PT_relations_with_ref{$section}->{$ExpectedRef}->{$type}->{$ExpectedRouteType}})) ) {
                                    $relation_ptr = $PT_relations_with_ref{$section}->{$ExpectedRef}->{$type}->{$ExpectedRouteType}->{$relation_id};
                                    if ( $entry ne $working_on_entry ) {
                                        printTableSubHeader( 'ref'      => $relation_ptr->{'tag'}->{'ref'},
                                                             'network'  => $relation_ptr->{'tag'}->{'network'},
                                                             'pt_type'  => $ExpectedRouteType,
                                                             'colour'   => $relation_ptr->{'tag'}->{'colour'},
                                                             'Comment'  => $ExpectedComment,
                                                             'From'     => $ExpectedFrom,
                                                             'To'       => $ExpectedTo,
                                                             'Operator' => $ExpectedOperator         );
                                        $working_on_entry = $entry;
                                    }
                                    
                                    @{$relation_ptr->{'__issues__'}} = ();
                                    @{$relation_ptr->{'__notes__'}}  = ();

                                    if ( $refs_of_interest{$ExpectedRef}->{$ExpectedRouteType} > 1 && $multiple_ref_type_entries ne 'allow')
                                    {
                                        #
                                        # for this 'ref' and 'route_type' we have more than one entry in the CSV file
                                        # i.e. there are doubled lines (example: DE-HB-VBN: bus routes 256, 261, 266, ... appear twice in different areas of the network)
                                        # we should be able to distinguish them by their 'operator' values
                                        # this requires the operator to be stated in the CSV file as Expected Operator and the tag 'operator' being set in the relation
                                        #
                                        if ( $ExpectedOperator && $relation_ptr->{'tag'}->{'operator'} ) {
                                            if ( $ExpectedOperator eq $relation_ptr->{'tag'}->{'operator'} ) {
                                                push( @{$relation_ptr->{'__notes__'}}, "There is more than one public transport service for this 'ref'. 'operator' value of this relation fits to expected operator value." );
                                            } else {
                                                printf STDERR "%s Skipping relation %s, 'ref' %s: 'operator' does not match expected operator (%s vs %s)\n", get_time(), $relation_id, $ExpectedRef, $relation_ptr->{'tag'}->{'operator'}, $ExpectedOperator; 
                                                next;
                                            }
                                        } else {
                                            if ( !$ExpectedOperator && !$relation_ptr->{'tag'}->{'operator'} ) {
                                                push( @{$relation_ptr->{'__notes__'}}, "There is more than one public transport service for this 'ref'. Please set 'operator' value for this relation and set operator value in the CSV file." );
                                            } elsif ( $ExpectedOperator ) {
                                                push( @{$relation_ptr->{'__notes__'}}, "There is more than one public transport service for this 'ref'. Please set operator value in the CSV file to match the mapped opeator value (or vice versa)." );
                                            } else {
                                                push( @{$relation_ptr->{'__notes__'}}, "There is more than one public transport service for this 'ref'. Please set 'operator' value for this relation to match an expected operator value (or vice versa)." );
                                            }
                                        }
                                    }
                                    $status = analyze_environment( $PT_relations_with_ref{$section}->{$ExpectedRef}, $ExpectedRef, $type, $ExpectedRouteType, $relation_id );
    
                                    $status = analyze_relation( $relation_ptr, $relation_id );
                                    
                                    printTableLine( 'ref'           =>    $relation_ptr->{'tag'}->{'ref'},
                                                    'relation'      =>    $relation_id,
                                                    'type'          =>    $type,
                                                    'route_type'    =>    $ExpectedRouteType,
                                                    'name'          =>    $relation_ptr->{'tag'}->{'name'},
                                                    'network'       =>    $relation_ptr->{'tag'}->{'network'},
                                                    'operator'      =>    $relation_ptr->{'tag'}->{'operator'},
                                                    'from'          =>    $relation_ptr->{'tag'}->{'from'},
                                                    'via'           =>    $relation_ptr->{'tag'}->{'via'},
                                                    'to'            =>    $relation_ptr->{'tag'}->{'to'},
                                                    'PTv'           =>    ($relation_ptr->{'tag'}->{'public_transport:version'} ? $relation_ptr->{'tag'}->{'public_transport:version'} : '?'),
                                                    'issues'        =>    join( '__separator__', @{$relation_ptr->{'__issues__'}} ),
                                                    'notes'         =>    join( '__separator__', @{$relation_ptr->{'__notes__'}}  )
                                                  );
                                    $number_of_positive_relations++;
                                }
                            }
                        }
                    }
                }
                else {
                    #
                    # we do not have a line which fits to the requested 'ref' and 'route_type' combination
                    #
                    if ( $entry ne $working_on_entry ) {
                        printTableSubHeader( 'ref'      => $ExpectedRef,
                                             'Comment'  => $ExpectedComment,
                                             'From'     => $ExpectedFrom,
                                             'To'       => $ExpectedTo,
                                             'Operator' => $ExpectedOperator         );
                        $working_on_entry = $entry;
                    }
                    printTableLine( 'issues'        =>    sprintf("Missing route for ref='%s' and route='%s'", $ExpectedRef, $ExpectedRouteType)
                                  );
                }
            }
            else {
                #
                # we do not have a line which fits to the requested 'ref'
                #
                if ( $entry ne $working_on_entry ) {
                    printTableSubHeader( 'ref'      => $ExpectedRef,
                                         'Comment'  => $ExpectedComment,
                                         'From'     => $ExpectedFrom,
                                         'To'       => $ExpectedTo,
                                         'Operator' => $ExpectedOperator         );
                    $working_on_entry = $entry;
                }
                printTableLine( 'issues'        =>    sprintf("Missing route for ref='%s' and route='%s'", $ExpectedRef, $ExpectedRouteType),
                              );
            }
        }
        else {
            printf STDERR "%s Internal error: ref and route_type not set in CSV file. %s\n", get_time(), $entry;
        }
    }
    
    printTableFooter()  if ( $table_headers_printed ); 
    
    printFooter();

}

printf STDERR "%s Printed positives: %d\n", get_time(), $number_of_positive_relations       if ( $verbose );


#############################################################################################
#
# now we print the list of all remainig relations/lines that could not be associated or when there was no csv file
#
#############################################################################################

printf STDERR "%s Printing others\n", get_time()       if ( $verbose );
$number_of_negative_relations = 0;

my @line_refs = ();

$section = 'negative';
@line_refs = sort( keys( %{$PT_relations_with_ref{$section}} ) );

if ( scalar(@line_refs) ) {
    my $help;
    my $route_type_lines = 0;
    
    printTableInitialization( 'ref', 'relation', 'type', 'route_type', 'name', 'network', 'operator', 'from', 'via', 'to', 'PTv', 'issues', 'notes' );

    if ( $routes_file ) {
        printBigHeader( 'Andere ÖPNV Linien' );
    }
    else {
        printBigHeader( 'ÖPNV Linien' );
    }


    foreach $route_type ( @supported_route_types ) {
        
        $route_type_lines = 0;
        foreach $ref ( @line_refs ) {
            foreach $type ( 'route_master', 'route' ) {
                $route_type_lines += scalar(keys(%{$PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}}));
            }
        }
        if ( $route_type_lines ) {
            $help = sprintf( "== %s", ($transport_types{$route_type} ? $transport_types{$route_type} : $route_type) );
            printHeader( $help );
            printTableHeader();
            foreach $ref ( @line_refs ) {
                foreach $type ( 'route_master', 'route' ) {
                    foreach $relation_id ( sort( { $PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}->{$a}->{'tag'}->{'sort_name'} cmp 
                                                   $PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}->{$b}->{'tag'}->{'sort_name'}     } 
                                                 keys(%{$PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}})) ) {
                        $relation_ptr = $PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}->{$relation_id};
    
                        # $status = analyze_environment( $PT_relations_with_ref{$section}->{$ref}, $relation_ptr->{'tag'}->{'ref'}, $type, $route_type, $relation_id );
    
                        $status = analyze_relation( $relation_ptr, $relation_id );
                                    
                        printTableLine( 'ref'           =>    $relation_ptr->{'tag'}->{'ref'},
                                        'relation'      =>    $relation_id,
                                        'type'          =>    $type,
                                        'route_type'    =>    $route_type,
                                        'name'          =>    $relation_ptr->{'tag'}->{'name'},
                                        'network'       =>    $relation_ptr->{'tag'}->{'network'},
                                        'operator'      =>    $relation_ptr->{'tag'}->{'operator'},
                                        'from'          =>    $relation_ptr->{'tag'}->{'from'},
                                        'via'           =>    $relation_ptr->{'tag'}->{'via'},
                                        'to'            =>    $relation_ptr->{'tag'}->{'to'},
                                        'PTv'           =>    ($relation_ptr->{'tag'}->{'public_transport:version'} ? $relation_ptr->{'tag'}->{'public_transport:version'} : '?'),
                                        'issues'        =>    join( '__separator__', @{$relation_ptr->{'__issues__'}} ),
                                        'notes'         =>    join( '__separator__', @{$relation_ptr->{'__notes__'}} )
                                      );
                        $number_of_negative_relations++;
                    }
                }
            }
            printTableFooter(); 
        }
    }
}

printf STDERR "%s Printed others: %d\n", get_time(), $number_of_negative_relations       if ( $verbose );


#############################################################################################
#
# now we print the routes/route-masters having no 'ref'
#
#############################################################################################

printf STDERR "%s Printing those w/o 'ref'\n", get_time()       if ( $verbose );
$number_of_relations_without_ref = 0;

my @route_types = sort( keys( %PT_relations_without_ref ) );

if ( scalar(@route_types) ) {
    my $help;
    
    printTableInitialization( 'relation', 'type', 'route_type', 'name', 'network', 'operator', 'from', 'via', 'to', 'PTv', 'issues', 'notes' );
    
    printBigHeader( "ÖPNV Linien ohne 'ref'" );
    
    foreach $route_type ( @route_types ) {
        $help = sprintf( "== %s", ($transport_types{$route_type} ? $transport_types{$route_type} : $route_type) );
        printHeader( $help );
        printTableHeader();
        foreach $relation_id ( sort( { $PT_relations_without_ref{$route_type}->{$a}->{'tag'}->{'sort_name'} cmp 
                                       $PT_relations_without_ref{$route_type}->{$b}->{'tag'}->{'sort_name'}     } 
                                     keys(%{$PT_relations_without_ref{$route_type}})) ) {
            $relation_ptr = $PT_relations_without_ref{$route_type}->{$relation_id};

            $status = analyze_relation( $relation_ptr, $relation_id );
                                
            printTableLine( 'relation'      =>    $relation_id,
                            'type'          =>    $relation_ptr->{'tag'}->{'type'},
                            'route_type'    =>    $route_type,
                            'name'          =>    $relation_ptr->{'tag'}->{'name'},
                            'network'       =>    $relation_ptr->{'tag'}->{'network'},
                            'operator'      =>    $relation_ptr->{'tag'}->{'operator'},
                            'from'          =>    $relation_ptr->{'tag'}->{'from'},
                            'via'           =>    $relation_ptr->{'tag'}->{'via'},
                            'to'            =>    $relation_ptr->{'tag'}->{'to'},
                            'PTv'           =>    ($relation_ptr->{'tag'}->{'public_transport:version'} ? $relation_ptr->{'tag'}->{'public_transport:version'} : '?'),
                            'issues'        =>    join( '__separator__', @{$relation_ptr->{'__issues__'}} ),
                            'notes'         =>    join( '__separator__', @{$relation_ptr->{'__notes__'}} )
                          );
            $number_of_relations_without_ref++;
        }
        printTableFooter(); 
    }
}

printf STDERR "%s Printed those w/o 'ref': %d\n", get_time(), $number_of_relations_without_ref       if ( $verbose );


#############################################################################################
#
# now we print the list of all suspicious relations
#
#############################################################################################

printf STDERR "%s Printing suspicious\n", get_time()       if ( $verbose );

printTableInitialization( 'relation', 'type', 'route_type', 'ref', 'name', 'network', 'operator', 'from', 'via', 'to', 'PTv', 'public_transport' );

my @suspicious_relations = sort( keys( %suspicious_relations ) );

if ( scalar(@suspicious_relations) ) {
    
    $number_of_suspicious_relations = 0;

    printBigHeader( 'Verdächtige Relationen' );

    printHintSuspiciousRelations();
        
    printTableHeader();

    foreach $relation_id ( @suspicious_relations ) {
        $relation_ptr = $RELATIONS{$relation_id};

        printTableLine( 'relation'          =>    $relation_id,
                        'type'              =>    $relation_ptr->{'tag'}->{'type'},
                        'route_type'        =>    ($relation_ptr->{'tag'}->{'type'} && ($relation_ptr->{'tag'}->{'type'} eq 'route' || $relation_ptr->{'tag'}->{'type'} eq 'route_master')) ? $relation_ptr->{'tag'}->{$relation_ptr->{'tag'}->{'type'}} : '',
                        'ref'               =>    $relation_ptr->{'tag'}->{'ref'},
                        'name'              =>    $relation_ptr->{'tag'}->{'name'},
                        'network'           =>    $relation_ptr->{'tag'}->{'network'},
                        'operator'          =>    $relation_ptr->{'tag'}->{'operator'},
                        'from'              =>    $relation_ptr->{'tag'}->{'from'},
                        'via'               =>    $relation_ptr->{'tag'}->{'via'},
                        'to'                =>    $relation_ptr->{'tag'}->{'to'},
                        'PTv'               =>    $relation_ptr->{'tag'}->{'public_transport:version'},
                        'public_transport'  =>    $relation_ptr->{'tag'}->{'public_transport'},
                      );
        $number_of_suspicious_relations++;
    }
    printTableFooter(); 
}

printf STDERR "%s Printed suspicious: %d\n", get_time(), $number_of_suspicious_relations       if ( $verbose );


#############################################################################################
#
# now we print the list of all unused network values
#
#############################################################################################

printf STDERR "%s Printing unused networks\n", get_time()       if ( $verbose );

printTableInitialization( 'network', 'relations' );

my @relations_of_network    = ();

if ( keys( %unused_networks ) ) {
    
    $number_of_unused_networks = 0;

    printBigHeader( "Nicht berücksichtigte 'network'-Werte" );

    printHintUnusedNetworks();
        
    printTableHeader();

    foreach my $network ( sort( keys( %unused_networks ) ) ) {
        @relations_of_network    = sort( keys( %{$unused_networks{$network}} ) );
        $network = $network eq '__unset_network__' ? '' : $network;
        if ( scalar @relations_of_network <= 10 ) {
            printTableLine( 'network'           =>    $network,
                            'relations'         =>    join( ',', @relations_of_network )
                          );
        }
        else {
            printTableLine( 'network'           =>    $network,
                            'relations'         =>    sprintf( "%s and more ...", join( ',', splice(@relations_of_network,0,10) ) )
                          );
        }
        $number_of_unused_networks++;
    }
    printTableFooter(); 
}

printf STDERR "%s Printed unused networks: %d\n", get_time(), $number_of_unused_networks       if ( $verbose );


#############################################################################################
#
# now we print the list of all rool options and their values
#
#############################################################################################

if ( $show_options ) {
    printf STDERR "%s Printing tool options\n", get_time()       if ( $verbose );
    
    printTableInitialization( 'Option', 'Wert', 'Anmerkung' );
    
    printBigHeader( "Auswertungsoptionen" );
    
    printToolOptions();    
    
    printf STDERR "%s Printed tool options\n", get_time()   if ( $verbose );
}


#############################################################################################

printFinalFooter(); 

printf STDERR "%s Done ...\n", get_time()       if ( $verbose );


#############################################################################################

sub match_route_type {
    my $route_type = shift;
    my $rt          = undef;

    if ( $route_type ) {
        foreach my $rt ( @supported_route_types )
        {
            if ( $route_type eq $rt ) {
                printf STDERR "%s Keeping route_type: %s\n", get_time(), $route_type       if ( $debug );
                return 'keep';
            }
            elsif ( $route_type =~ m/$rt/ ) {
                printf STDERR "%s Suspicious route_type: %s\n", get_time(), $route_type    if ( $debug );
                return 'suspicious';
            }
        }
        #if ( $route_type =~ m/^$regex_supported_route_types$/ ) {
        #    printf STDERR "%s Keeping route_type: %s\n", get_time(), $route_type       if ( $debug );
        #    return 'keep';
        #}
        #elsif ( $route_type =~ m/$regex_supported_route_types/ ) {
        #    printf STDERR "%s Suspicious route_type: %s\n", get_time(), $route_type    if ( $debug );
        #    return 'suspicious';
        #}
        #else {
        #    printf STDERR "%s Skipping route_type: %s\n", get_time(), $route_type       if ( $debug );
        #    return 'skip';
        #}
    }

    printf STDERR "%s Finally skipping route_type: %s\n", get_time(), $route_type       if ( $debug );

    return 'skip';
}


#############################################################################################

sub match_network {
    my $network = shift;

    if ( $network ) {
        if ( $network_long_regex || $network_short_regex ) {
            if ( $network_long_regex  && $network =~ m/$network_long_regex/ ) {
                return 'keep long';
            }
            elsif ( $network_short_regex && $network =~ m/$network_short_regex/ ) {
                return 'keep short';
            }
            else {
                printf STDERR "%s Skipping network: %s\n", get_time(), $network        if ( $debug );
                return 'skip';
            }
        }
    }
    else {
        if ( $strict_network ) {
            printf STDERR "%s Skipping unset network\n", get_time()                   if ( $debug );
            return 'skip';
        }
    }

    return 'keep';
}


#############################################################################################

sub match_operator {
    my $operator = shift;

    if ( $operator ) {
        if ( $operator_regex ) {
            if ( $operator !~ m/$operator_regex/   ) {
                printf STDERR "%s Skipping operator: %s\n", get_time(), $operator        if ( $debug );
                return 'skip';
            }
        }
    }
    else {
        if ( $strict_operator ) {
            printf STDERR "%s Skipping unset operator\n", get_time()                   if ( $debug );
            return 'skip';
        }
    }

    return 'keep';
}


#############################################################################################

sub match_ref_and_pt_type {
    my $ref             = shift;
    my $pt_type         = shift;

    if ( $ref && $pt_type ) {
        return 'keep positive'      if ( $refs_of_interest{$ref}->{$pt_type} );
        return 'keep positive'      if ( $refs_of_interest{$ref}->{__any__}  );
    }
    else {
        printf STDERR "%s Skipping unset ref or unset type: %s/%s\n", get_time()        if ( $verbose );
        return 'skip';
    }
    printf STDERR "%s Keeping negative ref/type: %s/%s\n", get_time(), $ref, $pt_type   if ( $debug );
    return 'keep negative';
}


#############################################################################################

sub analyze_environment {
    my $ref_ref         = shift;
    my $ref             = shift;
    my $type            = shift;
    my $route_type      = shift;
    my $relation_id     = shift;
    my $return_code     = 0;
    
    my $relation_ptr    = undef;
    
    if ( $ref_ref && $ref && $type && $route_type && $relation_id ) {
        
        $relation_ptr = $ref_ref->{$type}->{$route_type}->{$relation_id};
        
        if ( $relation_ptr ) {

            if ( $type eq 'route_master' ) {
                $return_code = analyze_route_master_environment( $ref_ref, $ref, $type, $route_type, $relation_id );
            }
            elsif ( $type eq 'route') {
                $return_code = analyze_route_environment( $ref_ref, $ref, $type, $route_type, $relation_id );
            }
        }
    }

    return $return_code;
}


#############################################################################################

sub analyze_route_master_environment {
    my $ref_ref         = shift;
    my $ref             = shift;
    my $type            = shift;
    my $route_type      = shift;
    my $relation_id     = shift;
    my $return_code     = 0;
    
    my $relation_ptr            = undef;
    my $number_of_route_masters = 0;
    my $number_of_routes        = 0;
    my $number_of_my_routes     = 0;
    my %my_routes               = ();
    
    if ( $ref_ref && $ref && $type && $type eq 'route_master' && $route_type && $relation_id ) {
        
        # do we have more than one route_master here for this "ref" and "route_type"?
        $number_of_route_masters    = scalar( keys( %{$ref_ref->{'route_master'}->{$route_type}} ) );
        
        # how many routes do we have at all for this "ref" and "route_type"?
        $number_of_routes           = scalar( keys( %{$ref_ref->{'route'}->{$route_type}} ) );

        # reference to this relation, the route_master under examination
        $relation_ptr               = $ref_ref->{'route_master'}->{$route_type}->{$relation_id};
        
        # if this is a route_master and PTv2 is set, then 
        # 1. check route_master_relation number against number of 'route' relations below this ref_ref with same route_type (same number?)
        # 2. check 'route' relations and their 'relation_id' against the member list (do all 'route' members actually exist?)

        if ( $number_of_route_masters > 1 ) {
            #
            # that's OK if they belong to different 'network' ('network' has to be set though)
            # that's OK if they belong to same 'network' but are operated by different 'operator' ('operator' has to be set though)
            #
            my %networks            = ();
            my %operators           = ();
            my $num_of_networks     = 0;
            my $num_of_operators    = 0;
            my $temp_relation_ptr   = undef;
            foreach my $rel_id ( keys( %{$ref_ref->{'route_master'}->{$route_type}} ) ) {
                $temp_relation_ptr = $ref_ref->{'route_master'}->{$route_type}->{$rel_id};
                
                # how many routes are members of this route_master?
                $number_of_my_routes        += scalar( @{$temp_relation_ptr->{'route_master_relation'}} );
                
                foreach my $member_ref ( @{$temp_relation_ptr->{'route_master_relation'}} ) {
                    $my_routes{$member_ref->{'ref'}} = 1;
                }
                
                if ( $temp_relation_ptr->{'tag'}->{'network'} ) {
                    $networks{$temp_relation_ptr->{'tag'}->{'network'}} = 1;
                    #printf STDERR "analyze_route_master_environment(): network = %s\n", $temp_relation_ptr->{'tag'}->{'network'};
                }
                
                if ( $temp_relation_ptr->{'tag'}->{'operator'} ) {
                    $operators{$temp_relation_ptr->{'tag'}->{'operator'}} = 1;
                    #printf STDERR "analyze_route_master_environment(): operator = %s\n", $temp_relation_ptr->{'tag'}->{'operator'};
                }
            }
            $num_of_networks  = scalar( keys ( %networks  ) );
            $num_of_operators = scalar( keys ( %operators ) );
            #printf STDERR "analyze_route_master_environment(): num_of_networks = %s, num_of_operators = %s\n", $num_of_networks, $num_of_operators;
            if ( $num_of_networks < 2 && $num_of_operators < 2 ) {
                push( @{$relation_ptr->{'__issues__'}}, "There is more than one Route-Master for this line" );
            }
            if ( $number_of_my_routes > $number_of_routes ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("Route-Masters have more Routes than actually exist (%d versus %d) in the given data set", $number_of_my_routes, $number_of_routes) );
            }
            elsif ( $number_of_my_routes < $number_of_routes ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("Route-Masters have less Routes than actually exist (%d versus %d) in the given data set", $number_of_my_routes, $number_of_routes) );
            }
        }
        else {
            # how many routes are members of this route_master?
            $number_of_my_routes        = scalar( @{$relation_ptr->{'route_master_relation'}} );
        
            if ( $number_of_my_routes > $number_of_routes ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("Route-Master has more Routes than actually exist (%d versus %d) in the given data set", $number_of_my_routes, $number_of_routes) );
            }
            elsif ( $number_of_my_routes < $number_of_routes ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("Route-Master has less Routes than actually exist (%d versus %d) in the given data set", $number_of_my_routes, $number_of_routes) );
            }
        }
        
        # check whether all my member routes actually exist, tell us which one does not
        foreach my $member_ref ( @{$relation_ptr->{'route_master_relation'}} ) {
            $my_routes{$member_ref->{'ref'}} = 1;
            if ( !defined($ref_ref->{'route'}->{$route_type}->{$member_ref->{'ref'}}) ) {
                #
                # relation_id points to a route which has different 'ref' or does not exist in data set
                #
                if ( $RELATIONS{$member_ref->{'ref'}} ) {
                    #
                    # relation is included in XML input file but has no 'ref' or 'ref' is different from 'ref' or route_master
                    #
                    if ( $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'ref'} ) {
                        if ( $ref eq $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'ref'} ) {
                            #
                            # 'ref' is the same, check for other problems
                            #
                            if ( $relation_ptr->{'tag'}->{'network'} && $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'} ) {
                                if ( $relation_ptr->{'tag'}->{'network'} eq $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'} ) {
                                    ; # hmm should not happen here
                                    printf STDERR "%s Route of Route-Master not found although 'ref' and 'network' are equal. Route-Master: %s, Route: %s, 'ref': %s, 'network': %s\n", get_time(), $relation_id, $member_ref->{'ref'}, $ref, $relation_ptr->{'tag'}->{'network'};
                                }
                                else {
                                    # 'ref' tag is set and is same but 'network' is set and differs
                                    push( @{$relation_ptr->{'__issues__'}}, sprintf("Route has different 'network' tag ('%s'): %s", $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'}, printRelationTemplate($member_ref->{'ref'}) ) );
                                }
                            }
                            elsif ( $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'} ) {
                                # 'ref' tag is set and is same but 'network' is strange
                                push( @{$relation_ptr->{'__issues__'}}, sprintf("Route has strange 'network' tag ('%s'): %s", $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'}, printRelationTemplate($member_ref->{'ref'}) ) );
                                $suspicious_relations{$member_ref->{'ref'}} = 1;
                                $number_of_suspicious_relations++;
                            }
                        }
                        else {
                            # 'ref' tag is set but differs
                            push( @{$relation_ptr->{'__issues__'}}, sprintf("Route has different 'ref' tag ('%s'): %s", $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'ref'}, printRelationTemplate($member_ref->{'ref'}) ) );
                        }
                    }
                    else {
                        # 'ref' tag is not set
                        push( @{$relation_ptr->{'__issues__'}}, sprintf("Route exists but 'ref' tag is not set: %s", printRelationTemplate($member_ref->{'ref'}) ) );
                    }
                }
                else {
                    #
                    # relation is not included in XML input file
                    #
                    push( @{$relation_ptr->{'__issues__'}}, sprintf("Route does not exist in the given data set: %s", printRelationTemplate($member_ref->{'ref'}) ) );
                }
            }
        }
        # check whether all found relations are member of this/these route master(s), tell us which one is not
        foreach my $rel_id ( sort( keys( %{$ref_ref->{'route'}->{$route_type}} ) ) ) {
            if ( !defined($my_routes{$rel_id}) ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("Route is not member of this Router-Master: %s", printRelationTemplate($rel_id) ) );
            }
        }
    }

    return $return_code;
}


#############################################################################################

sub analyze_route_environment {
    my $ref_ref         = shift;
    my $ref             = shift;
    my $type            = shift;
    my $route_type      = shift;
    my $relation_id     = shift;
    my $return_code     = 0;
    
    my $relation_ptr                = undef;
    my $number_of_route_masters     = 0;
    my $number_of_routes            = 0;
    my $is_member_of_route_masters  = 0;
    
    if ( $ref_ref && $ref && $type && $type eq 'route' && $route_type && $relation_id ) {
        
        $relation_ptr = $ref_ref->{'route'}->{$route_type}->{$relation_id};
        
        # do we have more than one route_master here for this "ref" and "route_type"?
        $number_of_route_masters    = scalar( keys( %{$ref_ref->{'route_master'}->{$route_type}} ) );
        
        # how many routes do we have at all for this "ref" and "route_type"?
        $number_of_routes           = scalar( keys( %{$ref_ref->{'route'}->{$route_type}} ) );
        
        # if this is a route and PTv2 is set, then 
        # 1. check if we have more than one route here
        # 2. if there are more than one route, check whether we have a route_master which has these routes as members

        foreach my $rel_id ( sort( keys( %{$ref_ref->{'route_master'}->{$route_type}} ) ) ) {
            if ( $relation_ptr->{'tag'}->{'network'}                                         &&
                 $ref_ref->{'route_master'}->{$route_type}->{$rel_id}->{'tag'}->{'network'}  &&
                 $relation_ptr->{'tag'}->{'network'}                                         ne $ref_ref->{'route_master'}->{$route_type}->{$rel_id}->{'tag'}->{'network'} ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("'network' of Route does not fit to 'network' of Route-Master: %s", printRelationTemplate($rel_id)) );
            }
            if ( $relation_ptr->{'tag'}->{'colour'} ) {
                if ( $ref_ref->{'route_master'}->{$route_type}->{$rel_id}->{'tag'}->{'colour'} ) {
                    if ( uc($relation_ptr->{'tag'}->{'colour'}) ne uc($ref_ref->{'route_master'}->{$route_type}->{$rel_id}->{'tag'}->{'colour'}) ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf("'colour' of Route does not fit to 'colour' of Route-Master: %s", printRelationTemplate($rel_id)) );
                    }
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf("'colour' of Route is set but 'colour' of Route-Master is not set: %s", printRelationTemplate($rel_id)) );
                }
            }
            elsif ( $ref_ref->{'route_master'}->{$route_type}->{$rel_id}->{'tag'}->{'colour'} ) {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf("'colour' of Route is not set but 'colour' of Route-Master is set: %s", printRelationTemplate($rel_id)) );
            }
            foreach my $member_ref ( @{$ref_ref->{'route_master'}->{$route_type}->{$rel_id}->{'route_master_relation'}} ) {
                if ( $relation_id == $member_ref->{'ref'} ) {
                    $is_member_of_route_masters++;
                }
            }
        }
        if ( $number_of_routes > 1 && $number_of_route_masters == 0 ) {
            push( @{$relation_ptr->{'__issues__'}}, "Multiple Routes but no Route-Master" );
        }
        if ( $relation_ptr->{'tag'}->{'public_transport:version'} ) {
            if ( $relation_ptr->{'tag'}->{'public_transport:version'} =~ m/^2$/ ) {
                if ( $number_of_route_masters == 0 ) {
                    # push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: there is no Route-Master for this line in the given data set" );
                    ;
                }
                elsif ( $is_member_of_route_masters == 0 ) {
                    push( @{$relation_ptr->{'__issues__'}}, "PTv2 route: Route is not member of an existing Route-Master of this line" );
                }
            }
            else {
                if ( $number_of_routes > 1 ) {
                    push( @{$relation_ptr->{'__issues__'}}, "Multiple Routes but 'public_transport:version' is not set to '2'" );
                }
            }
        }
    }

    return $return_code;
}


#############################################################################################

sub analyze_relation {
    my $relation_ptr    = shift;
    my $relation_id     = shift;
    my $return_code     = 0;
    
    my $ref                             = '';
    my $type                            = '';
    my $route_type                      = '';
    my $network                         = '';
    my $operator                        = '';
    my $member_index                    = 0;
    my $relation_index                  = 0;
    my $route_master_relation_index     = 0;    # counts number of relation members in a 'route_master' which are not 'platforms' (should be equal to $relation_index')
    my $route_relation_index            = 0;    # counts number of relation members in a 'route' which are not 'platforms'
    my $way_index                       = 0;    # counts number of all way members
    my $route_highway_index             = 0;    # counts number of ways members in a route which are not 'platforms'
    my $node_index                      = 0;
    my @specialtags                     = ( 'comment', 'note', 'fixme', 'check_date' );
    my $specialtag                      = undef;
    my %specialtag2reporttype           = ( 'comment'       => '__notes__',
                                            'note'          => '__issues__',
                                            'fixme'         => '__issues__',
                                            'check_date'    => '__notes__'
                                          );
    my $reporttype                      = undef;
    my $wide_characters                 = '';
    
    if ( $relation_ptr ) {
        
        $ref                            = $relation_ptr->{'tag'}->{'ref'};
        $type                           = $relation_ptr->{'tag'}->{'type'};
        $route_type                     = $relation_ptr->{'tag'}->{$type};

        #
        # now, check existing and defined tags and report them to front of list (ISSUES, NOTES)
        #
        
        foreach $specialtag ( @specialtags ) {
            foreach my $tag ( sort(keys(%{$relation_ptr->{'tag'}})) ) {
                if ( $tag =~ m/^$specialtag/i ) {
                    if ( $relation_ptr->{'tag'}->{$tag} ) {
                        $reporttype = ( $specialtag2reporttype{$specialtag} ) ? $specialtag2reporttype{$specialtag} : '__notes__';
                        if ( $tag =~ m/^note$/i ){
                            $help =  $relation_ptr->{'tag'}->{$tag};
                            $help =~ s|^https{0,1}://wiki.openstreetmap.org\S+\s*[;,_+#\.\-]*\s*||;
                            unshift( @{$relation_ptr->{$reporttype}}, sprintf("'%s' ~ %s", $tag, $help) )  if ( $help );
                        }
                        else {
                            unshift( @{$relation_ptr->{$reporttype}}, sprintf("'%s' = %s", $tag, $relation_ptr->{'tag'}->{$tag}) )
                        }
                    }
                }
            }
        }

        #
        # now check existance of required/optional tags
        #
        
        push( @{$relation_ptr->{'__issues__'}}, "'ref' is not set" )        unless ( $ref ); 
        
        push( @{$relation_ptr->{'__issues__'}}, "'name' is not set" )       unless ( $relation_ptr->{'tag'}->{'name'} );

        $network = $relation_ptr->{'tag'}->{'network'};
        if ( $network ) {
            my $expected_long  = $expect_network_long_for  || '';
            my $expected_short = $expect_network_short_for || '';

            $expected_long  =~ s/;/,/g;
            $expected_long  =  ',' . $expected_long . ',';
            $expected_short =~ s/;/,/g;
            $expected_short =  ',' . $expected_short . ',';


            if ( $expected_short =~ m/,$network,/ ) {
                push( @{$relation_ptr->{'__notes__'}}, "'network' is long form" );
            }
            elsif ( $expected_long =~ m/,$network,/ ) {
                push( @{$relation_ptr->{'__notes__'}}, "'network' is short form" );
            }
            else {
                if ( $network_long_regex && $network =~ m/$network_long_regex/ ) {
                    if ( $positive_notes || ($expect_network_short && !$expect_network_long_for) ) {
                        my $n   = '---' . $network . '---';
                        my $nlr = '---' . $network_long_regex . '---';
                        if ( $n =~ m/$nlr/ ) {
                            push( @{$relation_ptr->{'__notes__'}}, "'network' is long form" );
                        }
                        else {
                            push( @{$relation_ptr->{'__notes__'}}, "'network' matches long form" );
                        }
                    }
                }
                if ( $network_short_regex && $network =~ m/$network_short_regex/ ) {
                    if ( $positive_notes || ($expect_network_long && !$expect_network_short_for) ) {
                        my $n   = '---' . $network . '---';
                        my $nsr = '---' . $network_short_regex . '---';
                        if ( $n =~ m/$nsr/ ) {
                            push( @{$relation_ptr->{'__notes__'}}, "'network' is short form" );
                        }
                        else {
                            push( @{$relation_ptr->{'__notes__'}}, "'network' matches short form" );
                        }
                    }
                }
            }
        }
        else {
            push( @{$relation_ptr->{'__issues__'}}, "'network' is not set" );
        }

        if ( $relation_ptr->{'tag'}->{'colour'} ) {
                my $colour = GetColourFromString( $relation_ptr->{'tag'}->{'colour'} );
                push( @{$relation_ptr->{'__issues__'}}, sprintf("'colour' has unknown value '%s'",$relation_ptr->{'tag'}->{'colour'}) )        unless ( $colour );
        }
        
        if ( $positive_notes ) {
            foreach my $special ( 'network:', 'route:', 'ref:', 'ref_' ) {
                foreach my $tag ( sort(keys(%{$relation_ptr->{'tag'}})) ) {
                    if ( $tag =~ m/^$special/i ) {
                        if ( $relation_ptr->{'tag'}->{$tag} ) {
                            if ( $tag =~ m/^network:long$/i && $network_long_regex){
                                if ( $relation_ptr->{'tag'}->{$tag} =~ m/^$network_long_regex$/ ) {
                                    push( @{$relation_ptr->{'__notes__'}}, sprintf("'%s' is long form", $tag, ) );
                                }
                                elsif ( $relation_ptr->{'tag'}->{$tag} =~ m/$network_long_regex/ ) {
                                    push( @{$relation_ptr->{'__notes__'}}, sprintf("'%s' matches long form", $tag, ) );
                                }
                                else {
                                    push( @{$relation_ptr->{'__notes__'}}, sprintf("'%s' = %s", $tag, $relation_ptr->{'tag'}->{$tag}) )
                                }
                            }
                            else {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf("'%s' = %s", $tag, $relation_ptr->{'tag'}->{$tag}) )
                            }
                        }
                    }
                }
            }
        }
        
        #
        # check route_master/route specific things
        #
        
        if ( $type eq 'route_master' ) {
            $return_code = analyze_route_master_relation( $relation_ptr );
        }
        elsif ( $type eq 'route') {
            $return_code = analyze_route_relation( $relation_ptr );
        }
        
        if ( 0  ) { #$check_wide_characters ) {
            if ( $relation_ptr->{'tag'} ) {
#                printf STDERR "Relation %s: checking tag ", $relation_id;
                foreach my $tag ( sort( keys( %{$relation_ptr->{'tag'}} ) ) ) {
                    next if ( $tag eq 'sort_name' );
#                    printf STDERR "'%s' ", $tag;
                    $wide_characters = '';
                    if ( defined($relation_ptr->{'tag'}->{$tag}) ) {
                        while ( $relation_ptr->{'tag'}->{$tag} && $relation_ptr->{'tag'}->{$tag} =~ m/([\N{U+0100}-\N{U+FFFE}])/g ) {
                            $wide_characters .= "'" . $1 . "', ";
                            #printf STDERR "Wide character %s in tag '%s' for relation %s\n", $1, $tag, $relation_id;
                        }
                        if ( $wide_characters ) {
                            $wide_characters =~ s/, $//;
                            push( @{$relation_ptr->{'__issues__'}}, sprintf("Wide charater(s) in tag '%s': %s", $tag, $wide_characters ) );
                        }
                    } else {
                        printf STDERR "Internal problem for relation: %s checking tag %s\n", $relation_id, $tag;
                    }
                }
#                printf STDERR "\n";
            } else {
                printf STDERR "Internal problem for relation %s: relation_ptr->{'tag'}\n", $relation_id;
            }
        }

    }

    return $return_code;
}


#############################################################################################

sub analyze_route_master_relation {
    my $relation_ptr    = shift;
    my $return_code     = 0;
    
    my $ref                            = $relation_ptr->{'tag'}->{'ref'};
    my $type                           = $relation_ptr->{'tag'}->{'type'};
    my $route_type                     = $relation_ptr->{'tag'}->{$type};
    my $member_index                   = scalar( @{$relation_ptr->{'member'}} );
    my $relation_index                 = scalar( @{$relation_ptr->{'relation'}} );
    my $route_master_relation_index    = scalar( @{$relation_ptr->{'route_master_relation'}} );
    my $route_relation_index           = scalar( @{$relation_ptr->{'route_relation'}} );
    my $way_index                      = scalar( @{$relation_ptr->{'way'}} );
    my $route_highway_index            = scalar( @{$relation_ptr->{'route_highway'}} );
    my $node_index                     = scalar( @{$relation_ptr->{'node'}} );

    push( @{$relation_ptr->{'__issues__'}}, "Route-Master without Route(s)" )                                   unless ( $route_master_relation_index );
    #push( @{$relation_ptr->{'__notes__'}},  "Route-Master with only 1 Route" )                                  if     ( $route_master_relation_index == 1 );
    push( @{$relation_ptr->{'__issues__'}}, "Route-Master with Relation(s) unequal to 'route'" )                if     ( $route_master_relation_index != $relation_index );
    push( @{$relation_ptr->{'__issues__'}}, "Route-Master with Way(s)" )                                        if     ( $way_index );
    push( @{$relation_ptr->{'__issues__'}}, "Route-Master with Node(s)" )                                       if     ( $node_index );
    if ( $relation_ptr->{'tag'}->{'public_transport:version'} ) {
        if ( $relation_ptr->{'tag'}->{'public_transport:version'} !~ m/^2$/ ) {
            push( @{$relation_ptr->{'__issues__'}}, "'public_transport:version' is not set to '2'" )        if ( $check_version ); 
        }
        else {
            ; #push( @{$relation_ptr->{'__notes__'}}, sprintf("'public_transport:version' = %s",$relation_ptr->{'tag'}->{'public_transport:version'}) )    if ( $positive_notes );
        }
    }
    else {
        push( @{$relation_ptr->{'__notes__'}}, "'public_transport:version' is not set" )        if ( $check_version );
    }

    return $return_code;
}


#############################################################################################

sub analyze_route_relation {
    my $relation_ptr    = shift;
    my $return_code     = 0;
    
    my $ref                            = $relation_ptr->{'tag'}->{'ref'};
    my $type                           = $relation_ptr->{'tag'}->{'type'};
    my $route_type                     = $relation_ptr->{'tag'}->{$type};
    my $member_index                   = scalar( @{$relation_ptr->{'member'}} );
    my $relation_index                 = scalar( @{$relation_ptr->{'relation'}} );
    my $route_relation_index           = scalar( @{$relation_ptr->{'route_relation'}} );
    my $way_index                      = scalar( @{$relation_ptr->{'way'}} );
    my $route_highway_index            = scalar( @{$relation_ptr->{'route_highway'}} );
    my $node_index                     = scalar( @{$relation_ptr->{'node'}} );

    push( @{$relation_ptr->{'__issues__'}}, "Route without Way(s)" )                    unless ( $route_highway_index );
    push( @{$relation_ptr->{'__issues__'}}, "Route with only 1 Way" )                   if     ( $route_highway_index == 1 && $route_type ne 'ferry' && $route_type ne 'aerialway' );
    push( @{$relation_ptr->{'__issues__'}}, "Route without Node(s)" )                   unless ( $node_index );
    push( @{$relation_ptr->{'__issues__'}}, "Route with only 1 Node" )                  if     ( $node_index == 1 );
    push( @{$relation_ptr->{'__issues__'}}, "Route with Relation(s)" )                  if     ( $route_relation_index );

    if ( $relation_ptr->{'tag'}->{'public_transport:version'} ) {
        if ( $relation_ptr->{'tag'}->{'public_transport:version'} !~ m/^[12]$/ ) {
            push( @{$relation_ptr->{'__issues__'}}, "'public_transport:version' is neither '1' nor '2'" ); 
        }
        else {
            #push( @{$relation_ptr->{'__notes__'}}, sprintf("'public_transport:version' = %s",$relation_ptr->{'tag'}->{'public_transport:version'}) )    if ( $positive_notes );
            
            if ( $relation_ptr->{'tag'}->{'public_transport:version'} == 2 ) {
                $return_code = analyze_ptv2_route_relation( $relation_ptr );
            }
        }
    }
    else {
        push( @{$relation_ptr->{'__notes__'}}, "'public_transport:version' is not set" )        if ( $check_version );
    }
    
    #
    # WAYS      vehicles must have access permission
    #
    if ( $check_access && $xml_has_ways ) {
        my $access_restriction  = undef;
        my %restricted_access   = ();
        foreach my $route_highway ( @{$relation_ptr->{'route_highway'}} ) {
            $access_restriction = noAccess( $route_highway->{'ref'}, $relation_ptr->{'tag'}->{'route'} );
            if ( $access_restriction ) {
                $restricted_access{$access_restriction}->{$route_highway->{'ref'}} = 1;
                $return_code++;
            }
        }

        if ( %restricted_access ) {
            foreach $access_restriction ( sort(keys(%restricted_access)) ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("Route: restricted access (%s) to way(s) without 'bus'='yes', 'bus'='designated', 'psv'='yes' or ...: %s", $access_restriction, join(', ', map { printWayTemplate($_); } sort(keys(%{$restricted_access{$access_restriction}})))) );
            }
        }
    }

    #
    # WAYS      must not have "highway" = "bus_stop" set - allowed only on nodes
    #
    if ( $check_bus_stop && $xml_has_ways ) {
        my %bus_stop_ways = ();
        foreach my $highway_ref ( @{$relation_ptr->{'way'}} ) {
            if ( $WAYS{$highway_ref->{'ref'}}->{'tag'}->{'highway'} && $WAYS{$highway_ref->{'ref'}}->{'tag'}->{'highway'} eq 'bus_stop' ) {
                $bus_stop_ways{$highway_ref->{'ref'}} = 1;
                $return_code++;
            }
        }
        if ( %bus_stop_ways ) {
            my @help_array     = sort(keys(%bus_stop_ways));
            my $num_of_errors  = scalar(@help_array);
            my $error_string   = "Route: 'highway' = 'bus_stop' is set on way(s). Allowed on nodes only!: ";
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s and %d more ...", $error_string, join(', ', map { printWayTemplate($_); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            }
            else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $error_string, join(', ', map { printWayTemplate($_); } @help_array )) );
            }
        }
    }
    
    return $return_code;
}


#############################################################################################

sub analyze_ptv2_route_relation {
    my $relation_ptr        = shift;
    my $return_code         = 0;
    
    my $role_mismatch_found           = 0;
    my %role_mismatch                 = ();
    my @relation_route_ways           = ();
    my @relation_route_stop_positions = ();
    my @sorted_way_nodes              = ();
    my @help_array                    = ();
    my $num_of_errors                 = 0;
    my $access_restriction            = undef;
    
    @relation_route_ways            = FindRouteWays( $relation_ptr );
    
    @relation_route_stop_positions  = FindRouteStopPositions( $relation_ptr );
    
    $relation_ptr->{'non_platform_ways'}       = \@relation_route_ways;
    $relation_ptr->{'number_of_segments'}      = 0;
    $relation_ptr->{'number_of_roundabouts'}   = 0;
    $relation_ptr->{'sorted_in_reverse_order'} = '';
    
    if ( $check_name ) {
        if ( $relation_ptr->{'tag'}->{'name'} ) {
            my $preconditions_failed = 0;
            my $name = $relation_ptr->{'tag'}->{'name'}; 
            my $ref  = $relation_ptr->{'tag'}->{'ref'}; 
            my $from = $relation_ptr->{'tag'}->{'from'}; 
            my $to   = $relation_ptr->{'tag'}->{'to'}; 
            my $via  = $relation_ptr->{'tag'}->{'via'};
            #
            # we do not use =~ m/.../ here because the strings may contain special regex characters such as ( ) [ ] and so on
            #
            if ( $ref ) {
                if ( index($name,$ref) == -1 ) {
                    push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'ref' is not part of 'name'" );
                    $preconditions_failed++;
                    $return_code++;
                }
            }
            else {
                # already checked, but must increase conditions_failed here
                #push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'ref' is not set" );
                $preconditions_failed++;
                $return_code++;
            }
            if ( $from ) {
                if ( index($name,$from) == -1 ) {
                    push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'from' is not part of 'name'" );
                    $preconditions_failed++;
                    $return_code++;
                }
            }
            else {
                push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'from' is not set" );
                $preconditions_failed++;
                $return_code++;
            }
            if ( $to ) {
                if ( index($name,$to) == -1 ) {
                    push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'to' is not part of 'name'" );
                    $preconditions_failed++;
                    $return_code++;
                }
            }
            else {
                push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'to' is not set" );
                $preconditions_failed++;
                $return_code++;
            }
            if ( $name =~ m/<=>/ ) {
                push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'name' includes deprecated '<=>'" );
                $preconditions_failed++;
                $return_code++;
            }
            if ( $name =~ m/==>/ ) {
                push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'name' includes deprecated '==>'" );
                #$preconditions_failed++;
                $return_code++;
            }
            
            if ( $preconditions_failed == 0 ) {
                # i.e. 'to' and 'from' and 'ref' are set, and of course 'name'
                my $expected_long  = undef;
                my $expected_short = undef;
                my $i_long         = 0;
                my $i_short        = 0;
                my $num_of_arrows  = 0;
                $num_of_arrows++    while ( $name =~ m/=>/g );
                if ( $num_of_arrows < 2 ) {
                    # well, 'name' should then include 'ref' and only 'from' and 'to' (no 'via')
                    $expected_long  = $ref . ': ' . $from . ' => ' . $to;   # this is how it really should be: with blank around '=>'
                    $expected_short = $ref . ': ' . $from . '=>'   . $to;   # some people ommit the blank around the '=>', be relaxed with that
                    $i_long        = index( $name, $expected_long  );
                    $i_short       = index( $name, $expected_short );
                    if ( ($i_long  == -1 || length($name) > $i_long  + length($expected_long))  &&
                         ($i_short == -1 || length($name) > $i_short + length($expected_short))    ) {
                        # no match or 'name' is longer than expected
                        push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'name' should (at least) be of the form '... ref: from => to'" );
                        $return_code++;
                    }
                }
                else {
                    # there is more than one '=>' in the 'name' value, so 'name' includes via stops
                    if ( $via ) {
                        my @via_values = split( ";", $via );
                        $preconditions_failed = 0;
                        foreach my $via_value ( @via_values ) {
                            if ( index($name,$via_value) == -1 ) {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf("PTv2 route: 'via' is set: via-part = '%s' is not part of 'name' (separate multiple 'via' values by ';', without blanks)",$via_value) );
                                $preconditions_failed++;
                                $return_code++;
                            }
                        }
                        if ( $preconditions_failed == 0 ){
                            $expected_long  = $ref . ': ' . $from . ' => ' . join(' => ',@via_values) .' => ' . $to;   # this is how it really should be: with blank around '=>'
                            $expected_short = $ref . ': ' . $from . '=>'   . join('=>' ,@via_values)  .'=>'   . $to;   # some people ommit the blank around the '=>', be relaxed with that
                            $i_long         = index( $name, $expected_long );
                            $i_short        = index( $name, $expected_short );
                            if ( ($i_long  == -1 || length($name) > $i_long + length($expected_long)) && 
                                 ($i_short == -1 || length($name) > $i_short + length($expected_short))    ) {
                                # no match or 'name' is longer than expected
                                if ( $num_of_arrows == 2 ) {
                                    push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'via' is set: 'name' should be of the form '... ref: from => via => to'" );
                                }
                                else {
                                    push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'via' is set: 'name' should be of the form '... ref: from => via => ... => to' (separate multiple 'via' values by ';', without blanks)" );
                                }
                                $return_code++;
                            }
                        }
                    }
                    else {
                        # multiple '=>' in 'name' but 'via is not set
                        push( @{$relation_ptr->{'__notes__'}}, "PTv2 route: 'name' has more than one '=>' but 'via' is not set" );
                        $return_code++;
                     }
                }
            }
        }
    }

    if ( $relation_route_ways[0] && $relation_route_ways[1] ) {
        #
        # special check for route being sorted in reverse order and starting with a oneway (except closed way)
        #
        my $current_way_id  = $relation_route_ways[0];
        my $entry_node_id   = undef;
        my $node_id         = undef;
        printf STDERR "analyze_ptv2_route_relation() : at least two ways exist: 1st = %d, 2nd = %s\n", $current_way_id, $relation_route_ways[1]     if ( $debug );
        if ( !isClosedWay($current_way_id) ) {
            printf STDERR "analyze_ptv2_route_relation() : first way is not a closed way\n"     if ( $debug );
            if ( ($entry_node_id = isOneway($current_way_id,undef)) ) {
                printf STDERR "analyze_ptv2_route_relation() : first way is onway with entry_node_id = %d\n", $entry_node_id     if ( $debug );
                if ( $entry_node_id = $WAYS{$current_way_id}->{'first_node'} ) {
                    $node_id = $WAYS{$current_way_id}->{'last_node'};
                    printf STDERR "analyze_ptv2_route_relation() : node_id = %d is 'last_node\n", $node_id     if ( $debug );
                }
                else {
                    $node_id = $WAYS{$current_way_id}->{'first_node'};
                    printf STDERR "analyze_ptv2_route_relation() : node_id = %d is 'first_node\n", $node_id     if ( $debug );
                }
                printf STDERR "analyze_ptv2_route_relation() : node_id is in relations's stop node array\n" if ( isNodeInNodeArray($node_id,@relation_route_stop_positions) && $debug );
                if ( isNodeInNodeArray($node_id,@relation_route_stop_positions) ) {
                    #
                    # OK, let's check whether this stop-position is not a connecting node to the second way
                    #
                    $current_way_id = $relation_route_ways[1];
                    if ( $node_id == $WAYS{$current_way_id}->{'first_node'} ||
                         $node_id == $WAYS{$current_way_id}->{'last_node'}     ) {
                        #
                        # OK: so it's: ->->->->Sn----Cn------Cn--- which means, the route starts too early (found and reported later on)
                        #
                        ;
                    }
                    else {      # Sn == Stop-Node; Cn == Connecting-Node; ----- == normal Way; ->->->-> == Oneway
                        #
                        #
                        # Bad: it's: Sn<-<-<-<Cn---Cn----- and reverse it's OK: -----Cn---Cn->->->->Sn
                        #
                        $relation_ptr->{'sorted_in_reverse_order'} = 1;
                    }
                }
            }
        }
    }
    
    if ( $check_sequence ) {
        #
        # check for correct sequence of members: stop1, platform1, stop2, platform2, ... way1, way2, ...
        #
        my $have_seen_stop            = 0;
        my $have_seen_platform        = 0;
        my $have_seen_highway_railway = 0;

        $relation_ptr->{'wrong_sequence'} = 0;

        foreach my $item ( @{$relation_ptr->{'member'}} ) {
            if ( $item->{'type'} eq 'node' ) {
                if ( $stop_nodes{$item->{'ref'}} ) {
                    $have_seen_stop++;
                    $relation_ptr->{'wrong_sequence'}++     if ( $have_seen_highway_railway );
                    #printf STDERR "stop node after way for %s\n", $item->{'ref'};
                }
                elsif ( $platform_nodes{$item->{'ref'}} ) {
                    $have_seen_platform++;
                    $relation_ptr->{'wrong_sequence'}++     if ( $have_seen_highway_railway );
                    #printf STDERR "platform node after way for %s\n", $item->{'ref'};
                }
            }
            elsif ( $item->{'type'} eq 'way' ) {
                if ( $platform_ways{$item->{'ref'}} ) {
                    $have_seen_platform++;
                    $relation_ptr->{'wrong_sequence'}++     if ( $have_seen_highway_railway );
                    #printf STDERR "platform way after way for %s\n", $item->{'ref'};
                }
                elsif ( $WAYS{$item->{'ref'}}->{'tag'}->{'railway'} ) {
                    if ( $WAYS{$item->{'ref'}}->{'tag'}->{'railway'} ne 'platform' ) {
                        $have_seen_highway_railway++;
                    }
                }
                elsif ( $WAYS{$item->{'ref'}}->{'tag'}->{'highway'} ) {
                    if ( $WAYS{$item->{'ref'}}->{'tag'}->{'highway'} ne 'platform' &&
                         $WAYS{$item->{'ref'}}->{'tag'}->{'highway'} ne 'bus_stop'    ) {
                        $have_seen_highway_railway++;
                    }
                }
            }
            elsif ( $item->{'type'} eq 'relation' ) {
                if ( $PL_MP_relations{$item->{'ref'}} ) {
                    $have_seen_platform++;
                    $relation_ptr->{'wrong_sequence'}++     if ( $have_seen_highway_railway );
                    #printf STDERR "platform relation after way for %s\n", $item->{'ref'};
                }
            }
        }
    }
        
    printf STDERR "analyze_ptv2_route_relation() : SortRouteWayNodes() for relation ref=%s, name=%s\n", $relation_ptr->{'tag'}->{'ref'}, $relation_ptr->{'tag'}->{'name'}   if ( $debug );
    
    @sorted_way_nodes    = SortRouteWayNodes( $relation_ptr, $relation_ptr->{'non_platform_ways'} );
    
    if ( $relation_ptr->{'sorted_in_reverse_order'} ) {
        push( @{$relation_ptr->{'__issues__'}}, "PTv2 route: first way is a oneway road and ends in a 'stop_position' of this route and there is no exit. Is the route sorted in reverse order?" );
        $return_code++
    }
    if ( $relation_ptr->{'number_of_segments'} > 1 ) {
        push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: has gap(s), consists of %d segments", $relation_ptr->{'number_of_segments'}) );
        $return_code += $relation_ptr->{'number_of_segments'} - 1;
    }
    if ( $relation_ptr->{'wrong_sequence'} ) {
        push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: incorrect order of 'stop_position', 'platform' and 'way' (stop/platform after way)" ) );
        $return_code++;
    }
    if ( $relation_ptr->{'number_of_roundabouts'} && $check_roundabouts ) {
        push( @{$relation_ptr->{'__notes__'}},  sprintf("PTv2 route: includes %d entire roundabout(s) but uses only segment(s)", $relation_ptr->{'number_of_roundabouts'}) );
        $return_code++;
    }
    if ( $relation_ptr->{'wrong_direction_oneways'} ) {
        push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: using oneway way(s) in wrong direction: %s", join(', ', map { printWayTemplate($_); } sort(keys(%{$relation_ptr->{'wrong_direction_oneways'}})))) );
        $return_code++;
    }
    
    
    #
    # NODES     are either Stop-Positions or Platforms, so they must have a 'role'
    #
    foreach my $node_ref ( @{$relation_ptr->{'node'}} ) {
        if ( $node_ref->{'role'} ){
            if ( $node_ref->{'role'} =~ m/^stop$/                   ||
                 $node_ref->{'role'} =~ m/^stop_entry_only$/        ||
                 $node_ref->{'role'} =~ m/^stop_exit_only$/         ||
                 $node_ref->{'role'} =~ m/^platform$/               ||
                 $node_ref->{'role'} =~ m/^platform_entry_only$/    ||
                 $node_ref->{'role'} =~ m/^platform_exit_only$/        ) {
                
                if ( $xml_has_nodes ) {
                    if ( $node_ref->{'role'} =~ m/^stop/ ) {
                        if ( $stop_nodes{$node_ref->{'ref'}} ) {
                            if ( isNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                
                                # checking roles stop_entry_only and stop_exit_only makes only sense if there are no gaps, i.e. the ways are sorted
                                # checking stop_exit_only and stop_entry_only is not performed
                                # MVV Bus 213 (Munich) has stops at Karl-Preis-Platz which are neither first nor last nodes.
                                
                                if ( $relation_ptr->{'number_of_segments'} == 1 ) {
                                      #
                                    ; # fine, what can we check here now?
                                      #
                                    
                                    #if ( $node_ref->{'role'} eq 'stop_entry_only' ) {
                                    #    if ( isFirstNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                    #        ; # fine, what else can we check here?
                                    #    }
                                    #    else {
                                    #        $role_mismatch{"'role' = 'stop_entry_only' is not first node of first way"}->{$node_ref->{'ref'}} = 1;
                                    #        $role_mismatch_found++;
                                    #    }
                                    #}
                                    #if ( $node_ref->{'role'} eq 'stop_exit_only' ) {
                                    #    if ( isLastNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                    #       ; # fine, what else can we check here?
                                    #    }
                                    #    else {
                                    #        $role_mismatch{"'role' = 'stop_exit_only' is not last node of last way"}->{$node_ref->{'ref'}} = 1;
                                    #        $role_mismatch_found++;
                                    #    }
                                    #}
                                }
                                if ( scalar(@relation_route_ways) == 1 ) {
                                    my $entry_node_id = isOneway( $relation_route_ways[0], undef );
                                    if ( $entry_node_id != 0 ) {
                                        # it is a oneway
                                        if ( $node_ref->{'role'} eq 'stop_exit_only' && isFirstNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                            $role_mismatch{"first node of oneway way has 'role' = 'stop_exit_only'"}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                        if ( $node_ref->{'role'} eq 'stop_entry_only' && isLastNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                            $role_mismatch{"last node of oneway way has 'role' = 'stop_entry_only'"}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                    }
                                }
                                elsif ( scalar(@relation_route_ways) > 1 ) {
                                    #
                                    # for routes with more than 1 way
                                    #
                                    # do not consider roundtrip routes where first and last node is the same node but passengers have to leave the bus/tram/...
                                    #
                                    if ( $node_ref->{'role'} eq 'stop_exit_only' ) {
                                        if ( isFirstNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) && !isLastNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                            $role_mismatch{"first node of way has 'role' = 'stop_exit_only'. Is the route sorted in reverse order?"}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                    }
                                    if ( $node_ref->{'role'} eq 'stop_entry_only' ) {
                                        if ( isLastNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) && ! isFirstNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                            $role_mismatch{"last node of way has 'role' = 'stop_entry_only'. Is the route sorted in reverse order?"}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                    }
                                }
                            }
                            else {
                                $role_mismatch{"'public_transport' = 'stop_position' is not part of way"}->{$node_ref->{'ref'}} = 1;
                                $role_mismatch_found++;
                            }
                            if ( $check_stop_position ) {
                                if ( $relation_ptr->{'tag'}->{'route'} eq 'bus'        ||
                                     $relation_ptr->{'tag'}->{'route'} eq 'tram'       ||
                                     $relation_ptr->{'tag'}->{'route'} eq 'share_taxi'    ) {
                                    if ( $NODES{$node_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}}          &&
                                         $NODES{$node_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}} eq "yes"    ) {
                                        ; # fine
                                    }
                                    else {
                                        $role_mismatch{"missing '".$relation_ptr->{'tag'}->{'route'}."' = 'yes' on 'public_transport' = 'stop_position'"}->{$node_ref->{'ref'}} = 1;
                                        $role_mismatch_found++;
                                    }
                                }
                            }
                        }
                        elsif ( $NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'} ) {
                            $role_mismatch{"mismatch between 'role' = '".$node_ref->{'role'}."' and 'public_transport' = '".$NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'}."'"}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        }
                        else {
                            $role_mismatch{"'role' = '".$node_ref->{'role'}."' but 'public_transport' is not set"}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        }
                    }
                    else    # matches any platform of the three choices
                    {
                        if ( $platform_nodes{$node_ref->{'ref'}} ) {
                            if ( isNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                $role_mismatch{"'public_transport' = 'platform' is part of way"}->{$node_ref->{'ref'}} = 1;
                                $role_mismatch_found++;
                            }
                            else {
                                ; # fine, what else can we check here?
                            }
                            #
                            # bus=yes, tram=yes or share_taxi=yes is not required on public_transport=platform
                            #
                            #if ( $check_platform ) {
                            #    if ( $relation_ptr->{'tag'}->{'route'} eq 'bus'        ||
                            #         $relation_ptr->{'tag'}->{'route'} eq 'tram'       ||
                            #         $relation_ptr->{'tag'}->{'route'} eq 'share_taxi'    ) {
                            #        if ( $NODES{$node_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}}          &&
                            #             $NODES{$node_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}} eq "yes"    ) {
                                        ; # fine
                            #        }
                            #        else {
                            #            $role_mismatch{"missing '".$relation_ptr->{'tag'}->{'route'}."' = 'yes' on 'public_transport' = 'platform'"}->{$node_ref->{'ref'}} = 1;
                            #            $role_mismatch_found++;
                            #        }
                            #    }
                            #}
                        }
                        elsif ( $NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'} ) {
                            $role_mismatch{"mismatch between 'role' = '".$node_ref->{'role'}."' and 'public_transport' = '".$NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'}."'"}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        }
                        else {
                            $role_mismatch{"'role' = '".$node_ref->{'role'}."' but 'public_transport' is not set"}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        }
                    }
                }
            }
            else {
                $role_mismatch{"wrong 'role' = '".$node_ref->{'role'}."'"}->{$node_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        }
        else {
            $role_mismatch{"empty 'role'"}->{$node_ref->{'ref'}} = 1;
            $role_mismatch_found++;
        }
    }
    if ( $role_mismatch_found ) {
        foreach my $role ( sort ( keys ( %role_mismatch ) ) ) {
            @help_array     = sort(keys(%{$role_mismatch{$role}}));
            $num_of_errors  = scalar(@help_array);
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: %s: %s and %d more ...", $role, join(', ', map { printNodeTemplate($_); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            }
            else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: %s: %s", $role, join(', ', map { printNodeTemplate($_); } @help_array )) );
            }
        }
    }
    $return_code += $role_mismatch_found;

    if ( $relation_ptr->{'number_of_segments'} == 1 ) {
        if ( isNodeInNodeArray($sorted_way_nodes[0],@relation_route_stop_positions) ) {
            #
            # fine, first node of ways is actually a stop position of this route
            #
            if ( $sorted_way_nodes[0] == $relation_route_stop_positions[0] ) {
                #
                # fine, first stop position in the list is actually the first node of the way
                #
                ;
            }
            else {
                if ( scalar(@relation_route_ways) > 1 || isOneway($relation_route_ways[0],undef) ) {
                    #
                    # if we have more than one way or the single way is a oneway, and because we know: the ways are sorted and w/o gaps
                    #
                    push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: first node of way is not the first stop position of this route: %s versus %s", printNodeTemplate($sorted_way_nodes[0]), printNodeTemplate($relation_route_stop_positions[0]) ) );            
                    $return_code++;
                }
            }
        }
        else {
            my $relaxed_for =  $relaxed_begin_end_for || '';
            $relaxed_for    =~ s/;/,/g;
            $relaxed_for    =  ',' . $relaxed_for . ',';
            if ( $relaxed_for =~ m/,$relation_ptr->{'tag'}->{'route'},/ ) {
                my $first_way_ID     = $relation_route_ways[0];
                my @first_way_nodes  = ();
                my $found_it         = 0;
                my $found_nodeid     = 0;

                if ( $sorted_way_nodes[0] == ${$WAYS{$first_way_ID}->{'node_array'}}[0] ) {
                    @first_way_nodes  = @{$WAYS{$first_way_ID}->{'node_array'}};
                }
                else {
                    @first_way_nodes  = reverse @{$WAYS{$first_way_ID}->{'node_array'}};
                }
                
                foreach my $nodeid ( @first_way_nodes ) {
                    printf STDERR "WAY{%s}->{'node_array'}->%s\n", $first_way_ID, $nodeid   if ( $debug );
                    if ( isNodeInNodeArray($nodeid,@relation_route_stop_positions) ) {
                        #
                        # fine, an inner node, or the last of the first way is a stop position of this route
                        #
                        $found_it++;
                        printf STDERR "WAY{%s}->{'node_array'}->%s - %d\n", $first_way_ID, $nodeid, $found_it   if ( $debug );
                        if ( $nodeid == $relation_route_stop_positions[0] ) {
                            #
                            # fine the first node of the first way which is a stop position and is actually the first stop position
                            #
                            $found_it++;
                            printf STDERR "WAY{%s}->{'node_array'}->%s - %d\n", $first_way_ID, $nodeid, $found_it   if ( $debug );
                        }
                        $found_nodeid = $nodeid;
                        last;
                    }
                }
                if ( $found_it == 1 ) {
                    printf STDERR "1: Number of ways: %s, found_nodeid = %s, last node of first way = %s\n", scalar(@relation_route_ways), $found_nodeid, $first_way_nodes[$#first_way_nodes]  if ( $debug );
                    if ( scalar(@relation_route_ways) > 1 && $found_nodeid == $first_way_nodes[$#first_way_nodes] ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: there is no stop position of this route on the first way, except the last node == first node of next way: %s", printWayTemplate($first_way_ID) ) );            
                        $return_code++;
                    }
                    else {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: first stop position on first way is not the first stop position of this route: %s versus %s", printNodeTemplate($found_nodeid), printNodeTemplate($relation_route_stop_positions[0]) ) );            
                        $return_code++;
                    }
                }
                elsif ( $found_it == 2 ) {
                    printf STDERR "2: Number of ways: %s, found_nodeid = %s, last node of first way = %s\n", scalar(@relation_route_ways), $found_nodeid, $first_way_nodes[$#first_way_nodes]  if ( $debug );
                    if ( scalar(@relation_route_ways) > 1 && $found_nodeid == $first_way_nodes[$#first_way_nodes] ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: there is no stop position of this route on the first way, except the last node == first node of next way: %s", printWayTemplate($first_way_ID) ) );            
                        $return_code++;
                    }
                }
                else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: there is no stop position of this route on the first way: %s", printWayTemplate($first_way_ID) ) );            
                    $return_code++;
                }
            }
            else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: first node of way is not a stop position of this route: %s", printNodeTemplate($sorted_way_nodes[0]) ) );            
                $return_code++;
            }
        }
        if ( isNodeInNodeArray($sorted_way_nodes[$#sorted_way_nodes],@relation_route_stop_positions) ) {
            #
            # fine, last node of ways is actually a stop position of this route
            #
            if ( $sorted_way_nodes[$#sorted_way_nodes] == $relation_route_stop_positions[$#relation_route_stop_positions] ) {
                #
                # fine, last stop position in the list is actually the last node of the way
                #
                ;
            }
            else {
                if ( scalar(@relation_route_ways) > 1 || isOneway($relation_route_ways[0],undef) ) {
                    #
                    # if we have more than one way or the single way is a oneway, and because we know: the ways are sorted and w/o gaps
                    #
                    push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: last node of way is not the last stop position of this route: %s versus %s", printNodeTemplate($sorted_way_nodes[$#sorted_way_nodes]), printNodeTemplate($relation_route_stop_positions[$#relation_route_stop_positions]) ) );            
                    $return_code++;
                }
            }
        }
        else {
            my $relaxed_for =  $relaxed_begin_end_for || '';
            $relaxed_for    =~ s/;/,/g;
            $relaxed_for    =  ',' . $relaxed_for . ',';
            if ( $relaxed_for =~ m/,$relation_ptr->{'tag'}->{'route'},/ ) {
                my $last_way_ID     = $relation_route_ways[$#relation_route_ways];
                my @last_way_nodes  = ();
                my $found_it        = 0;
                my $found_nodeid    = 0;

                if ( $sorted_way_nodes[$#sorted_way_nodes] == ${$WAYS{$last_way_ID}->{'node_array'}}[0] ) {
                    @last_way_nodes  = @{$WAYS{$last_way_ID}->{'node_array'}};
                }
                else {
                    @last_way_nodes  = reverse @{$WAYS{$last_way_ID}->{'node_array'}};
                }
                
                foreach my $nodeid ( @last_way_nodes ) {
                    printf STDERR "WAY{%s}->{'node_array'}->%s\n", $last_way_ID, $nodeid   if ( $debug );
                    if ( isNodeInNodeArray($nodeid,@relation_route_stop_positions) ) {
                        #
                        # fine, an inner node, or the first of the last way is a stop position of this route
                        #
                        $found_it++;
                        printf STDERR "WAY{%s}->{'node_array'}->%s - %d\n", $last_way_ID, $nodeid, $found_it   if ( $debug );
                        if ( $nodeid == $relation_route_stop_positions[$#relation_route_stop_positions] ) {
                            #
                            # fine the last node of the last way which is a stop position and is actually the first stop position
                            #
                            $found_it++;
                            printf STDERR "WAY{%s}->{'node_array'}->%s - %d\n", $last_way_ID, $nodeid, $found_it   if ( $debug );
                        }
                        $found_nodeid = $nodeid;
                        last;
                    }
                }
                if ( $found_it == 1 ) {
                    printf STDERR "1: Number of ways: %s, found_nodeid = %s, first node of last way = %s\n", scalar(@relation_route_ways), $found_nodeid, $last_way_nodes[0]  if ( $debug );
                    if ( scalar(@relation_route_ways) > 1 && $found_nodeid == $last_way_nodes[0] ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: there is no stop position of this route on the last way, except the first node == last node of previous way: %s", printWayTemplate($last_way_ID) ) );            
                        $return_code++;
                    }
                    else {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: last stop position on last way is not the last stop position of this route: %s versus %s", printNodeTemplate($found_nodeid), printNodeTemplate($relation_route_stop_positions[$#relation_route_stop_positions]) ) );            
                        $return_code++;
                    }
                }
                elsif ( $found_it == 2 ) {
                    printf STDERR "2: Number of ways: %s, found_nodeid = %s, first node of last way = %s\n", scalar(@relation_route_ways), $found_nodeid, $last_way_nodes[0]  if ( $debug );
                    if ( scalar(@relation_route_ways) > 1 && $found_nodeid == $last_way_nodes[0] ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: there is no stop position of this route on the last way, except the first node == last node of previous way: %s", printWayTemplate($last_way_ID) ) );            
                        $return_code++;
                    }
                }
                else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: there is no stop position of this route on the last way: %s", printWayTemplate($last_way_ID) ) );            
                    $return_code++;
                }
            }
            else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: last node of way is not a stop position of this route: %s", printNodeTemplate($sorted_way_nodes[$#sorted_way_nodes]) ) );            
                $return_code++;
            }
        }
    }                                
    #
    # WAYS      are either Platforms (which must have a 'role') or Ways (which must not have a 'role')
    #
    $role_mismatch_found = 0;
    %role_mismatch       = ();
    foreach my $highway_ref ( @{$relation_ptr->{'way'}} ) {
        if ( $highway_ref->{'role'} ) {
            if ( $highway_ref->{'role'} =~ m/^platform$/               ||
                 $highway_ref->{'role'} =~ m/^platform_entry_only$/    ||
                 $highway_ref->{'role'} =~ m/^platform_exit_only$/        ) {
                
                if ( $xml_has_ways ) {
                    if ( $platform_ways{$highway_ref->{'ref'}} ) {
                        #
                        # bus=yes, tram=yes or share_taxi=yes is not required on public_transport=platform
                        #
                        #if ( $check_platform ) {
                        #    if ( $relation_ptr->{'tag'}->{'route'} eq 'bus'        ||
                        #         $relation_ptr->{'tag'}->{'route'} eq 'tram'       ||
                        #         $relation_ptr->{'tag'}->{'route'} eq 'share_taxi'    ) {
                        #        if ( $WAYS{$highway_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}}          &&
                        #             $WAYS{$highway_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}} eq "yes"    ) {
                                    ; # fine
                        #        }
                        #        else {
                        #            $role_mismatch{"missing '".$relation_ptr->{'tag'}->{'route'}."' = 'yes' on 'public_transport' = 'platform'"}->{$highway_ref->{'ref'}} = 1;
                        #            $role_mismatch_found++;
                        #        }
                        #    }
                        #}
                    }
                    elsif ( $WAYS{$highway_ref->{'ref'}}->{'tag'}->{'public_transport'} ) {
                        $role_mismatch{"mismatch between 'role' = '".$highway_ref->{'role'}."' and 'public_transport' = '".$WAYS{$highway_ref->{'ref'}}->{'tag'}->{'public_transport'}."'"}->{$highway_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    }
                    else {
                        $role_mismatch{"'role' = '".$highway_ref->{'role'}."' but 'public_transport' is not set"}->{$highway_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    }
                }
            }
            else {
                $role_mismatch{"wrong 'role' = '".$highway_ref->{'role'}."'"}->{$highway_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        }
        else {
            if ( $platform_ways{$highway_ref->{'ref'}} ) {
                $role_mismatch{"empty 'role'"}->{$highway_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        }
    }
    if ( $role_mismatch_found ) {
        foreach my $role ( sort ( keys ( %role_mismatch ) ) ) {
            @help_array     = sort(keys(%{$role_mismatch{$role}}));
            $num_of_errors  = scalar(@help_array);
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: %s: %s and %d more ...", $role, join(', ', map { printWayTemplate($_); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            }
            else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: %s: %s", $role, join(', ', map { printWayTemplate($_); } @help_array )) );
            }
        }
    }
    $return_code += $role_mismatch_found;

    #
    # RELATIONS     are Platforms, which must have a 'role'
    #
    $role_mismatch_found = 0;
    %role_mismatch       = ();
    foreach my $rel_ref ( @{$relation_ptr->{'relation'}} ) {
        if ( $rel_ref->{'role'} ){
            if ( $rel_ref->{'role'} =~ m/^platform$/               ||
                 $rel_ref->{'role'} =~ m/^platform_entry_only$/    ||
                 $rel_ref->{'role'} =~ m/^platform_exit_only$/        ) {
                
                if ( $number_of_pl_mp_relations ) {
                    if ( $PL_MP_relations{$rel_ref->{'ref'}} ) {
                        #
                        # bus=yes, tram=yes or share_taxi=yes is not required on public_transport=platform
                        #
                        #if ( $check_platform ) {
                        #    if ( $relation_ptr->{'tag'}->{'route'} eq 'bus'        ||
                        #         $relation_ptr->{'tag'}->{'route'} eq 'tram'       ||
                        #         $relation_ptr->{'tag'}->{'route'} eq 'share_taxi'    ) {
                        #        if ( $RELATIONS{$rel_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}}          &&
                        #             $RELATIONS{$rel_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}} eq "yes"    ) {
                                    ; # fine
                        #        }
                        #        else {
                        #            $role_mismatch{"missing '".$relation_ptr->{'tag'}->{'route'}."' = 'yes' on 'public_transport' = 'platform'"}->{$rel_ref->{'ref'}} = 1;
                        #            $role_mismatch_found++;
                        #        }
                        #    }
                        #}
                    }
                    elsif ( $RELATIONS{$rel_ref->{'ref'}}                                &&
                            $RELATIONS{$rel_ref->{'ref'}}->{'tag'}->{'public_transport'}   ) {
                        $role_mismatch{"mismatch between 'role' = '".$rel_ref->{'role'}."' and 'public_transport' = '".$RELATIONS{$rel_ref->{'ref'}}->{'tag'}->{'public_transport'}."'"}->{$rel_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    }
                    else {
                        $role_mismatch{"'role' = '".$rel_ref->{'role'}."' but 'public_transport' is not set"}->{$rel_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    }
                }
            }
            else {
                $role_mismatch{"wrong 'role' = '".$rel_ref->{'role'}."'"}->{$rel_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        }
        else {
            $role_mismatch{"empty 'role'"}->{$rel_ref->{'ref'}} = 1;
            $role_mismatch_found++;
        }
    }
    if ( $role_mismatch_found ) {
        foreach my $role ( sort ( keys ( %role_mismatch ) ) ) {
            @help_array     = sort(keys(%{$role_mismatch{$role}}));
            $num_of_errors  = scalar(@help_array);
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: %s: %s and %d more ...", $role, join(', ', map { printRelationTemplate($_); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            }
            else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("PTv2 route: %s: %s", $role, join(', ', map { printRelationTemplate($_); } @help_array )) );
            }
        }
    }
    $return_code += $role_mismatch_found;
    
    return $return_code;
}


#############################################################################################

sub FindRouteWays {
    my $relation_ptr            = shift;
    my $highway_ref             = undef;
    my @relations_route_ways    = ();

    foreach $highway_ref ( @{$relation_ptr->{'way'}} ) {
        push( @relations_route_ways, $highway_ref->{'ref'} )    unless ( $platform_ways{$highway_ref->{'ref'}} );
        #printf STDERR "FindRouteWays(): not pushed() %s\n", $highway_ref->{'ref'}   if ( $platform_ways{$highway_ref->{'ref'}} );
        #printf STDERR "FindRouteWays(): pushed() %s\n", $highway_ref->{'ref'}       unless ( $platform_ways{$highway_ref->{'ref'}} );
    }
    
    return @relations_route_ways;
}


#############################################################################################

sub FindRouteStopPositions {
    my $relation_ptr                    = shift;
    my $node_ref                        = undef;
    my @relations_route_stop_positions  = ();

    foreach $node_ref ( @{$relation_ptr->{'node'}} ) {
        push( @relations_route_stop_positions, $node_ref->{'ref'} )    if ( $stop_nodes{$node_ref->{'ref'}} );
    }
    
    return @relations_route_stop_positions;
}


#############################################################################################

sub SortRouteWayNodes {
    my $relation_ptr                = shift;
    my $relations_route_ways_ref    = shift;
    my @sorted_nodes                = ();
    my $connecting_node_id          = 0;
    my $current_way_id              = undef;
    my $next_way_id                 = undef;
    my $node_id                     = undef;
    my @control_nodes               = ();
    my $counter                     = 0;
    my $index                       = undef;
    my $way_index                   = 0;
    my $entry_node_id               = 0;
    my $route_type                  = undef;
    my $access_restriction          = undef;
    my $number_of_ways              = 0;
    
    printf STDERR "SortRouteWayNodes() : processing Ways:\nWays: %s\n", join( ', ', @{$relations_route_ways_ref} )     if ( $debug );
    
    if ( $relation_ptr && $relations_route_ways_ref ) {
        
        $number_of_ways = scalar @{$relations_route_ways_ref} ;
        if ( $number_of_ways ) {
            # we have at least one way, so we start with one segment
            $relation_ptr->{'number_of_segments'} = 1;
        }
        else {
            # no ways, no segments
            $relation_ptr->{'number_of_segments'} = 0;
        }
        
        while ( ${$relations_route_ways_ref}[$way_index] ) {
            
            $current_way_id  = ${$relations_route_ways_ref}[$way_index];
            $next_way_id     = ${$relations_route_ways_ref}[$way_index+1];
            $way_index++;
            
            foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                push( @control_nodes, $node_id );
            }
    
            if ( $next_way_id ) {
                if ( $connecting_node_id ) {
                    #
                    printf STDERR "SortRouteWayNodes() : Connecting Node %d\n",$connecting_node_id       if ( $debug );
                    #
                    # continue this segment with the connecting node of the previously handled way
                    #
                    if ( isClosedWay($current_way_id) ) {
                        #
                        # no direct match, this current way is a closed way, roundabout or whatever, where first node is also last node
                        # check whether connecting node is a node of this, closed way
                        #
                        if ( ($index=IndexOfNodeInNodeArray($connecting_node_id,@{$WAYS{$current_way_id}->{'node_array'}})) >= 0 ) {
                            printf STDERR "SortRouteWayNodes() : handle Nodes of closed Way %s with Index %d:\nNodes: %s\n", $current_way_id, $index, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            my $i = 0;
                            for ( $i = $index+1; $i <= $#{$WAYS{$current_way_id}->{'node_array'}}; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'node_array'}}[$i] );
                            }
                            for ( $i = 0; $i <= $index; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'node_array'}}[$i] );
                            }
                            
                            #
                            # now that we entered the closed way, how and where (!) do we get out of it
                            # - if this current way is a turning circle, where the 'bus' turns and comes back, then entering_node is leaving_node and we're fine and next While-loop will find that out
                            # - if this current way is an entire roundabout and the 'bus' leaves it prematurely, then we have an issue, because some parts of the roundabout aren't used
                            #
                            if ( $sorted_nodes[$#sorted_nodes] == $WAYS{$next_way_id}->{'first_node'} ||
                                 $sorted_nodes[$#sorted_nodes] == $WAYS{$next_way_id}->{'last_node'}     ) {
                                #
                                # perfect: this is a turnig roundabout where the 'bus' leaves where it entered the closed way, no reason to complain
                                #
                                printf STDERR "SortRouteWayNodes() : handle turning roundabout %s at node %s for %s:\nNodes here : %s\nNodes there: %s\n",
                                                                    $current_way_id, 
                                                                    $sorted_nodes[$#sorted_nodes], 
                                                                    $next_way_id, 
                                                                    join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} ), 
                                                                    join( ', ', @{$WAYS{$next_way_id}->{'node_array'}} )     if ( $debug );
                            }
                            else {
                                printf STDERR "SortRouteWayNodes() : handle partially used roundabout %s at node %s for %s:\nNodes here : %s\nNodes there: %s\n",
                                                                    $current_way_id, 
                                                                    $sorted_nodes[$#sorted_nodes], 
                                                                    $next_way_id, 
                                                                    join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} ), 
                                                                    join( ', ', @{$WAYS{$next_way_id}->{'node_array'}} )     if ( $debug );
                                
                                $relation_ptr->{'number_of_roundabouts'}++;
                                
                                if ( isNodeInNodeArray($WAYS{$next_way_id}->{'first_node'},@{$WAYS{$current_way_id}->{'node_array'}}) || 
                                     isNodeInNodeArray($WAYS{$next_way_id}->{'last_node'}, @{$WAYS{$current_way_id}->{'node_array'}})     ){
                                    #
                                    # there is a match with first or last node of next way and some node of this roundabout
                                    # so we're deleting superflous nodes from the top of sorted_nodes until we hit the connecting node
                                    #
                                    while ( $sorted_nodes[$#sorted_nodes] != $WAYS{$next_way_id}->{'first_node'} &&
                                            $sorted_nodes[$#sorted_nodes] != $WAYS{$next_way_id}->{'last_node'}     ) {
                                        printf STDERR "SortRouteWayNodes() : pop() Node %s from \@sorted_nodes\n", $sorted_nodes[$#sorted_nodes]     if ( $debug );
                                        pop( @sorted_nodes );
                                    }
                                }
                                else {
                                    #
                                    # no way out, we do not have any connection between any node of this way and the next way
                                    #
                                    printf STDERR "SortRouteWayNodes() : no match between this closed Way %s and the next Way %s\n", $current_way_id, $next_way_id      if ( $debug );
                                    push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                                    $relation_ptr->{'number_of_segments'}++;
                                    printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at Way %s and the next Way %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, $next_way_id      if ( $debug );
                                }
                            }
                        }
                        else {
                            printf STDERR "SortRouteWayNodes() : handle Nodes of first, closed, single Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                                push( @sorted_nodes, $node_id );
                            }
                            push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                            $relation_ptr->{'number_of_segments'}++;
                            printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at first, closed, single Way %s:\nNodes: %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                        }
                    }
                    elsif ( 0 != ($entry_node_id=isOneway($current_way_id,undef)) ) {
                        if ( $connecting_node_id == $entry_node_id ) {
                            #
                            # perfect, entering the oneway in the right or allowed direction
                            #
                            if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                #
                                # perfect order for this way (oneway=yes, junction=roundabout): last node of former segment is first node of this way
                                #
                                printf STDERR "SortRouteWayNodes() : handle Nodes of oneway Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                                pop( @sorted_nodes );     # don't add connecting node twice
                                foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                                    push( @sorted_nodes, $node_id );
                                }
                            }
                            else {
                                #
                                # not so perfect (oneway=-1), but we can take the nodes of this way in reverse order
                                #
                                printf STDERR "SortRouteWayNodes() : handle Nodes of oneway Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                                pop( @sorted_nodes );     # don't add connecting node twice
                                foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}})) {
                                    push( @sorted_nodes, $node_id );
                                }
                            }
                        }
                        else{
                            if ( $connecting_node_id == $WAYS{$current_way_id}->{'last_node'}  ||
                                 $connecting_node_id == $WAYS{$current_way_id}->{'first_node'}    ) {
                                #
                                # oops! entering oneway in wrong direction, copying nodes assuming we are allowd to do so
                                #
                                if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                    printf STDERR "SortRouteWayNodes() : entering oneway in wrong direction Way %s:\nNodes: %s, reverse( %s )\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                                    foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}}) ) {
                                        push( @sorted_nodes, $node_id );
                                    }
                                }
                                else {
                                    printf STDERR "SortRouteWayNodes() : entering oneway in wrong direction Way %s:\nNodes: %s, %s\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                                    foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}} ) {
                                        push( @sorted_nodes, $node_id );
                                    }
                                }
                                $relation_ptr->{'wrong_direction_oneways'}->{$current_way_id} = 1;
                            }
                            else {
                                #
                                # no match, i.e. a gap between this (current) way and the way before
                                #
                                push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                                if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                    printf STDERR "SortRouteWayNodes() : mark a gap before oneway Way %s:\nNodes: %s, G, %s\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                                    foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                                        push( @sorted_nodes, $node_id );
                                    }
                                }
                                else {
                                    printf STDERR "SortRouteWayNodes() : mark a gap before oneway Way %s:\nNodes: %s, G, reverse(%)s\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                                    foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}}) ) {
                                        push( @sorted_nodes, $node_id );
                                    }
                                }
                                printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ at gap between this (current) way and the way before\n"     if ( $debug );
                                $relation_ptr->{'number_of_segments'}++;
                                $connecting_node_id = 0;
                            }
                        }
                    }
                    elsif ( $connecting_node_id eq $WAYS{$current_way_id}->{'first_node'} ) {
                        #
                        # perfect order for this way: last node of former segment is first node of this way
                        #
                        printf STDERR "SortRouteWayNodes() : handle Nodes of Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                        pop( @sorted_nodes );     # don't add connecting node twice
                        foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                            push( @sorted_nodes, $node_id );
                        }
                    }
                    elsif ( $connecting_node_id eq $WAYS{$current_way_id}->{'last_node'} ) {
                        #
                        # not so perfect, but we can take the nodes of this way in reverse order
                        #
                        printf STDERR "SortRouteWayNodes() : handle Nodes of Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                        pop( @sorted_nodes );     # don't add connecting node twice
                        foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}})) {
                            push( @sorted_nodes, $node_id );
                        }
                    }
                    else {
                        #
                        # no match, i.e. a gap between this (current) way and the way before
                        #
                        printf STDERR "SortRouteWayNodes() : mark a gap before Way %s:\nNodes: %s, G, %s\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                        push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                        foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                            push( @sorted_nodes, $node_id );
                        }
                        $relation_ptr->{'number_of_segments'}++;
                        printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d before Way %s:\nNodes: %s, G, %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                        $connecting_node_id = 0;
                    }
                }
                if ( $connecting_node_id == 0 ) {
                    #
                    printf STDERR "SortRouteWayNodes() : Connecting Node 0\n"       if ( $debug );
                    #
                    # we're at the beginning of the first or a new segment
                    #
                    if ( isClosedWay($current_way_id) ) {
                        #
                        # no direct match, this current way is a closed way, roundabout or whatever, where first node is also last node
                        # find a node in this way which connects to the first or last node of the next way
                        #
                        if ( ($index=IndexOfNodeInNodeArray($WAYS{$next_way_id}->{'first_node'},@{$WAYS{$current_way_id}->{'node_array'}})) >= 0 ||
                             ($index=IndexOfNodeInNodeArray($WAYS{$next_way_id}->{'last_node'}, @{$WAYS{$current_way_id}->{'node_array'}})) >= 0    ) {
                            printf STDERR "SortRouteWayNodes() : handle Nodes of first, closed Way %s with Index %d:\nNodes: %s\n", $current_way_id, $index, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            my $i = 0;
                            for ( $i = $index+1; $i <= $#{$WAYS{$current_way_id}->{'node_array'}}; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'node_array'}}[$i] );
                            }
                            for ( $i = 0; $i <= $index; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'node_array'}}[$i] );
                            }
                        }
                        else {
                            printf STDERR "SortRouteWayNodes() : handle Nodes of first, closed, single Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                                push( @sorted_nodes, $node_id );
                            }
                            push( @sorted_nodes, 0 );                   # mark a gap in the sorted nodes
                            $relation_ptr->{'number_of_segments'}++;
                            printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at Nodes of first, closed, single Way %s:\nNodes: %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
    
                        }
                    }
                    elsif ( 0 != ($entry_node_id=isOneway($current_way_id,undef)) ) {
                        if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                            #
                            # perfect order for this way (oneway=yes, junction=roundabout): start at first node of this way
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes of first oneway Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                                push( @sorted_nodes, $node_id );
                            }
                        }
                        else {
                            #
                            # not so perfect (oneway=-1), but we can take the nodes of this way in reverse order
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes of first oneway Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}})) {
                                push( @sorted_nodes, $node_id );
                            }
                        }
                    }
                    elsif ( isClosedWay($next_way_id) ) {
                        #
                        # no direct match, this current way shall connect to a closed way, roundabout or whatever, where first node is also last node
                        # check whether first or last node of this way is one of the nodes of the next, closed way, so that we have a connectting point
                        #
                        if ( ($index=IndexOfNodeInNodeArray($WAYS{$current_way_id}->{'last_node'},@{$WAYS{$next_way_id}->{'node_array'}})) >= 0 ) {
                            #
                            # perfect match, last node of this way is a node of the next roundabout
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes for last Node %s of first Way %s connecting to a closed Way %s with Index %d:\nNodes: %s\n", $WAYS{$current_way_id}->{'first_node'}, $current_way_id, $next_way_id. $index, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                                push( @sorted_nodes, $node_id );
                            }
                        }
                        elsif ( ($index=IndexOfNodeInNodeArray($WAYS{$current_way_id}->{'first_node'},@{$WAYS{$next_way_id}->{'node_array'}})) >= 0 ) {
                            #
                            # not so perfect match, but first node of this way is a node of the next roundabout
                            # take nodes of this way in reverse order
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes for first Node %s of first Way %s connecting to a closed Way %s with Index %d:\nNodes: reverse( %s )\n", $WAYS{$current_way_id}->{'first_node'}, $current_way_id, $next_way_id. $index, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}})) {
                                push( @sorted_nodes, $node_id );
                            }
                        }
                        else {
                            #
                            # no match at all into next, closed way, i.e. a gap between this (current) way and the next, closed way
                            # take nodes of this way in normal order and mark a gap after that
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes of single Way %s before a closed Way %s:\nNodes: %s, G\n", $current_way_id, $next_way_id, oin( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                            foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                                push( @sorted_nodes, $node_id );
                            }
                            push( @sorted_nodes, 0 );                   # mark a gap in the sorted nodes
                            $relation_ptr->{'number_of_segments'}++;
                            printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at Nodes of single Way %s before a closed Way %s:\nNodes: %s, G\n", $relation_ptr->{'number_of_segments'}, $current_way_id, $next_way_id, oin( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                        }
                    }
                    elsif ( $WAYS{$current_way_id}->{'last_node'} == $WAYS{$next_way_id}->{'first_node'}   ||
                            $WAYS{$current_way_id}->{'last_node'} == $WAYS{$next_way_id}->{'last_node'}       ) {
                        #
                        # perfect order for this way: last node of this segment is first or last node of next segment
                        #
                        printf STDERR "SortRouteWayNodes() : handle Nodes of first Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                        foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                            push( @sorted_nodes, $node_id );
                        }
                    }
                    elsif ( $WAYS{$current_way_id}->{'first_node'} == $WAYS{$next_way_id}->{'first_node'}   ||
                            $WAYS{$current_way_id}->{'first_node'} == $WAYS{$next_way_id}->{'last_node'}       ) {
                        #
                        # not so perfect, but we can take the nodes of this way in reverse order
                        #
                        printf STDERR "SortRouteWayNodes() : handle Nodes of first Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                        foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}})) {
                            push( @sorted_nodes, $node_id );
                        }
                    }
                    else {
                        #
                        # no match at all, i.e. a gap between this (current) way and the next way
                        #
                        printf STDERR "SortRouteWayNodes() : handle Nodes of single Way %s:\nNodes: %s, G\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                        foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                            push( @sorted_nodes, $node_id );
                        }
                        push( @sorted_nodes, 0 );                   # mark a gap in the sorted nodes
                        $relation_ptr->{'number_of_segments'}++;
                        printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at Nodes of single Way %s:\nNodes: %s, G\n", $relation_ptr->{'number_of_segments'}, $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                    }
                }
            }
            else {
                #
                # handle last way
                #
                if ( $connecting_node_id ) {
                    #
                    printf STDERR "SortRouteWayNodes() : Connecting Node for last way %d\n", $connecting_node_id       if ( $debug );
                    #
                    # handle last way by appending its nodes in right order to the segment
                    #
                    if ( isClosedWay($current_way_id) ) {
                        #
                        # no direct match, this current way is a closed way, roundabout or whatever, where first node is also last node
                        # check whether connecting node is a node of this, closed way
                        #
                        if ( ($index=IndexOfNodeInNodeArray($connecting_node_id,@{$WAYS{$current_way_id}->{'node_array'}})) >= 0 ) {
                            printf STDERR "SortRouteWayNodes() : handle Nodes of last, closed Way %s with Index %d:\nNodes: %s\n", $current_way_id, $index, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            my $i = 0;
                            for ( $i = $index+1; $i <= $#{$WAYS{$current_way_id}->{'node_array'}}; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'node_array'}}[$i] );
                            }
                            for ( $i = 0; $i <= $index; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'node_array'}}[$i] );
                            }
                        }
                        else {
                            push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                            printf STDERR "SortRouteWayNodes() : handle Nodes of last, closed, isolated Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                                push( @sorted_nodes, $node_id );
                            }
                            $relation_ptr->{'number_of_segments'}++;
                            printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at Nodes of last, closed, isolated Way %s:\nNodes: %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                        }
                    }
                    elsif ( 0 != ($entry_node_id=isOneway($current_way_id,undef)) ) {
                        if ( $connecting_node_id == $entry_node_id ) {
                            #
                            # perfect, entering the oneway in the right or allowed direction
                            #
                            if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                #
                                # perfect order for this way (oneway=yes, junction=roundabout): last node of former segment is first node of this way
                                #
                                printf STDERR "SortRouteWayNodes() : handle Nodes of oneway Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                                pop( @sorted_nodes );     # don't add connecting node twice
                                foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                                    push( @sorted_nodes, $node_id );
                                }
                            }
                            else {
                                #
                                # not so perfect (oneway=-1), but we can take the nodes of this way in reverse order
                                #
                                printf STDERR "SortRouteWayNodes() : handle Nodes of oneway Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                                pop( @sorted_nodes );     # don't add connecting node twice
                                foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}})) {
                                    push( @sorted_nodes, $node_id );
                                }
                            }
                        }
                        else{
                            if ( $connecting_node_id == $WAYS{$current_way_id}->{'last_node'}  ||
                                 $connecting_node_id == $WAYS{$current_way_id}->{'first_node'}    ) {
                                #
                                # oops! entering oneway in wrong direction, copying nodes assuming we are allowd to do so
                                #
                                if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                    printf STDERR "SortRouteWayNodes() : entering oneway in wrong direction Way %s:\nNodes: %s, reverse( %s )\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                                    foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}})) {
                                        push( @sorted_nodes, $node_id );
                                    }
                                }
                                else {
                                    printf STDERR "SortRouteWayNodes() : entering oneway in wrong direction Way %s:\nNodes: %s, %s\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                                    foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}} ) {
                                        push( @sorted_nodes, $node_id );
                                    }
                                }
                                $relation_ptr->{'wrong_direction_oneways'}->{$current_way_id} = 1;
                            }
                            else {
                                #
                                # no match, i.e. a gap between this (current) way and the way before, we will follow the oneway in the intended direction
                                #
                                push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                                if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                    printf STDERR "SortRouteWayNodes() : mark a gap before oneway Way %s:\nNodes: %s, G, %s, G\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                                    foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                                        push( @sorted_nodes, $node_id );
                                    }
                                }
                                else {
                                    printf STDERR "SortRouteWayNodes() : mark a gap before oneway Way %s:\nNodes: %s, G, reverse( %s ), G\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                                    foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}}) ) {
                                        push( @sorted_nodes, $node_id );
                                    }
                                }
                                $relation_ptr->{'number_of_segments'}++;
                                printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at gap between this (current) way and the way before, we will follow the oneway in the intended direction\n", $relation_ptr->{'number_of_segments'}, $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )    if ( $debug );
                                $connecting_node_id = 0;
                            }
                        }
                    }
                    elsif ( $connecting_node_id eq $WAYS{$current_way_id}->{'first_node'} ) {
                        printf STDERR "SortRouteWayNodes() : handle Nodes of last, connected Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                        pop( @sorted_nodes );     # don't add connecting node twice
                        foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                            push( @sorted_nodes, $node_id );
                        }
                    }
                    elsif ( $connecting_node_id eq $WAYS{$current_way_id}->{'last_node'} ) {
                        printf STDERR "SortRouteWayNodes() : handle Nodes of last, connected Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                        pop( @sorted_nodes );     # don't add connecting node twice
                        foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}})) {
                            push( @sorted_nodes, $node_id );
                        }
                    }
                    else {
                        printf STDERR "SortRouteWayNodes() : last, isolated Way %s and Node %s\n", $current_way_id, $connecting_node_id     if ( $debug );
                        push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                        foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                            push( @sorted_nodes, $node_id );
                        }
                        $relation_ptr->{'number_of_segments'}++;
                        printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d last, isolated Way %s and Node %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, $connecting_node_id     if ( $debug );
                    }
                }
                else {
                    #
                    printf STDERR "SortRouteWayNodes() : Connecting Node for last way is ZERO\n"                if ( $debug );
                    #
                    # seems that that there was only one way at all or the last segment consists of only one way
                    #
                    if ( 0 != ($entry_node_id=isOneway($current_way_id,undef)) ) {
                        if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                            #
                            # perfect order for this way (oneway=yes, junction=roundabout): we can take the nodes of this way in this order
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes of last, isolated, single oneway Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            pop( @sorted_nodes );     # don't add connecting node twice
                            foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                                push( @sorted_nodes, $node_id );
                            }
                        }
                        else {
                            #
                            # not so perfect (oneway=-1), but we can take the nodes of this way in reverse order
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes of last, isolated, single oneway Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                            pop( @sorted_nodes );     # don't add connecting node twice
                            foreach $node_id ( reverse(@{$WAYS{$current_way_id}->{'node_array'}})) {
                                push( @sorted_nodes, $node_id );
                            }
                        }
                    }
                    else {
                        printf STDERR "SortRouteWayNodes() : handle Nodes of last, isolated Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'node_array'}} )     if ( $debug );
                        foreach $node_id ( @{$WAYS{$current_way_id}->{'node_array'}}) {
                            push( @sorted_nodes, $node_id );
                        }
                    }
                    $relation_ptr->{'number_of_segments'}++ unless ( $number_of_ways == 1 );  # a single way cannot have 2 segments
                    printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'} = %d at handle Nodes of last, isolated Way\n", $relation_ptr->{'number_of_segments'}    if ( $debug );
                }
            }
            
            $connecting_node_id = $sorted_nodes[$#sorted_nodes];
        }
    
        if ( $debug ) {
            foreach $node_id ( @control_nodes ) {
                $counter = isNodeInNodeArray( $node_id, @sorted_nodes );
                printf STDERR "SortRouteWayNodes() : Node %s has been considered %d times\n", $node_id, $counter   if ( $counter != 1 );
            }
        
            printf STDERR "SortRouteWayNodes() : returning Nodes:\nNodes: %s\n", join( ', ', @sorted_nodes );
            printf STDERR "%s\n", join( '', map { $_ ? '_' : 'G' } @sorted_nodes );
        
        }
    }
    
    return @sorted_nodes;
}


#############################################################################################

sub isNodeInNodeArray {
    my $node_id         = shift;
    my @node_array      = @_;
    
    my $node_of_way     = undef;
    my $return_code     = 0;
    
    if ( $node_id && @node_array ) {
        foreach $node_of_way ( @node_array ) {
            if ( $node_of_way eq $node_id ) {
                $return_code++;
                printf STDERR "... match found for Node-ID %d\n", $node_id       if ( $debug );
            }
        }
    }
    printf STDERR "isNodeInNodeArray() returns %d for node-ID %d\n", $return_code, $node_id       if ( $debug );
    return $return_code;
}


#############################################################################################

sub IndexOfNodeInNodeArray {
    my $node_id         = shift;
    my @node_array      = @_;
    
    my $index           = undef;
   
    if ( $node_id && @node_array ) {
        for ( $index = 0; $index <= $#node_array; $index++ ) {
            if ( $node_array[$index] == $node_id ) {
                printf STDERR "IndexOfNodeInNodeArray() : ... match found for Node-ID %s at index %d\n", $node_id, $index       if ( $debug );
                return $index;
            }
        }
    }
    printf STDERR "IndexOfNodeInNodeArray() : ... no match found for Node-ID %s\n", $node_id       if ( $debug );
    return -1;
}


#############################################################################################

sub isFirstNodeInNodeArray {
    my $node_id         = shift;
    my @node_array      = @_;
    
    if ( $node_id && @node_array ) {
        if ( $node_array[0] == $node_id    ) {
            printf STDERR "... match found for Node-ID %d, $node_id\n"       if ( $debug );
            return 1;
        }
    }
    printf STDERR "isFirstNodeInNodeArray() returns 0 for node-ID %d\n", $node_id       if ( $debug );
    return 0;
}


#############################################################################################

sub isLastNodeInNodeArray {
    my $node_id         = shift;
    my @node_array      = @_;
    
    if ( $node_id && @node_array ) {
        if ( $node_array[$#node_array] == $node_id    ) {
            printf STDERR "... match found for Node-ID %d, $node_id\n"       if ( $debug );
            return 1;
        }
    }
    printf STDERR "isLastNodeInNodeArray() returns 0 for node-ID %d\n", $node_id       if ( $debug );
    return 0;
}


#############################################################################################

sub isOneway {
    my $way_id          = shift;
    my $vehicle_type    = shift;        # optional !
    
    my $entry_node_id   = 0;
    
    if ( $way_id && $WAYS{$way_id} ) {
        if ( $vehicle_type ) {
        }
        else {
            if ( ($WAYS{$way_id}->{'tag'}->{'oneway:bus'} && $WAYS{$way_id}->{'tag'}->{'oneway:bus'} eq 'no')            ||
                 ($WAYS{$way_id}->{'tag'}->{'oneway:psv'} && $WAYS{$way_id}->{'tag'}->{'oneway:psv'} eq 'no')            || 
                 ($WAYS{$way_id}->{'tag'}->{'busway'}     && $WAYS{$way_id}->{'tag'}->{'busway'}     eq 'opposite_lane')    ) {
                # bus may enter the road in either direction, return 0: don't care about entry point
                printf STDERR "isOneway() : no for bus/psv for Way %d\n", $way_id       if ( $debug );
                return 0;
            }
            elsif ( $WAYS{$way_id}->{'tag'}->{'oneway'} && $WAYS{$way_id}->{'tag'}->{'oneway'} eq 'yes' ) {
                $entry_node_id = $WAYS{$way_id}->{'first_node'};
                printf STDERR "isOneway() : yes for all for Way %d, entry at first Node %d\n", $way_id, $entry_node_id       if ( $debug );
                return $entry_node_id;
            }
            elsif ( $WAYS{$way_id}->{'tag'}->{'oneway'} && $WAYS{$way_id}->{'tag'}->{'oneway'} eq '-1'  ) {
                $entry_node_id = $WAYS{$way_id}->{'last_node'};
                printf STDERR "isOneway() : yes for all for Way %d, entry at last Node %d\n", $way_id, $entry_node_id       if ( $debug );
                return $entry_node_id;
            }
            elsif ( $WAYS{$way_id}->{'tag'}->{'junction'} && $WAYS{$way_id}->{'tag'}->{'junction'} eq 'roundabout' ) {
                $entry_node_id = $WAYS{$way_id}->{'first_node'};
                printf STDERR "isOneway() : yes for all for Way %d, entry at first Node %d\n", $way_id, $entry_node_id       if ( $debug );
                return $entry_node_id;
            }
        }
    }
    printf STDERR "isOneway() : no for all for Way %d\n", $way_id       if ( $debug );
    return 0;
}


#############################################################################################

sub isClosedWay {
    my $way_id  = shift;
    
    if ( $way_id && $WAYS{$way_id} ) {
        if ( $WAYS{$way_id}->{'first_node'} && $WAYS{$way_id}->{'last_node'} ) {
            if ( $WAYS{$way_id}->{'first_node'} == $WAYS{$way_id}->{'last_node'} ) {
                printf STDERR "isClosedWay() : yes for Way %d\n", $way_id       if ( $debug );
                return 1;
            }
        } else {
            printf STDERR "%s WAYS{%s}->{'first_node'} is undefined\n", get_time(), $way_id     if ( !$WAYS{$way_id}->{'first_node'} );
            printf STDERR "%s WAYS{%s}->{'last_node'}  is undefined\n", get_time(), $way_id     if ( !$WAYS{$way_id}->{'last_node'}  );
        }
    }
    printf STDERR "isClosedWay() : no for Way %d\n", $way_id       if ( $debug );
    return 0;
}


#############################################################################################

sub isNodeArrayClosedWay {
    my @node_array = @_;
    
    if ( @node_array ) {
        if ( $node_array[0] == $node_array[$#node_array] ) {
            printf STDERR "isNodeArrayClosedWay() : yes\n"       if ( $debug );
            return 1;
        }
    }
    printf STDERR "isNodeArrayClosedWay() : no\n"       if ( $debug );
    return 0;
}


#############################################################################################

sub noAccess {
    my $way_id          = shift;
    my $vehicle_type    = shift;        # optional !
    
    if ( $way_id && $WAYS{$way_id} && $vehicle_type ) {
        my $way_tag_ref = $WAYS{$way_id}->{'tag'};
        if ( $vehicle_type eq 'bus' || $vehicle_type eq 'share_taxi' || $vehicle_type eq 'trolleybus' ) {
            if ( ($way_tag_ref->{'bus'} && ($way_tag_ref->{'bus'} eq 'yes' || $way_tag_ref->{'bus'} eq 'designated' || $way_tag_ref->{'bus'} eq 'official')) ||
                 ($way_tag_ref->{'psv'} && ($way_tag_ref->{'psv'} eq 'yes' || $way_tag_ref->{'psv'} eq 'designated' || $way_tag_ref->{'psv'} eq 'official'))    ) {
                ; # fine
            }
            else {
                foreach my $access_restriction ( 'no', 'private' ) {
                    foreach my $access_type ( 'access', 'vehicle', 'motor_vehicle', 'motor_car' ) {
                        if ( $way_tag_ref->{$access_type} && $way_tag_ref->{$access_type} eq $access_restriction ) {
                            printf STDERR "noAccess() : no for %s for way %d (%s=%s)\n", $vehicle_type, $way_id, $access_type, $access_restriction       if ( $debug );
                            return $access_type . '=' . $access_restriction;
                        }
                    }
                }
                foreach my $highway_type ( 'pedestrian', 'footway', 'cycleway', 'path', 'construction' ) {
                    if ( $way_tag_ref->{'highway'} && $way_tag_ref->{'highway'} eq $highway_type ) {
                        if ( ($way_tag_ref->{'access'}          && $way_tag_ref->{'access'}         eq 'yes') ||
                             ($way_tag_ref->{'vehicle'}         && $way_tag_ref->{'vehicle'}        eq 'yes') ||
                             ($way_tag_ref->{'motor_vehicle'}   && $way_tag_ref->{'motor_vehicle'}  eq 'yes') ||
                             ($way_tag_ref->{'motor_car'}       && $way_tag_ref->{'motor_car'}      eq 'yes')    ) {
                            ; # fine
                        }
                        else {
                            printf STDERR "noAccess() : no for %s for way %d (%s=%s)\n", $vehicle_type, $way_id, 'highway', $highway_type       if ( $debug );
                            return 'highway=' . $highway_type;
                        }
                    }
                }
            }
        }
    }
    printf STDERR "noAccess() : access for all for way %d\n", $way_id       if ( $debug );
    return '';
}


#############################################################################################
#
# functions for printing wiki page code
#
#############################################################################################

my $no_of_columns               = 0;
my @columns                     = ();
my @table_columns               = ();
my $max_templates               = 0;            # do not print more than xxx wiki-templates, set later on
my $number_of_printed_templates = 0;
my @html_header_anchors         = ();
my @html_header_anchor_numbers  = (0,0,0,0,0,0,0);

sub printInitialHeader {
    my $title       = shift;
    my $osm_base    = shift;
    my $areas       = shift;
    
    $no_of_columns               = 0;
    @columns                     = ();
    @table_columns               = ();
    $max_templates               = 700;
    $number_of_printed_templates = 0;

    if ( $print_wiki ) {
        #
        # WIKI code
        #
        print  "{{TOC limit|3}}\n";
        print  "\n";
        if ( $osm_base || $areas ) {
            printBigHeader( "Datum der Daten" );
            printf "OSM-Base Time : %s<br>\n", $osm_base          if ( $osm_base );
            printf "Areas Time    : %s<br>\n", $areas             if ( $areas    );
            print  "<br>\n";
        }
        print  "Die Analyse läuft in der Regel abends zwischen 19:00 und 20:00 Uhr.<br>\n";
        print  "<br>\n";
        print  "Die Daten im Wiki werden gegebenenfalls nur aktualisiert, wenn sich das Ergebnis der Analyse geändert hat.<br>\n";
        print  "\n";
        print  "Weitere Details sind auf der hier zugehörigen Diskussionsseite zu finden.<br>\n";
        print  "\n";
        print  "Eine Erläuterung der Fehlertexte ist auf der Seite von [[User:ToniE/analyze-routes#Momentane_Prüfungen|analyze-routes]] zu finden.<br>\n";
        print  "\n";
    }
    else {
        #
        # HTML
        #
        print  "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\">\n";
        print  "<html>\n";
        print  "    <head>\n";
        printf "        <title>%sOSM - Public Transport Analysis</title>\n", ($title ? $title . ' - ' : '');
        print  "        <meta name=\"generator\" content=\"analyze-routes.pl\">\n";
        print  "        <meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\" />\n";
        print  "        <meta name=\"language\" content=\"de\" />\n";
        print  "        <meta name=\"keywords\" content=\"OSM Public Transport PTv2\" />\n";
        print  "        <meta name=\"description\" content=\"OSM - Public Transport Analysis\" />\n";
        print  "        <style type=\"text/css\">\n";
        print  "              table { border-width: 1px; border-style: solid; border-collapse: collapse; vertical-align: center; }\n";
        print  "              th    { border-width: 1px; border-style: solid; border-collapse: collapse; padding: 0.2em; }\n";
        print  "              td    { border-width: 1px; border-style: solid; border-collapse: collapse; padding: 0.2em; }\n";
        print  "              ol    { list-style: none; }\n";
        print  "              img   { witdh: 20px }\n";
        print  "              .tableheaderrow   { background-color: LightSteelBlue;   }\n";
        print  "              .sketchline       { background-color: LightBlue;        }\n";
        print  "              .sketch           { text-align:left;  font-weight: 500; }\n";
        print  "              .csvinfo          { text-align:right; font-size: 0.8em; }\n";
        print  "              .ref              { white-space:nowrap; }\n";
        print  "              .relation         { white-space:nowrap; }\n";
        print  "              .PTv              { text-align:center; }\n";
        print  "        </style>\n";
        print  "    </head>\n";
        print  "    <body>\n";
        print  "    <!-- split here for table of contents -->\n";
        if ( $osm_base || $areas ) {
            printBigHeader( "Datum der Daten" );
            printf "OSM-Base Time : %s<br>\n", $osm_base          if ( $osm_base );
            printf "Areas Time    : %s<br>\n", $areas             if ( $areas    );
            print  "\n";
            print  "<br>\n";
        }
        print  "Die Analyse läuft in der Regel abends zwischen 19:00 und 20:00 Uhr.<br>\n";
        print  "<br>\n";
        print  "Die Daten im Wiki werden gegebenenfalls nur aktualisiert, wenn sich das Ergebnis der Analyse geändert hat.<br>\n";
        print  "\n";
        print  "Weitere Details sind auf der hier zugehörigen Diskussionsseite zu finden.<br>\n";
        print  "\n";
        print  "Eine Erläuterung der Fehlertexte ist auf der Seite von <a href='https://wiki.openstreetmap.org/wiki/User:ToniE/analyze-routes#Momentane_Prüfungen'>analyze-routes</a> zu finden.<br>\n";
        print  "\n";
    }

}


#############################################################################################

sub printFinalFooter {

    if ( $print_wiki ) {
        #
        # WIKI code
        #
        print "<!-- end of file -->"
    }
    else {
        #
        # HTML
        #
        print  "    </body>\n";
        print  "</html>\n";
        
        printTableOfContents();
        
    }
}


#############################################################################################

sub printTableOfContents {
    
    if ( $print_wiki ) {
        #
        # WIKI code
        #
        ;
    }
    else {
        my $toc_line        = undef;
        my $last_level      = 0;
        my $anchor_level    = undef;
        my $header_number   = undef;
        my $header_text     = undef;
        #
        # HTML
        #
        print "        <!-- split here for table of contents -->\n";
        print "        <h1>Inhaltsverzeichnis</h1>\n";
        foreach $toc_line ( @html_header_anchors ) {
            if ( $toc_line =~ m/^L(\d+)\s+([0-9\.]+)\s+(.*)$/ ) {
                $anchor_level   = $1;
                $header_number  = $2;
                $header_text    = wiki2html($3);
                if ( $anchor_level <= $last_level ) {
                    print "        </li>\n";
                }
                if ( $anchor_level < $last_level ) {
                    while ( $anchor_level < $last_level ) {
                        print "        </ol>\n        </li>\n";
                        $last_level--;
                    }
                } else {
                    while ( $anchor_level > $last_level ) {
                        print "        <ol>\n";
                        $last_level++;
                    }
                }
                printf "        <li>%s <a href=\"#A%s\">%s</a>\n", $header_number, $header_number, $header_text;
            } else {
                printf STDERR "%s Missmatch in TOC line '%s'\n", get_time(), $toc_line;
            }
        }
        while ( $last_level > 0) {
            print "        </li>\n        </ol>\n";
            $last_level--;
        }
    }
}


#############################################################################################

sub printBigHeader {
    my $title    = shift;
    
    printHeader( '= ' . $title )  if ( $title );
}


#############################################################################################

sub printHintSuspiciousRelations {
    if ( $print_wiki ) {
        #
        # WIKI code
        #
        print  "Dieser Abschnitt enthält alle Relationen, die verdächtig sind:\n";
        print  "* evtl. falsche 'route' oder 'route_master' Werte?\n";
        print  "** z.B. 'route' = 'suspended_bus' statt 'route' = 'bus'\n";
        print  "* aber auch 'type' = 'network', 'type' = 'set' oder 'route' = 'network', d.h. eine Sammlung aller zum 'network' gehörenden Route und Route-Master.\n";
        print  "** solche '''Sammlungen sind Fehler''', da Relationen keinen Sammlungen darstellen sollen: [[DE:Relationen/Relationen_sind_keine_Kategorien|Relationen sind keine Kategorien]]\n";
        print  "\n";
    }
    else {
        #
        # HTML
        #
        print  "Dieser Abschnitt enthält alle Relationen, die verdächtig sind:\n";
        print  "<ul>\n";
        print  "    <li>evtl. falsche 'route' oder 'route_master' Werte?\n";
        print  "        <ul>\n";
        print  "            <li>z.B. 'route' = 'suspended_bus' statt 'route' = 'bus'</li>\n";
        print  "        </ul>\n";
        print  "    </li>\n";
        print  "    <li>aber auch 'type' = 'network', 'type' = 'set' oder 'route' = 'network', d.h. eine Sammlung aller zum 'network' gehörenden Route und Route-Master.\n";
        print  "        <ul>\n";
        print  "            <li>solche '''Sammlungen sind Fehler''', da Relationen keinen Sammlungen darstellen sollen: <a href=\"https://wiki.openstreetmap.org/wiki/DE:Relationen/Relationen_sind_keine_Kategorien\">Relationen sind keine Kategorien</a></li>\n";
        print  "        </ul>\n";
        print  "    </li>\n";
        print  "</ul>\n";
        print  "\n";
    }
}


#############################################################################################

sub printHintUnusedNetworks {
    if ( $print_wiki ) {
        #
        # WIKI code
        #
        print  "Dieser Abschnitt listet die 'network'-Werte auf, die nicht berücksichtigt wurden.<br />\n";
        print  "Darunter können auch Tippfehler in ansonsten zu berücksichtigenden Werten sein.<br />\n";
        print  "<br />\n";
    }
    else {
        #
        # HTML
        #
        ;
        print  "Dieser Abschnitt listet die 'network'-Werte auf, die nicht berücksichtigt wurden.<br />\n";
        print  "Darunter können auch Tippfehler in ansonsten zu berücksichtigenden Werten sein.<br />\n";
        print  "<br />\n";
    }
}
    

#############################################################################################

sub printToolOptions {

    if ( $print_wiki ) {
        #
        # WIKI code
        #
        print  "Die Ausgabe von Fehlern und Anmerkungen kann durch eine Vielzahl von Auswertungsoptionen beeinflusst werden.<br />\n";
        print  "Hier ist eine [[User_talk:ToniE/Transportation/Analyse#Momentane_Prüfungen|Auflistung der Texte der Fehlermeldungen und Anmerkungen]].<br />\n";
        print  "<br />\n";
    }
    else {
        #
        # HTML
        #
        print  "Die Ausgabe von Fehlern und Anmerkungen kann durch eine Vielzahl von Auswertungsoptionen beeinflusst werden.<br />\n";
        print  "Hier ist eine <a href=\"https://wiki.openstreetmap.org/wiki/User_talk:ToniE/Transportation/Analyse#Momentane_Prüfungen\">Auflistung der Texte der Fehlermeldungen und Anmerkungen</a>.<br />\n";
        print  "<br />\n";
        ;
    }
    
    printTableHeader();
    printTableLine( 'Option' => 'check-access',             'Wert' =>  ($check_access               ? 'ON' : 'OFF'),                        'Anmerkung' => 'Es werden Wege benutzt, die explizit oder implizit nicht befahren werden dürfen und wo bus="yes", bus="designated", bus="official", psv="yes", ... fehlt.' );
    printTableLine( 'Option' => 'check-bus-stop',           'Wert' =>  ($check_bus_stop             ? 'ON' : 'OFF'),                        'Anmerkung' => 'highway="bus_stop" darf nur auf Punkten (Nodes) gesetzt werden, nicht auf Wege oder Flächen.' );
    printTableLine( 'Option' => 'check-name',               'Wert' =>  ($check_name                 ? 'ON' : 'OFF'),                        'Anmerkung' => 'Prüfung von name="...ref: from => to" bzw. name="...ref: from => via => ... => to".' );
    printTableLine( 'Option' => 'check-platform',           'Wert' =>  ($check_platform             ? 'ON' : 'OFF'),                        'Anmerkung' => 'Fehlendes bus="yes", tram="yes" oder share_taxi="yes" bei public_transport="platform".' );
    printTableLine( 'Option' => 'check-roundabouts',        'Wert' =>  ($check_roundabouts          ? 'ON' : 'OFF'),                        'Anmerkung' => 'Prüfung, ob Kreisverkehre nur teilweise durchfahren werden, aber komplett in der Relation enthalten sind (JOSM prüft das nicht).' );
    printTableLine( 'Option' => 'check-sequence',           'Wert' =>  ($check_sequence             ? 'ON' : 'OFF'),                        'Anmerkung' => 'Prüfung, ob die Wege in der Route-Relation lückenlos sind.' );
    printTableLine( 'Option' => 'check-stop-position',      'Wert' =>  ($check_stop_position        ? 'ON' : 'OFF'),                        'Anmerkung' => 'Fehlendes bus="yes", tram="yes" oder share_taxi="yes" bei public_transport="stop_position".' );
    printTableLine( 'Option' => 'check-version',            'Wert' =>  ($check_version              ? 'ON' : 'OFF'),                        'Anmerkung' => 'Prüfung von public_transport:version="..." bei Route-Master und Route.' );
    printTableLine( 'Option' => 'coloured-sketchline',      'Wert' =>  ($coloured_sketchline        ? 'ON' : 'OFF'),                        'Anmerkung' => 'Die SketchLine berücksichtigt den Wert von colour="..." des Route-Master, der Route.' );
    printTableLine( 'Option' => 'expect-network-long',      'Wert' =>  ($expect_network_long        ? 'ON' : 'OFF'),                        'Anmerkung' => 'Der Wert von network="..." wird in der langen Form erwartet (siehe network-long-regex).' );
    printTableLine( 'Option' => 'expect-network-long-for',  'Wert' =>  ($expect_network_long_for    ? $expect_network_long_for : ''),       'Anmerkung' => 'Der Wert von network="..." wird in der langen Form erwartet, statt der hier angegebenen kurzen Form.' );
    printTableLine( 'Option' => 'expect-network-short',     'Wert' =>  ($expect_network_short       ? 'ON' : 'OFF'),                        'Anmerkung' => 'Der Wert von network="..." wird in der kurzen Form erwartet (siehe network-short-regex).' );
    printTableLine( 'Option' => 'expect-network-short-for', 'Wert' =>  ($expect_network_short_for   ? $expect_network_short_for : ''),      'Anmerkung' => 'Der Wert von network="..." wird in der kurzen Form erwartet, statt der hier angegebenen langen Form.' ); 
    printTableLine( 'Option' => 'max-error',                'Wert' =>  ($max_error                  ? $max_error : ''),                     'Anmerkung' => 'Limitiert die Anzahl der Ausgabe von Nodes, Ways, Relations bei identischen Fehlermeldungen pro Route.' );
    printTableLine( 'Option' => 'network-long-regex',       'Wert' =>  ($network_long_regex         ? ' | ' . $network_long_regex  : ''),   'Anmerkung' => 'Der Wert von network="..." der im Datensatz enthaltenen Route-Master und Routen muss diesem Muster als Langform entsprechen oder darf leer sein.' );
    printTableLine( 'Option' => 'network-short-regex',      'Wert' =>  ($network_short_regex        ? ' | ' . $network_short_regex : ''),   'Anmerkung' => 'Der Wert von network="..." der im Datensatz enthaltenen Route-Master und Routen muss diesem Muster als Kurzform entsprechen oder darf leer sein.' );
    printTableLine( 'Option' => 'operator-regex',           'Wert' =>  ($operator_regex             ? ' | ' . $operator_regex : ''),        'Anmerkung' => 'Der Wert von operator="..." der im Datensatz enthaltenen Route-Master und Routen muss diesem Muster entsprechen oder darf leer sein.' );
    printTableLine( 'Option' => 'positive-notes',           'Wert' =>  ($positive_notes             ? 'ON' : 'OFF'),                        'Anmerkung' => 'Ausgabe von network:short="...", network:guid="..." und anderen Werten.' );
    printTableLine( 'Option' => 'relaxed-begin-end-for',    'Wert' =>  ($relaxed_begin_end_for      ? $relaxed_begin_end_for : ''),         'Anmerkung' => 'Entspanntere Prüfung von Anfang und Ende einer Route bzgl. Stop-Position (zB. bei train, tram, light_rail).' );
    printTableLine( 'Option' => 'strict-network',           'Wert' =>  ($strict_network             ? 'ON' : 'OFF'),                        'Anmerkung' => 'Keine Berücksichtigung von Route-Master oder Route bei leerem network="...".' );
    printTableLine( 'Option' => 'strict-operator',          'Wert' =>  ($strict_operator            ? 'ON' : 'OFF'),                        'Anmerkung' => 'Keine Berücksichtigung von Route-Master oder Route bei leerem operator="...".' );
    printTableFooter();
    
}


#############################################################################################

sub printHeader {
    my $text = shift;

    if ( $text ) {
        $text =~ s/^\s*//;
        $text =~ s/\s*=*\s*$//;
        my $level  = undef;
        my $header = undef;
        if ( $text ) {
            #printf STDERR "working on: %s\n", $text;
            if ( $text =~ m/^(=+)([^=].*)/ ) {
                $level  =  $1;
                $header =  $2;
                $header =~ s/^\s*//;
                if ( $print_wiki ) {
                    #
                    # WIKI code
                    #
                    printf "%s %s %s\n", $level, $header, $level;
                }
                else {
                    #
                    # HTML
                    #
                    my $level_nr = 0;
                    my $header_numbers = '';
                    $level_nr++ while ( $level =~ m/=/g );
                    $level_nr = 6   if ( $level_nr > 6 );
                    if ( $level_nr == 1 ) {
                        $header_numbers = ++$html_header_anchor_numbers[1] . '.';
                        $html_header_anchor_numbers[2] = 0;
                        $html_header_anchor_numbers[3] = 0;
                        $html_header_anchor_numbers[4] = 0;
                        $html_header_anchor_numbers[5] = 0;
                        $html_header_anchor_numbers[6] = 0;
                    } elsif ( $level_nr == 2 ) {
                        $header_numbers = $html_header_anchor_numbers[1] . '.' . ++$html_header_anchor_numbers[2] . '.';
                        $html_header_anchor_numbers[3] = 0;
                        $html_header_anchor_numbers[4] = 0;
                        $html_header_anchor_numbers[5] = 0;
                        $html_header_anchor_numbers[6] = 0;
                    } elsif ( $level_nr == 3 ) {
                        $header_numbers = $html_header_anchor_numbers[1] . '.' . $html_header_anchor_numbers[2] . '.' . ++$html_header_anchor_numbers[3] . '.';
                        $html_header_anchor_numbers[4] = 0;
                        $html_header_anchor_numbers[5] = 0;
                        $html_header_anchor_numbers[6] = 0;
                    } elsif ( $level_nr == 4 ) {
                        $header_numbers = $html_header_anchor_numbers[1] . '.' . $html_header_anchor_numbers[2] . '.' . $html_header_anchor_numbers[3] . '.' . ++$html_header_anchor_numbers[4] . '.';
                        $html_header_anchor_numbers[5] = 0;
                        $html_header_anchor_numbers[6] = 0;
                    } elsif ( $level_nr == 4 ) {
                        $header_numbers = $html_header_anchor_numbers[1] . '.' . $html_header_anchor_numbers[2] . '.' . $html_header_anchor_numbers[3] . '.' . $html_header_anchor_numbers[4] . '.' . ++$html_header_anchor_numbers[5] . '.';
                        $html_header_anchor_numbers[6] = 0;
                    } elsif ( $level_nr == 6 ) {
                        $header_numbers = $html_header_anchor_numbers[1] . '.' . $html_header_anchor_numbers[2] . '.' . $html_header_anchor_numbers[3] . '.' . $html_header_anchor_numbers[4] . '.' . $html_header_anchor_numbers[5] . '.' . ++$html_header_anchor_numbers[6] . '.';
                    }
                    push( @html_header_anchors, sprintf( "L%d %s %s", $level_nr, $header_numbers, $header ) );
                    print  "        <br /><hr />\n"   if ( $level_nr == 1 );
                    printf "        <h%d id=\"A%s\">%s %s</h%d>\n", $level_nr, $header_numbers, $header_numbers, wiki2html($header), $level_nr;
                }
                printf STDERR "%s %s %s %s\n", get_time(), $level, $header, $level    if ( $verbose );
            }
        }
    }
}


#############################################################################################

sub printText {
    my $text = shift;

    if ( $text ) {
        $text =~ s/^\s*-\s*//;
        if ( $text ) {
            if ( $print_wiki ) {
                #
                # WIKI code
                #
                printf "%s", $text;
            }
            else {
                #
                # HTML
                #
                printf "%s", wiki2html($text);
            }
            printf STDERR "%s %s\n", get_time(), $text    if ( $verbose );
        }
        printf "<br />\n"
    }
}


#############################################################################################

sub printFooter {

    if ( $print_wiki ) {
        #
        # WIKI code
        #
    }
    else {
        #
        # HTML
        #
    }
}


#############################################################################################

sub printTableInitialization
{
    $no_of_columns = scalar( @_ );
    @columns       = ( @_ );
    @table_columns = map { ( $column_name{$_} ? $column_name{$_} : $_ ) } @columns;
}



#############################################################################################

sub printTableHeader {
    my $element = undef;

    if ( scalar(@table_columns) ) {
        if ( $print_wiki ) {
            #
            # WIKI code
            #
            print  "{|class=\"wikitable unsortable\"\n";
            print  "|-class=\"sorttop\"\n";
            if ( $no_of_columns == 0 ) {
                print  "!scope=\"col\" class=\"unsortable\"                 | Linienverlauf (name=)\n";
                print  "!scope=\"col\" class=\"unsortable\"                 | Typ (type=)\n";
                print  "!scope=\"col\" width=\"400\" class=\"unsortable\"   | Relation (id=)\n"; 
                printf "!scope=\"col\" class=\"unsortable\"                 | PTv\n";
                print  "!scope=\"col\" class=\"unsortable\"                 | Fehler\n";
                print  "!scope=\"col\" class=\"unsortable\"                 | Anmerkungen\n";
            }
            else {
                foreach $element ( @table_columns ) {
                    printf "!scope=\"col\" class=\"unsortable\"             | %s\n", $element;
                }
            }
        }
        else {
            #
            # HTML
            #
            printf "%8s<table class=\"oepnvtable\" summary=\"oepnvtable\">\n", ' ';
            printf "%12s<thead>\n", ' ';
            printf "%16s<tr class=\"tableheaderrow\">", ' ';
            if ( $no_of_columns == 0 ) {
                print  "<th class=\"name\">Linienverlauf (name=)</th>";
                print  "<th class=\"type\">Typ (type=)</th>";
                print  "<th class=\"relation\">Relation (id=)</th>"; 
                print  "<th class=\"PTv\">PTv</th>";
                print  "<th class=\"issues\">Fehler</th>";
                print  "<th class=\"notes\">Anmerkungen</th>";
            }
            else {
                foreach $element ( @columns ) {
                    printf "<th class=\"%s\">%s</th>", $element, ($column_name{$element} ? $column_name{$element} : $element ) ;
                }
            }
            printf "</tr>\n";
            printf "%12s</thead>\n", ' ';
            printf "%12s<tbody>\n", ' ';
        }
    }
}


#############################################################################################

sub printTableSubHeader {
    my %hash            = ( @_ );
    my $ref             = $hash{'ref'}     || '';
    my $network         = $hash{'network'} || '';
    my $pt_type         = $hash{'pt_type'} || '';
    my $colour          = $hash{'colour'}  || '';
    my $ref_text        = undef;
    my $csv_text        = '';       # some information comming from the CSV input file

    if ( $ref && $network ) {
        $ref_text = printSketchLineTemplate( $ref, $network, $pt_type, $colour );
    }
    elsif ( $ref ) {
        $ref_text = $ref;
    }

    $csv_text .= sprintf( "%s: %s; ", ( $column_name{'Comment'}  ? $column_name{'Comment'}  : 'Comment' ),  $hash{'Comment'}  )  if ( $hash{'Comment'}  );
    $csv_text .= sprintf( "%s: %s; ", ( $column_name{'From'}     ? $column_name{'From'}     : 'From' ),     $hash{'From'}     )  if ( $hash{'From'}     );
    $csv_text .= sprintf( "%s: %s; ", ( $column_name{'To'}       ? $column_name{'To'}       : 'To' ),       $hash{'To'}       )  if ( $hash{'To'}       );
    $csv_text .= sprintf( "%s: %s; ", ( $column_name{'Operator'} ? $column_name{'Operator'} : 'Operator' ), $hash{'Operator'} )  if ( $hash{'Operator'} );
    $csv_text =~ s/; $//;

    if ( $no_of_columns > 1 && $ref && $ref_text ) {
        if ( $print_wiki ) {
            #
            # WIKI code
            #
            print  "|- bgcolor=\"#dfdfdf\"\n";
            printf "|| %s || colspan=\"%d\" align=\"right\"| %s\n", $ref_text, $no_of_columns-1, $csv_text;
        }
        else {
            #
            # HTML
            #
            printf "%16s<tr data-ref=\"%s\" class=\"sketchline\"><td class=\"sketch\">%s</td><td class=\"csvinfo\" colspan=\"%d\">%s</td></tr>\n", ' ', $ref, $ref_text, $no_of_columns-1, html_escape($csv_text);
        }
    }
}


#############################################################################################

sub printTableLine {
    my %hash    = ( @_ );
    my $val     = undef;
    my $i = 0;

    if ( $print_wiki ) {
        #
        # WIKI code
        #
        print  "|-\n|";
        for ( $i = 0; $i < $no_of_columns; $i++ ) {
            $val =  $hash{$columns[$i]} || '';
            $val =~ s/__separator__/<br>/g;
            if ( $columns[$i] eq "relation" ) {
                $val = printRelationTemplate( $val );
            }
            elsif ( $columns[$i] eq "ref" ) {
                $val =~ s/\s+/\&nbsp;/g;
            }
            elsif ( $columns[$i] eq "PTv" ) {
                $val = ' align="center" | ' . $val;
            }
            printf " %s %s", $val, ( $i < $no_of_columns-1 ? '||' : "\n" );
        }
    }
    else {
        #
        # HTML
        #
        my $ref = $hash{'ref'} || '???'; 
        printf  "%16s<tr data-ref=\"%s\" class=\"line\">", ' ', $ref;
        for ( $i = 0; $i < $no_of_columns; $i++ ) {
            $val =  $hash{$columns[$i]} || '';
            if ( $columns[$i] eq "relation" ) {
                printf "<td class=\"relation\">%s</td>", printRelationTemplate($val);
            }
            elsif ( $columns[$i] eq "relations"  ){
                my $and_more = '';
                if ( $val =~ m/ and more .../ ) {
                    $and_more = ' and more ...';
                    $val =~ s/ and more ...//;
                }
                printf "<td class=\"relations\">%s%s</td>", join( ', ', map { printRelationTemplate($_); } split( ',', $val ) ), $and_more;
            }
            elsif ( $columns[$i] eq "issues"  ){
                $val =~ s/__separator__/<br>/g;
                printf "<td class=\"%s\">%s</td>", $columns[$i], $val;
            }
            else {
                $val = html_escape($val);
                $val =~ s/__separator__/<br>/g;
                printf "<td class=\"%s\">%s</td>", $columns[$i], $val;
            }
        }
        printf "</tr>\n";
    }
}


#############################################################################################

sub printTableFooter {

    if ( $print_wiki ) {
        #
        # WIKI code
        #
        print "|}\n\n";
        printf STDERR "%s Templates printed: %d\n", get_time(), $number_of_printed_templates    if ( $verbose );
    }
    else {
        #
        # HTML
        #
        printf "%12s</tbody>\n",  ' ';
        printf "%8s</table>\n\n", ' ';
    }
}


#############################################################################################

sub printRelationTemplate {
    my $val = shift;
    
    if ( $val ) {
        if ( $print_wiki ) {
            #
            # WIKI code
            #
            if ( $number_of_printed_templates < $max_templates ) {
                $val = sprintf("{{Relation|%s}}", $val );
                $number_of_printed_templates++;
            }
            else
            {
                # some manual expansion of the template
                
                my $image_url       = sprintf( "[[Image:Osm_element_relation.svg|20px]]" );
                my $relation_url    = sprintf( "[http://osm.org/relation/%s %s]", $val, $val );
                my $xml_url         = sprintf( "[http://api.osm.org/api/0.6/relation/%s XML]", $val );
                my $id_url          = sprintf( "[http://osm.org/edit?editor=id&relation=%s iD]", $val );
                my $josm_url        = sprintf( "[http://localhost:8111/import?url=http://api.openstreetmap.org/api/0.6/relation/%s/full JOSM]", $val );
                my $potlatch2_url   = sprintf( "[http://osm.org/edit?editor=potlatch2&zoom=11&amp;relation=%s Potlatch2]", $val );
                my $history_url     = sprintf( "[http://osm.virtuelle-loipe.de/history/?type=relation&ref=%s history]", $val );
                my $analyze_url     = sprintf( "[http://ra.osmsurround.org/analyze.jsp?relationId=%s analyze]", $val );
                my $manage_url      = sprintf( "[http://osmrm.openstreetmap.de/relation.jsp?id=%s manage]", $val );
                my $gpx_url         = sprintf( "[http://ra.osmsurround.org/exportRelation/gpx?relationId=%s gpx]", $val );
    
                $val = sprintf( "%s %s <small>(%s, %s, %s, %s, %s, %s, %s, %s)</small>", $image_url, $relation_url, $xml_url, $id_url, $josm_url, $potlatch2_url, $history_url, $analyze_url, $manage_url, $gpx_url );    
            }
        }
        else {
            #
            # HTML
            #
            my $image_url       = sprintf( "<img src=\"http://wiki.openstreetmap.org/w/images/d/d9/Mf_Relation.svg\" title=\"Relation\" alt=\"Relation\" />" );
            my $relation_url    = sprintf( "<a href=\"http://osm.org/relation/%s\" title=\"Relation\">%s</a>", $val, $val );
#            my $xml_url         = sprintf( "<a href=\"http://api.osm.org/api/0.6/relation/%s\">XML</a>", $val );
            my $id_url          = sprintf( "<a href=\"http://osm.org/edit?editor=id&amp;relation=%s\">iD</a>", $val );
            my $josm_url        = sprintf( "<a href=\"http://localhost:8111/import?url=http://api.openstreetmap.org/api/0.6/relation/%s/full\">JOSM</a>", $val );
#            my $potlatch2_url   = sprintf( "<a href=\"http://osm.org/edit?editor=potlatch2&amp;zoom=11&amp;amp;relation=%s\">Potlatch2</a>", $val );
#            my $history_url     = sprintf( "<a href=\"http://osm.virtuelle-loipe.de/history/?type=relation&amp;ref=%s\">history</a>", $val );
#            my $analyze_url     = sprintf( "<a href=\"http://ra.osmsurround.org/analyze.jsp?relationId=%s\">analyze</a>", $val );
#            my $manage_url      = sprintf( "<a href=\"http://osmrm.openstreetmap.de/relation.jsp?id=%s\">manage</a>", $val );
#            my $gpx_url         = sprintf( "<a href=\"http://ra.osmsurround.org/exportRelation/gpx?relationId=%s\">gpx</a>", $val );

#            $val = sprintf( "%s %s <small>(%s, %s, %s, %s, %s, %s, %s, %s)</small>", $image_url, $relation_url, $xml_url, $id_url, $josm_url, $potlatch2_url, $history_url, $analyze_url, $manage_url, $gpx_url );    
            $val = sprintf( "%s %s <small>(%s, %s)</small>", $image_url, $relation_url, $id_url, $josm_url );    
        }
    }
    else {
        $val = '';
    }
    
    return $val;
}


#############################################################################################

sub printWayTemplate {
    my $val = shift;
    
    if ( $val ) {
        if ( $print_wiki ) {
            #
            # WIKI code
            #
            if ( 0 ) { # $number_of_printed_templates < $max_templates ) {
                $val = sprintf("{{Way|%s}}", $val );
                $number_of_printed_templates++;
            }
            else
            {
                # some manual expansion of the template
                
                my $image_url       = sprintf( "[[Image:Osm_element_way.svg|20px]]" );
                my $way_url         = sprintf( "[http://osm.org/way/%s %s]", $val, $val );
                my $xml_url         = sprintf( "[http://api.osm.org/api/0.6/way/%s XML]", $val );
                my $id_url          = sprintf( "[http://osm.org/edit?editor=id&way=%s iD]", $val );
                my $josm_url        = sprintf( "[http://localhost:8111/import?url=http://api.openstreetmap.org/api/0.6/way/%s/full JOSM]", $val );
                my $potlatch2_url   = sprintf( "[http://osm.org/edit?editor=potlatch2&zoom=11&amp;way=%s Potlatch2]", $val );
    
                $val = sprintf( "%s %s <small>(%s, %s, %s, %s)</small>", $image_url, $way_url, $xml_url, $id_url, $josm_url, $potlatch2_url );    
            }
        }
        else {
            #
            # HTML
            #
            my $image_url       = sprintf( "<img src=\"http://wiki.openstreetmap.org/w/images/2/2a/Mf_way.svg\" title=\"Way\" alt=\"Way\" />" );
            my $way_url         = sprintf( "<a href=\"http://osm.org/way/%s\" title=\"Way\">%s</a>", $val, $val );
#            my $xml_url         = sprintf( "<a href=\"http://api.osm.org/api/0.6/way/%s\">XML</a>", $val );
            my $id_url          = sprintf( "<a href=\"http://osm.org/edit?editor=id&amp;way=%s\">iD</a>", $val );
            my $josm_url        = sprintf( "<a href=\"http://localhost:8111/import?url=http://api.openstreetmap.org/api/0.6/way/%s/full\">JOSM</a>", $val );
#            my $potlatch2_url   = sprintf( "<a href=\"http://osm.org/edit?editor=potlatch2&amp;zoom=11&amp;amp;way=%s\">Potlatch2</a>", $val );

#            $val = sprintf( "%s %s <small>(%s, %s, %s, %s)</small>", $image_url, $way_url, $xml_url, $id_url, $josm_url, $potlatch2_url );    
            $val = sprintf( "%s %s <small>(%s, %s)</small>", $image_url, $way_url, $id_url, $josm_url );    
        }
    }
    else {
        $val = '';
    }
    
    return $val;
}


#############################################################################################

sub printNodeTemplate {
    my $val = shift;
    
    if ( $val ) {
        if ( $print_wiki ) {
            #
            # WIKI code
            #
            if ( 0 ) { # $number_of_printed_templates < $max_templates ) {
                $val = sprintf("{{Node|%s}}", $val );
                $number_of_printed_templates++;
            }
            else
            {
                # some manual expansion of the template
                
                my $image_url       = sprintf( "[[Image:Osm_element_node.svg|20px]]" );
                my $node_url        = sprintf( "[http://osm.org/node/%s %s]", $val, $val );
                my $xml_url         = sprintf( "[http://api.osm.org/api/0.6/node/%s XML]", $val );
                my $id_url          = sprintf( "[http://osm.org/edit?editor=id&node=%s iD]", $val );
                my $josm_url        = sprintf( "[http://localhost:8111/import?url=http://api.openstreetmap.org/api/0.6/node/%s JOSM]", $val );
                my $potlatch2_url   = sprintf( "[http://osm.org/edit?editor=potlatch2&zoom=11&amp;node=%s Potlatch2]", $val );
    
                $val = sprintf( "%s %s <small>(%s, %s, %s, %s)</small>", $image_url, $node_url, $xml_url, $id_url, $josm_url, $potlatch2_url );    
            }
        }
        else {
            #
            # HTML
            #
            my $image_url       = sprintf( "<img src=\"http://wiki.openstreetmap.org/w/images/2/20/Mf_node.svg\" title=\"Node\" alt=\"Node\" />" );
            my $node_url        = sprintf( "<a href=\"http://osm.org/node/%s\" title=\"Node\">%s</a>", $val, $val );
#            my $xml_url         = sprintf( "<a href=\"http://api.osm.org/api/0.6/node/%s\">XML</a>", $val );
            my $id_url          = sprintf( "<a href=\"http://osm.org/edit?editor=id&amp;node=%s\">iD</a>", $val );
            my $josm_url        = sprintf( "<a href=\"http://localhost:8111/import?url=http://api.openstreetmap.org/api/0.6/node/%s\">JOSM</a>", $val );
#            my $potlatch2_url   = sprintf( "<a href=\"http://osm.org/edit?editor=potlatch2&amp;zoom=11&amp;amp;node=%s\">Potlatch2</a>", $val );

#            $val = sprintf( "%s %s <small>(%s, %s, %s, %s)</small>", $image_url, $node_url, $xml_url, $id_url, $josm_url, $potlatch2_url );    
            $val = sprintf( "%s %s <small>(%s, %s)</small>", $image_url, $node_url, $id_url, $josm_url );    
        }
    }
    else {
        $val = '';
    }
    
    return $val;
}


#############################################################################################

sub printSketchLineTemplate {
    my $ref           = shift;
    my $network       = shift;
    my $pt_type       = shift || '';
    my $colour        = shift || '';
    my $text          = undef;
    my $ref_escaped   = $ref;
    my $colour_string = '';
    my $pt_string     = '';
    my $bg_colour     = GetColourFromString( $colour );
    my $fg_colour     = GetForeGroundFromBackGround( $bg_colour );
    
    if ( $print_wiki ) {
        #
        # WIKI code
        #
        if ( $number_of_printed_templates < $max_templates ) {
            #printf STDERR "printSketchLineTemplate: ref=%s, network=%s, pt_type=%s, colour=%s\n", $ref, $network, $pt_type, $colour;
            if ( $bg_colour && $fg_colour && $coloured_sketchline ) {
                $colour_string = '|bg=' . $bg_colour . '|fg='. $fg_colour;
                $pt_string     = '|r=1'                                 if ( $pt_type eq 'train' || $pt_type eq 'light_rail'     );
                #printf STDERR "printSketchLineTemplate: ref=%s, network=%s, pt_string=%s, colour_string=%s\n", $ref, $network, $pt_string, $colour_string;
            }
            $text = sprintf( "'''{{Sketch Line|%s|%s|wuppertal%s%s}}'''", $ref, $network, $colour_string, $pt_string );
            $number_of_printed_templates++;
        }
        else {
            #printf STDERR "printSketchLineTemplate: ref=%s, network=%s, pt_type=%s, colour=%s\n", $ref, $network, $pt_type, $colour;
            if ( $bg_colour && $fg_colour && $coloured_sketchline ) {
                $colour_string = '&bg=' . $bg_colour . '&fg='. $fg_colour;
                $pt_string     = '&r=1'                                 if ( $pt_type eq 'train' || $pt_type eq 'light_rail'     );
                #printf STDERR "printSketchLineTemplate: ref=%s, network=%s, pt_string=%s, colour_string=%s\n", $ref, $network, $pt_string, $colour_string;
            }
            $ref_escaped    =~ s/ /+/g;
            $network        =~ s/ /+/g;
            $text           = sprintf( "'''[https://overpass-api.de/api/sketch-line?ref=%s&network=%s&style=wuppertal%s%s %s]'''", $ref_escaped, $network, $colour_string, $pt_string, $ref ); # some manual expansion of the template
        }
    }
    else {
        my $span_begin    = '';
        my $span_end      = '';
        #
        # HTML
        #
        if ( $bg_colour && $fg_colour && $coloured_sketchline ) {
            $colour_string = "\&amp;bg=" . $bg_colour . "\&amp;fg=". $fg_colour;
            $pt_string     = "\&amp;r=1"                                        if ( $pt_type eq 'train' || $pt_type eq 'light_rail'     );
            $span_begin    = sprintf( "<span style=\"color:%s;background-color:%s;\">&nbsp;", $fg_colour, $bg_colour );
            $span_end      = "&nbsp;</span>";
        }
        $ref_escaped    =~ s/ /+/g;
        $network        =~ s/ /+/g;
        $text           = sprintf( "<a href=\"https://overpass-api.de/api/sketch-line?ref=%s\&amp;network=%s\&amp;style=wuppertal%s%s\" title=\"Sketch-Line\">%s%s%s</a>", $ref_escaped, uri_escape($network), $colour_string, $pt_string, $span_begin, $ref, $span_end ); # some manual expansion of the template
    }
    
    return $text;
}


#############################################################################################

sub html_escape {
    my $text = shift;
    if ( $text ) {
        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
        $text =~ s/>/&gt;/g;
        $text =~ s/"/&quot;/g;
        $text =~ s/'/&#039;/g;
        $text =~ s/Ä/&Auml;/g;
        $text =~ s/ä/&auml;/g;
        $text =~ s/Ö/&Ouml;/g;
        $text =~ s/ö/&ouml;/g;
        $text =~ s/Ü/&Uuml;/g;
        $text =~ s/ü/&uuml;/g;
        $text =~ s/ß/&szlig;/g;
    }
    return $text;
}


#############################################################################################

sub uri_escape {
    my $text = shift;
    if ( $text ) {
    }
    return $text;
}


#############################################################################################

sub wiki2html {
    my $text = shift;
    my $sub  = undef;
    if ( $text ) {
        # ignore: [[Category:Nürnberg]]
        $text =~ s/\[\[[^:]+:[^\]]+\]\]//g;
        # convert: [[Nürnberg/Transportation/Analyse/DE-BY-VGN-Linien|VGN Linien]]
        while ( $text =~ m/\[\[([^|]+)\|([^\]]+)\]\]/g ) {
            $sub = sprintf( "<a href=\"https://wiki.openstreetmap.org/wiki/%s\">%s</a>", $1, $2 );
            $text =~ s/\[\[[^|]+\|[^\]]+\]\]/$sub/;
        }
        # convert: [[https://example.com/index.html External Link]]
        while ( $text =~ m/\[([^ ]+) ([^\]]+)\]/g ) {
            $sub = sprintf( "<a href=\"https://wiki.openstreetmap.org/wiki/%s\">%s</a>", $1, $2 );
            $text =~ s/\[[^ ]+ [^\]]+\]/$sub/;
        }
        while ( $text =~ m/'''(.?)'''/g ) {
            $sub = sprintf( "<em>%s</em>", $1 );
        }
    }
    return $text;
}


#############################################################################################

sub GetColourFromString {

    my $string      = shift;
    my $ret_value   = undef;

    if ( $string ) {
        if ( $string =~ m/^#[A-Fa-f0-9]{6}$/ ) {
            $ret_value= uc($string);
        }
        elsif ( $string =~ m/^#([A-Fa-f0-9])([A-Fa-f0-9])([A-Fa-f0-9])$/ ) {
            $ret_value= uc("#" . $1 . $1 . $2 . $2 . $3 . $3);
        }
        else {
            $ret_value = ( $colour_table{$string} ) ? $colour_table{$string} : undef;
        }
    }
    return $ret_value;
}



#############################################################################################

sub GetForeGroundFromBackGround {
    
    my $bg_colour = shift;
    my $ret_value = undef;
    
    if ( $bg_colour ) {
        $bg_colour      =~ s/^#//;
        my$rgbval       = hex( $bg_colour );
        my $r           = $rgbval >> 16;
        my $g           = ($rgbval & 0x00FF00) >> 8;
        my $b           = $rgbval & 0xFF;
        my $brightness  = $r * 0.299 + $g * 0.587 + $b * 0.114;
        $ret_value      = ($brightness > 160) ? "#000" : "#fff";
    }
    return $ret_value;
}
    

#############################################################################################

sub get_time {
    
    my ($sec,$min,$hour,$day,$month,$year) = localtime();
    
    return sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $month+1, $day, $hour, $min, $sec ); 
}
   



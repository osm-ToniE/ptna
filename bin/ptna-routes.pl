#!/usr/bin/perl

use warnings;
use strict;

BEGIN { my $PATH = $0; $PATH =~ s|bin/[^/]*$|modules|; unshift( @INC, $PATH ); }

####################################################################################################################
#
#
#
####################################################################################################################

use POSIX;

use utf8;
binmode STDIN,  ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Locale::gettext;

use Getopt::Long;
use OSM::XML        qw( parse );
use OSM::Data       qw( %META %NODES %WAYS %RELATIONS );
use RoutesList;
use Data::Dumper;
use Encode;

my @supported_route_types                   = ( 'train', 'subway', 'light_rail', 'tram', 'trolleybus', 'bus', 'ferry', 'monorail', 'aerialway', 'funicular', 'share_taxi' );
my @well_known_other_route_types            = ( 'bicycle', 'mtb', 'hiking', 'road', 'foot', 'inline_skates', 'canoe', 'detour', 'fitness_trail', 'horse', 'motorboat', 'nordic_walking', 'pipeline', 'piste', 'power', 'running', 'ski', 'snowmobile', 'cycling' , 'historic', 'motorcycle', 'riding' );
my @well_known_network_types                = ( 'international', 'national', 'regional', 'local', 'icn', 'ncn', 'rcn', 'lcn', 'iwn', 'nwn', 'rwn', 'lwn', 'road' );
my @well_known_other_types                  = ( 'restriction', 'enforcement', 'destination_sign' );
my %have_seen_well_known_other_route_types  = ();
my %have_seen_well_known_network_types      = ();
my %have_seen_well_known_other_types        = ();

my $opt_language                    = undef;
my $verbose                         = undef;
my $debug                           = undef;
my $osm_xml_file                    = undef;
my $routes_file                     = undef;
my $relaxed_begin_end_for           = undef;
my $network_guid                    = undef;
my $network_long_regex              = undef;
my $network_short_regex             = undef;
my $operator_regex                  = undef;
my $allow_coach                     = undef;
my $check_access                    = undef;
my $check_bus_stop                  = undef;
my $check_name                      = undef;
my $check_name_relaxed              = undef;
my $check_stop_position             = undef;
my $check_osm_separator             = undef;
my $check_platform                  = undef;
my $check_sequence                  = undef;
my $check_roundabouts               = undef;
my $check_route_ref                 = undef;
my $check_motorway_link             = undef;
my $check_version                   = undef;
my $expect_network_long             = undef;
my $expect_network_long_as          = undef;
my $expect_network_long_for         = undef;
my $expect_network_short            = undef;
my $expect_network_short_as         = undef;
my $expect_network_short_for        = undef;
my $multiple_ref_type_entries       = "analyze";
my $ptv1_compatibility              = "no";
my $strict_network                  = undef;
my $strict_operator                 = undef;
my $max_error                       = undef;
my $help                            = undef;
my $man_page                        = undef;
my $positive_notes                  = undef;
my $csv_separator                   = ';';
my $or_separator                    = '|';                 # must be different from $csv_operator: used to separate several 'ref' values in CSV entry "43|E43;bus;;;;"
my $ref_separator                   = '/';                 # must be different from $csv_operator: used to separate several 'ref' values in CSV entry "602/50;bus;;;;"
my $coloured_sketchline             = undef;
my $page_title                      = undef;


GetOptions( 'help'                          =>  \$help,                         # -h or --help                      help
            'man'                           =>  \$man_page,                     # --man                             manual pages
            'language=s'                    =>  \$opt_language,                 # --language=de                     I18N
            'verbose'                       =>  \$verbose,                      # --verbose
            'debug'                         =>  \$debug,                        # --debug
            'allow-coach'                   =>  \$allow_coach,                  # --allow-coach                     allow 'coach' als valid routetype
            'check-access'                  =>  \$check_access,                 # --check-access                    check for access restrictions on highways
            'check-bus-stop'                =>  \$check_bus_stop,               # --check-bus-stop                  check for strict highway=bus_stop on nodes only
            'check-motorway-link'           =>  \$check_motorway_link,          # --check-motorway-link             check for motorway_link followed/preceeded by motorway or trunk
            'check-name'                    =>  \$check_name,                   # --check-name                      check for strict name conventions (name='... ref: from => to'
            'check-name-relaxed'            =>  \$check_name_relaxed,           # --check-name-relaxed              check for relaxed name conventions (name='... ref: from => to'
            'check-osm-separator'           =>  \$check_osm_separator,          # --check-osm-separator             check separator for '; ' (w/ blank) and ',' (comma instead of semi-colon)
            'check-platform'                =>  \$check_platform,               # --check-platform                  check for bus=yes, tram=yes, ... on platforms
            'check-roundabouts'             =>  \$check_roundabouts,            # --check-roundabouts               check for roundabouts being included completely
            'check-route-ref'               =>  \$check_route_ref,              # --check-route-ref                 check 'route_ref' tag on highway=bus_stop and public_transport=platform
            'check-sequence'                =>  \$check_sequence,               # --check-sequence                  check for correct sequence of stops, platforms and ways
            'check-stop-position'           =>  \$check_stop_position,          # --check-stop-position             check for bus=yes, tram=yes, ... on (stop_positions
            'check-version'                 =>  \$check_version,                # --check-version                   check for PTv2 on route_masters, ...
            'coloured-sketchline'           =>  \$coloured_sketchline,          # --coloured-sketchline             force SketchLine to print coloured icons
            'expect-network-long'           =>  \$expect_network_long,          # --expect-network-long             note if 'network' is not long form in general
            'expect-network-long-as:s'      =>  \$expect_network_long_as,       # --expect-network-long-as="Münchner Verkehrs- und Tarifverbund|Biberger Bürgerbus"
            'expect-network-long-for:s'     =>  \$expect_network_long_for,      # --expect-network-long-for="MVV|BBB"         note if 'network' is not long form for ...
            'expect-network-short'          =>  \$expect_network_short,         # --expect-network-short            note if 'network' is not short form in general
            'expect-network-short-as:s'     =>  \$expect_network_short_as,      # --expect-network-short-as='BOB'
            'expect-network-short-for:s'    =>  \$expect_network_short_for,     # --expect-network-short-for='Bayerische Oberlandbahn'        note if 'network' is not short form for ...
            'routes-file=s'                 =>  \$routes_file,                  # --routes-file=zzz                 CSV file with a list of routes of the of the network
            'max-error=i'                   =>  \$max_error,                    # --max-error=10                    limit number of templates printed for identical error messages
            'multiple-ref-type-entries=s'   =>  \$multiple_ref_type_entries,    # --multiple-ref-type-entries=analyze|allow    how to handle multiple "ref;type" in routes-file
            'network-guid=s'                =>  \$network_guid,                 # --network-guid='DE-BY-MVV'
            'network-long-regex:s'          =>  \$network_long_regex,           # --network-long-regex='Münchner Verkehrs- und Tarifverbund|Grünwald|Bayerische Oberlandbahn'
            'network-short-regex:s'         =>  \$network_short_regex,          # --network-short-regex='MVV|BOB'
            'operator-regex:s'              =>  \$operator_regex,               # --operator-regex='MVG|Münchner'
            'positive-notes'                =>  \$positive_notes,               # --positive-notes                  print positive information for notes, if e.g. something is fulfilled
            'ptv1-compatibility=s'          =>  \$ptv1_compatibility,           # --ptv1-compatibility=no|show|allow    how to handle "highway=bus_stop" in PTv2
            'relaxed-begin-end-for:s'       =>  \$relaxed_begin_end_for,        # --relaxed-begin-end-for=...       for train/tram/light_rail: first/last stop position does not have to be on first/last node of way, but within first/last way
            'osm-xml-file=s'                =>  \$osm_xml_file,                 # --osm-xml-file=yyy                XML output of Overpass APU query
            'separator=s'                   =>  \$csv_separator,                # --separator=';'                   separator in the CSV file
            'or-separator=s'                =>  \$or_separator,                 # --or-separator='|'                separator in the CSV file inside 'ref' values to allow multiple values
            'ref-separator=s'               =>  \$ref_separator,                # --ref-separator='/'               separator in the CSV file inside 'ref' values to show cooperations
            'strict-network'                =>  \$strict_network,               # --strict-network                  do not consider empty network tags
            'strict-operator'               =>  \$strict_operator,              # --strict-operator                 do not consider empty operator tags
            'title=s'                       =>  \$page_title,                   # --title=...                       Title for the HTML page
          );

$page_title                 = decode('utf8', $page_title )                  if ( $page_title                );
$network_guid               = decode('utf8', $network_guid )                if ( $network_guid              );
$network_long_regex         = decode('utf8', $network_long_regex )          if ( $network_long_regex        );
$network_short_regex        = decode('utf8', $network_short_regex )         if ( $network_short_regex       );
$operator_regex             = decode('utf8', $operator_regex )              if ( $operator_regex            );
$expect_network_long_as     = decode('utf8', $expect_network_long_as )      if ( $expect_network_long_as    );
$expect_network_long_for    = decode('utf8', $expect_network_long_for )     if ( $expect_network_long_for   );
$expect_network_short_as    = decode('utf8', $expect_network_short_as )     if ( $expect_network_short_as   );
$expect_network_short_for   = decode('utf8', $expect_network_short_for )    if ( $expect_network_short_for  );

if ( $verbose ) {
    printf STDERR "%s ptna-routes.pl -v\n", get_time();
    printf STDERR "%20s--language='%s'\n",                 ' ', $opt_language                  if ( $opt_language                );
    printf STDERR "%20s--title='%s'\n",                    ' ', $page_title                    if ( $page_title                  );
    printf STDERR "%20s--network-guid='%s'\n",             ' ', $network_guid                  if ( $network_guid                );
    printf STDERR "%20s--allow-coach\n",                   ' '                                 if ( $allow_coach                 );
    printf STDERR "%20s--check-access\n",                  ' '                                 if ( $check_access                );
    printf STDERR "%20s--check-bus-stop\n",                ' '                                 if ( $check_bus_stop              );
    printf STDERR "%20s--check-motorway-link\n",           ' '                                 if ( $check_motorway_link         );
    printf STDERR "%20s--check-name\n",                    ' '                                 if ( $check_name                  );
    printf STDERR "%20s--check-name-relaxed\n",            ' '                                 if ( $check_name_relaxed          );
    printf STDERR "%20s--check-osm-separator\n",           ' '                                 if ( $check_osm_separator         );
    printf STDERR "%20s--check-platform\n",                ' '                                 if ( $check_platform              );
    printf STDERR "%20s--check-roundabouts\n",             ' '                                 if ( $check_roundabouts           );
    printf STDERR "%20s--check-route-ref\n",               ' '                                 if ( $check_route_ref             );
    printf STDERR "%20s--check-sequence\n",                ' '                                 if ( $check_sequence              );
    printf STDERR "%20s--check-stop-position\n",           ' '                                 if ( $check_stop_position         );
    printf STDERR "%20s--check-version\n",                 ' '                                 if ( $check_version               );
    printf STDERR "%20s--coloured-sketchline\n",           ' '                                 if ( $coloured_sketchline         );
    printf STDERR "%20s--expect-network-long\n",           ' '                                 if ( $expect_network_long         );
    printf STDERR "%20s--expect-network-short\n",          ' '                                 if ( $expect_network_short        );
    printf STDERR "%20s--positive-notes\n",                ' '                                 if ( $positive_notes              );
    printf STDERR "%20s--strict-network\n",                ' '                                 if ( $strict_network              );
    printf STDERR "%20s--strict-operator\n",               ' '                                 if ( $strict_operator             );
    printf STDERR "%20s--network-long-regex='%s'\n",       ' ', $network_long_regex            if ( $network_long_regex          );
    printf STDERR "%20s--network-short-regex='%s'\n",      ' ', $network_short_regex           if ( $network_short_regex         );
    printf STDERR "%20s--operator-regex='%s'\n",           ' ', $operator_regex                if ( $operator_regex              );
    printf STDERR "%20s--expect-network-long-as='%s'\n",   ' ', $expect_network_long_as        if ( $expect_network_long_as      );
    printf STDERR "%20s--expect-network-long-for='%s'\n",  ' ', $expect_network_long_for       if ( $expect_network_long_for     );
    printf STDERR "%20s--expect-network-short-as='%s'\n",  ' ', $expect_network_short_as       if ( $expect_network_short_as     );
    printf STDERR "%20s--expect-network-short-for='%s'\n", ' ', $expect_network_short_for      if ( $expect_network_short_for    );
    printf STDERR "%20s--multiple-ref-type-entries='%s'\n",' ', $multiple_ref_type_entries     if ( $multiple_ref_type_entries   );
    printf STDERR "%20s--ptv1-compatibility='%s'\n",       ' ', $ptv1_compatibility            if ( $ptv1_compatibility          );
    printf STDERR "%20s--max-error='%s'\n",                ' ', $max_error                     if ( $max_error                   );
    printf STDERR "%20s--relaxed-begin-end-for='%s'\n",    ' ', $relaxed_begin_end_for         if ( $relaxed_begin_end_for       );
    printf STDERR "%20s--separator='%s'\n",                ' ', $csv_separator                 if ( $csv_separator               );
    printf STDERR "%20s--or-separator='%s'\n",             ' ', $or_separator                  if ( $or_separator                );
    printf STDERR "%20s--ref-separator='%s'\n",            ' ', $ref_separator                 if ( $ref_separator               );
    printf STDERR "%20s--routes-file='%s'\n",              ' ', decode('utf8', $routes_file )  if ( $routes_file                 );
    printf STDERR "%20s--osm-xml-file='%s'\n",             ' ', decode('utf8', $osm_xml_file ) if ( $osm_xml_file                );
}



if ( $opt_language ) {
    setlocale( LC_ALL, "" );
    $ENV{'LANG'}     = $opt_language;
    $ENV{'LANGUAGE'} = $opt_language;
    my $PATH = $0;
    $PATH =~ s|bin/[^/]*$|locale|; 
    bindtextdomain( 'ptna', $PATH );
    textdomain( "ptna" );
}    

if ( $check_name_relaxed ) {
    $check_name = 1;
}

if ( $csv_separator ) {
    if ( length($csv_separator) > 1 ) {
        printf STDERR "%s analyze-routes.pl: wrong value for option: '--separator' = '%s' - setting it to '--separator' = ';'\n", get_time(), $csv_separator;
        $csv_separator = ';'
    }
    $csv_separator = '\\' . $csv_separator;
}

if ( $or_separator ) {
    if ( length($or_separator) > 1 ) {
        printf STDERR "%s analyze-routes.pl: wrong value for option: '--or-separator' = '%s' - setting it to '--or-separator' = '|'\n", get_time(), $or_separator;
        $or_separator = '|';
    }
    $or_separator = '\\' . $or_separator;
}

if ( $ref_separator ) {
    if ( length($ref_separator) > 1 ) {
        printf STDERR "%s analyze-routes.pl: wrong value for option: '--ref-separator' = '%s' - setting it to '--ref-separator' = '/'\n", get_time(), $ref_separator;
        $or_separator = '|';
    }
    $ref_separator = '\\' . $ref_separator;
}

if ( $allow_coach ) {
    push( @supported_route_types, 'coach' );
}

if ( $multiple_ref_type_entries ne 'analyze' && $multiple_ref_type_entries ne 'allow' ) {
    printf STDERR "%s analyze-routes.pl: wrong value for option: '--multiple_ref_type_entries' = '%s' - setting it to '--multiple_ref_type_entries' = 'analyze'\n", get_time(), $multiple_ref_type_entries;
    $multiple_ref_type_entries = 'analyze';
}

if ( $ptv1_compatibility ne 'no' && $ptv1_compatibility ne 'allow' && $ptv1_compatibility ne 'show' ) {
    printf STDERR "%s analyze-routes.pl: wrong value for option: '--ptv1_compatibility' = '%s' - setting it to '--ptv1_compatibility' = 'no'\n", get_time(), $ptv1_compatibility;
    $ptv1_compatibility = 'no';
}

my $xml_has_meta            = 0;        # does the XML file include META information?
my $xml_has_relations       = 0;        # does the XML file include any relations? If not, we will exit
my $xml_has_ways            = 0;        # does the XML file include any ways, then we can make a big analysis
my $xml_has_nodes           = 0;        # does the XML file include any nodes, then we can make a big analysis

my %PT_relations_with_ref   = ();       # includes "positive" (the ones we are looking for) as well as "negative" (the other ones) route/route_master relations and "skip"ed relations (where 'network' or 'operator' does not fit)
my %PT_relations_without_ref= ();       # includes any route/route_master relations without 'ref' tag
my %PL_MP_relations         = ();       # includes type=multipolygon, public_transport=platform  multipolygone relations
my %suspicious_relations    = ();       # strange relations with suspicious tags, a simple list of Relation-IDs, more details can befound with $RELATIONS{rel-id}
my %route_ways              = ();       # all ways  of the XML file that build the route : equals to %WAYS - %platform_ways
my %platform_ways           = ();       # all ways  of the XML file that are platforms (tag: public_transport=platform)
my %platform_nodes          = ();       # all nodes of the XML file that are platforms (tag: public_transport=platform)
my %stop_nodes              = ();       # all nodes of the XML file that are stops (tag: public_transport=stop_position)
my %used_networks           = ();       # 'network' values that did match
my %unused_networks         = ();       # 'network' values that did not match
my %unused_operators        = ();       # 'operator' values that did not match but 'network' values did match


my $relation_ptr            = undef;    # a pointer in Perl to a relation structure
my $relation_id             = undef;    # the OSM ID of a relation
my $way_id                  = undef;    # the OSM ID of a way
my $node_id                 = undef;    # the OSM ID of a node
my $tag                     = undef;
my $ref                     = undef;    # the value of "ref" tag of an OSM object (usually the "ref" tag of a route relation
my $route_type              = undef;    # the value of "route_master" or "route" of a relation
my $operator                = undef;    # the value of "operator" of relation or in CSV file
my $member                  = undef;
my $node                    = undef;
my $entry                   = undef;
my $type                    = undef;
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

my @HTML_start                      = ();
my @HTML_main                       = ();

my %column_name             = ( 'ref'           => gettext('Line (ref=)'),
                                'relation'      => gettext('Relation (id=)'),
                                'relations'     => gettext('Relations'),                 # comma separated list of relation-IDs
                                'name'          => gettext('Name (name=)'),
                                'number'        => gettext('Number'),
                                'network'       => gettext('Network (network=)'),
                                'operator'      => gettext('Operator (operator=)'),
                                'from'          => gettext('From (from=)'),
                                'via'           => gettext('Via (via=)'),
                                'to'            => gettext('To (to=)'),
                                'issues'        => gettext('Errors'),
                                'notes'         => gettext('Notes'),
                                'type'          => gettext('Type (type=)'),
                                'route_type'    => gettext('Vehicle (route(_master)=)'),
                                'PTv'           => gettext('PTv'),
                                'Comment'       => gettext('Comment'),
                                'From'          => gettext('From'),
                                'To'            => gettext('To'),
                                'Operator'      => gettext('Operator'),
                              );

my %transport_types         = ( 'bus'           => gettext('Bus'),
                                'coach'         => gettext('Coach'),
                                'share_taxi'    => gettext('Share-Taxi'),
                                'train'         => gettext('Train/Suburban-Train'),
                                'tram'          => gettext('Tram/Streetcar'),
                                'subway'        => gettext('Subway/Underground'),
                                'light_rail'    => gettext('Light-Rail'),
                                'trolleybus'    => gettext('Trolley Bus'),
                                'ferry'         => gettext('Ferry'),
                                'monorail'      => gettext('Mono-Rail'),
                                'aerialway'     => gettext('Aerialway'),
                                'funicular'     => gettext('Funicular')
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
                                'white'         => '#ffffff',
                                'silver'        => '#c0c0c0',
                                'red'           => '#ff0000',
                                'yellow'        => '#ffff00',
                                'lime'          => '#00ff00',
                                'aqua'          => '#00ffff',
                                'cyan'          => '#00ffff',
                                'blue'          => '#0000ff',
                                'fuchsia'       => '#ff00ff',
                                'magenta'       => '#ff00ff',
                              );


#############################################################################################
#
# read the file which contains the lines of interest, CSV style file, first column corresponds to "ref", those are the "refs of interest"
#
#############################################################################################

if ( $routes_file ) {
    
    printf STDERR "%s Reading %s\n", get_time(), decode('utf8', $routes_file )                  if ( $verbose );
    
    my $ReadError = RoutesList::ReadRoutes( 'file'                   => $routes_file, 
                                            'analyze'                => $multiple_ref_type_entries, 
                                            'csv-separator'          => $csv_separator,
                                            'or-separator'           => $or_separator,
                                            'supported_route_types'  => \@supported_route_types,
                                            'verbose'                => $verbose, 
                                            'debug'                  => $debug
                                          );
    
    if ( $ReadError ) {
        printf STDERR "%s %s\n", get_time(), $ReadError;
    } else {
        printf STDERR "%s %s read\n", get_time(), decode('utf8', $routes_file )                 if ( $verbose );
    }
}


#############################################################################################
# 
# secondly read the XML file with the OSM information (might take a while)
#
#############################################################################################

if ( $osm_xml_file ) {

    printf STDERR "%s Reading %s\n", get_time(), decode('utf8', $osm_xml_file )                                         if ( $verbose );

    my $ret = parse( 'data' => $osm_xml_file, 'debug' => $debug, 'verbose' => $verbose );
    
    if ( $ret ) {
        printf STDERR "%s %s read\n", get_time(), decode('utf8', $osm_xml_file )                                        if ( $verbose );
        $xml_has_meta       = 1  if ( scalar(keys(%META)) );
        $xml_has_relations  = 1  if ( scalar(keys(%RELATIONS)) );
        $xml_has_ways       = 1  if ( scalar(keys(%WAYS))      );
        $xml_has_nodes      = 1  if ( scalar(keys(%NODES))     );
    } else {
        printf STDERR "%s %s read failed with return code %s\n", get_time(), decode('utf8', $osm_xml_file ), $ret       if ( $verbose );
    }
}

if ( $xml_has_relations == 0 ) {
    printf STDERR "No relations found in XML file %s - exiting\n", decode('utf8', $osm_xml_file );
    
    exit 1;
}


#############################################################################################
#
# now analyze the XML data
#
# 1. the meta informatio of the data: when has this been extracted from the DB
#
#############################################################################################

if ( $xml_has_meta ) {
    if ( $META{'osm_base'} ) {
        $osm_base = $META{'osm_base'};
    }
    if ( $META{'areas'} ) {
        $areas = $META{'areas'};
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
my $number_of_positive_relations        = 0;
my $number_of_unassigned_relations      = 0;
my $number_of_negative_relations        = 0;
my $number_of_suspicious_relations      = 0;
my $number_of_relations_without_ref     = 0;
my $number_of_ways                      = 0;
my $number_of_routeways                 = 0;
my $number_of_platformways              = 0;
my $number_of_nodes                     = 0;
my $number_of_platformnodes             = 0;
my $number_of_stop_positions            = 0;
my $number_of_used_networks             = 0;
my $number_of_unused_networks           = 0;

#
# there are relations, so lets convert them
#

printf STDERR "%s Converting relations\n", get_time()       if ( $verbose );

foreach $relation_id ( keys ( %RELATIONS ) ) {
    
    $number_of_relations++;
    
    $ref        = $RELATIONS{$relation_id}->{'tag'}->{'ref'};
    $type       = $RELATIONS{$relation_id}->{'tag'}->{'type'};

    if ( $type ) {
        #
        # first analyze route_master and route relations
        #
        if ( $type eq 'route_master' || $type eq 'route' ) {
    
            $route_type = $RELATIONS{$relation_id}->{'tag'}->{$RELATIONS{$relation_id}->{'tag'}->{'type'}};
    
            if ( $route_type ) {    
            
                $number_of_route_relations++;
        
                $relation_ptr = undef;
                
                if ( $ref ) {
                    $status = 'keep';
            
                    # match_route_type() returns either "keep" or "suspicious" or "skip"
                    # is this route_type of general interest? 'hiking', 'bicycle', ... routes are not of interest here
                    # "keep"        route_type matches exactly the supported route types            m/^'type'$/
                    # "suspicious"  route_type does not exactly match the supported route types     m/'type'/               (typo, ...?)
                    # "other"       route_type is not a well known route  type                      "coach", ...
                    # "well_known"  route_type is a well known route type                           "bicycle", "mtb", "hiking", "road", ...
                    #
                    if ( $status =~ m/keep/ ) { $status = match_route_type( $route_type ); }
                    printf STDERR "%-15s: ref=%s\ttype=%s\troute_type=%s\tRelation: %d\n", $status, $ref, $type, $route_type, $relation_id   if ( $debug );
                    
                    # match_network() returns either "keep long" or "keep short" or "skip"
                    #
                    if ( $status =~ m/keep/ ) { $status = match_network(  $RELATIONS{$relation_id}->{'tag'}->{'network'} ); }
                    
                    if ( $status =~ m/keep/ ) {
                        # match_operator() returns either "keep" or "skip"
                        #
                        $status = match_operator( $RELATIONS{$relation_id}->{'tag'}->{'operator'} );
                                
                        if ( $status =~ m/keep/ ) {
                            if ( $RELATIONS{$relation_id}->{'tag'}->{'network'} ) {
                                $used_networks{$RELATIONS{$relation_id}->{'tag'}->{'network'}}->{$relation_id} = 1;
                            }
                            else {
                                $used_networks{'__unset_network__'}->{$relation_id} = 1;
                            }
                        } else {
                            if ( $RELATIONS{$relation_id}->{'tag'}->{'operator'} ) {
                                $unused_operators{$RELATIONS{$relation_id}->{'tag'}->{'operator'}}{$relation_id} = 1;
                            }
                            else {
                                $unused_operators{'__unset_operator__'}->{$relation_id} = 1;
                            }
                        }
                    } elsif ( $status ne 'well_known' ) {
                        if ( $RELATIONS{$relation_id}->{'tag'}->{'network'} ) {
                            $unused_networks{$RELATIONS{$relation_id}->{'tag'}->{'network'}}{$relation_id} = 1;
                        }
                        else {
                            $unused_networks{'__unset_network__'}->{$relation_id} = 1;
                        }
                    }
                    
                    # match_ref_and_pt_type() returns "keep positive", "keep negative", "skip"
                    # "keep positive"   if $ref and $type match the %ref_type_of_interest (list of lines from CSV file)
                    # "keep negative"   if $ref and $type do not match
                    # "skip"            if $ref and $type are not set
                    #
                    if ( $status =~ m/keep/ ) { $status = match_ref_and_pt_type( $ref, $route_type ); }
                                
                    printf STDERR "%-15s: ref=%s\ttype=%s\troute_type=%s\tnetwork=%s\toperator=%s\tRelation: %d\n", $status, $ref, $type, $route_type, $RELATIONS{$relation_id}->{'tag'}->{'network'}, $RELATIONS{$relation_id}->{'tag'}->{'operator'}, $relation_id   if ( $debug );
                    
                    $section = undef;
                    if ( $status =~ m/(positive|negative|skip|other|suspicious|well_known)/ ) {
                        $section= $1;
                    }
                    
                    if ( $section ) {
                        if ( $section eq 'positive' || $section eq 'negative' ) {
                            my $ue_ref = $ref;
                            $PT_relations_with_ref{$section}->{$ue_ref}->{$type}->{$route_type}->{$relation_id} = $RELATIONS{$relation_id};
                            $relation_ptr = $RELATIONS{$relation_id};
                            $number_of_positive_relations++     if ( $section eq "positive"     );
                            $number_of_negative_relations++     if ( $section eq "negative"     );
                        } elsif ( $section eq 'other' || $section eq 'suspicious' ) {
                            $suspicious_relations{$relation_id} = 1;
                            $number_of_suspicious_relations++;
                        }
                    } elsif ( $verbose ) {
                        printf STDERR "%s Section mismatch 'status' = '%s'\n", get_time(), $status;
                    }
                } else {
                    $status = match_route_type( $route_type );
                    printf STDERR "%-15s: ref=undef\ttype=%s\troute_type=%s\tRelation: %d\n", $status, $type, $route_type, $relation_id   if ( $debug );
                    
                    if ( $status eq 'keep' || $status eq 'suspicious' ) {
                        # only supported route types or their typos must have 'ref' set
                        
                        $PT_relations_without_ref{$route_type}->{$relation_id} = $RELATIONS{$relation_id};
                        $relation_ptr = $RELATIONS{$relation_id};
                        $number_of_relations_without_ref++;
    
                        # match_network() returns either "keep long" or "keep short" or "skip"
                        #
                        my $status = match_network( $RELATIONS{$relation_id}->{'tag'}->{'network'} );
                        if ( $status =~ m/keep/ ) {
                            # match_operator() returns either "keep" or "skip"
                            #
                            $status = match_operator( $RELATIONS{$relation_id}->{'tag'}->{'operator'} );
                                    
                            if ( $status =~ m/keep/ ) {
                                if ( $RELATIONS{$relation_id}->{'tag'}->{'network'} ) {
                                    $used_networks{$RELATIONS{$relation_id}->{'tag'}->{'network'}}->{$relation_id} = 1;
                                }
                                else {
                                    $used_networks{'__unset_network__'}->{$relation_id} = 1;
                                }
                            } else {
                                if ( $RELATIONS{$relation_id}->{'tag'}->{'operator'} ) {
                                    $unused_operators{$RELATIONS{$relation_id}->{'tag'}->{'operator'}}{$relation_id} = 1;
                                }
                                else {
                                    $unused_operators{'__unset_operator__'}->{$relation_id} = 1;
                                }
                            }
                        } else {
                            if ( $RELATIONS{$relation_id}->{'tag'}->{'network'} ) {
                                $unused_networks{$RELATIONS{$relation_id}->{'tag'}->{'network'}}->{$relation_id} = 1;
                            } else {
                                $unused_networks{'__unset_network__'}->{$relation_id} = 1;
                            }
                        }
                        if ( $status eq 'suspicious' ) {
                            $suspicious_relations{$relation_id} = 1;
                            $number_of_suspicious_relations++;
                        }
                    } else {
                        if ( $status eq 'other' ) {
                            # at least all others (except well_known) shall also be reported as 'suspicious'
                            $suspicious_relations{$relation_id} = 1;
                            $number_of_suspicious_relations++;
                        }
                    }
                }
                
                if ( $relation_ptr ) {
        
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
                    $relation_ptr->{'__sort_name__'} = $relation_id     unless ( $relation_ptr->{'__sort_name__'} );        # will be set to "rel_ID_of_route_master - member_index"  for route relations having a parent route_master
                    $relation_ptr->{'__printed__'}   = 0;
                    $relation_index                  = 0;   # counts the number of members which are relations (any relation: 'route' or with 'role' = 'platform', ...
                    $route_master_relation_index     = 0;   # counts the number of relation members in a 'route_master' which do not have 'role' ~ 'platform' (should be equal to $relation_index')
                    $route_relation_index            = 0;   # counts the number of relation members in a 'route' which do not have 'role' ~ 'platform' (should be zero)
                    $way_index                       = 0;   # counts the number of all way members
                    $route_highway_index             = 0;   # counts the number of ways members in a route which do not have 'role' ~ 'platform', i.e. those ways a bus really uses
                    $node_index                      = 0;   # counts the number of node members
                    $role_platform_index             = 0;   # counts the number of members which have 'role' '^platform.*'
                    $role_stop_index                 = 0;   # counts the number of members which have 'role' '^stop.*'
                    foreach $member ( @{$relation_ptr->{'members'}} ) {
                        if ( $member->{'type'} ) {
                            if ( $member->{'type'} eq 'relation' ) {
                                ${$relation_ptr->{'relation'}}[$relation_index]->{'ref'}  = $member->{'ref'};
                                ${$relation_ptr->{'relation'}}[$relation_index]->{'role'} = $member->{'role'};
                                $relation_index++;
                                if ( $type             eq 'route_master'     &&
                                     $member->{'role'} !~ m/^platform/    ) {
                                    ${$relation_ptr->{'route_master_relation'}}[$route_master_relation_index]->{'ref'}  = $member->{'ref'};
                                    ${$relation_ptr->{'route_master_relation'}}[$route_master_relation_index]->{'role'} = $member->{'role'};
                                    $route_master_relation_index++;
                                    $RELATIONS{$member->{'ref'}}->{'member_of_route_master'}->{$relation_id} = 1;
                                    $RELATIONS{$member->{'ref'}}->{'__sort_name__'}                         = sprintf( "%s - %04d", $relation_id, $route_master_relation_index );
                                    printf STDERR "Relation %s: member of %s has index %d --> __sort_name__ = %s\n", $member->{'ref'}, $relation_id, $route_master_relation_index, $RELATIONS{$member->{'ref'}}->{'__sort_name__'}    if ( $debug );
                                } elsif ( $type        eq 'route'     &&
                                    $member->{'role'} !~ m/^platform/    ) {
                                    ${$relation_ptr->{'route_relation'}}[$route_relation_index]->{'ref'}  = $member->{'ref'};
                                    ${$relation_ptr->{'route_relation'}}[$route_relation_index]->{'role'} = $member->{'role'};
                                    $route_relation_index++;
                                }
                            } elsif ( $member->{'type'} eq 'way' ) {
                                ${$relation_ptr->{'way'}}[$way_index]->{'ref'}  = $member->{'ref'};
                                ${$relation_ptr->{'way'}}[$way_index]->{'role'} = $member->{'role'};
                                $way_index++;
                                if ( $type             eq 'route'     &&
                                     $member->{'role'} !~ m/^platform/    ) {
                                    ${$relation_ptr->{'route_highway'}}[$route_highway_index]->{'ref'}  = $member->{'ref'};
                                    ${$relation_ptr->{'route_highway'}}[$route_highway_index]->{'role'} = $member->{'role'};
                                    $route_highway_index++;
                                }
                            } elsif ( $member->{'type'} eq 'node' ) {
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
                                } elsif ( $member->{'role'} =~ m/^stop/ ) {
                                    ${$relation_ptr->{'role_stop'}}[$role_stop_index]->{'type'} = $member->{'type'};
                                    ${$relation_ptr->{'role_stop'}}[$role_stop_index]->{'ref'}  = $member->{'ref'};
                                    ${$relation_ptr->{'role_stop'}}[$role_stop_index]->{'role'} = $member->{'role'};
                                    $role_stop_index++;
                                }
                            }
                        }
                    }
                } elsif ( $verbose ) {
                    ; #printf STDERR "%s relation_ptr not set for relation id %s\n", get_time(), $relation_id;
                }
            } else {
                #printf STDERR "%s Suspicious: unset '%s' for relation id %s\n", get_time(), $type, $relation_id;
                $suspicious_relations{$relation_id} = 1;
                $number_of_suspicious_relations++;
            }
        } elsif ( $type eq 'multipolygon' ){
            #
            # analyze multipolygon relations
            #
            if ( $RELATIONS{$relation_id}->{'tag'}->{'public_transport'}               &&
                 $RELATIONS{$relation_id}->{'tag'}->{'public_transport'} eq 'platform'    ) {
                $PL_MP_relations{$relation_id} = $RELATIONS{$relation_id};
                $number_of_pl_mp_relations++;
            } else {
                #printf STDERR "%s Suspicious: wrong type=multipolygon (not public_transport=platform) for relation id %s\n", get_time(), $relation_id;
                $suspicious_relations{$relation_id} = 1;
                $number_of_suspicious_relations++;
            }
        } elsif ($type eq 'public_transport' ) {
            #
            # analyze public_transport relations (stop_area, stop_area_group), not of interest though for the moment
            #
            if ( $RELATIONS{$relation_id}->{'tag'}->{'public_transport'}                  &&
                 $RELATIONS{$relation_id}->{'tag'}->{'public_transport'} =~ m/^stop_area/    ) {
                ;
            } else {
                #printf STDERR "%s Suspicious: wrong type=public_transport (not public_transport=stop_area) for relation id %s\n", get_time(), $relation_id;
                $suspicious_relations{$relation_id} = 1;
                $number_of_suspicious_relations++;
            }
        } elsif ($type eq 'network' ) {
            #
            # collect network relations (collection of public_transport relations), not of interest though for the moment and against the rule (relations are not categories)
            #
            my $well_known = undef;
            if ( $RELATIONS{$relation_id}->{'tag'}->{'network'} ) {
                my $network = $RELATIONS{$relation_id}->{'tag'}->{'network'};
                foreach my $nt ( @well_known_network_types )
                {
                    if ( $network eq $nt ) {
                        printf STDERR "%s Skipping well known network type: %s\n", get_time(), $network       if ( $debug );
                        $have_seen_well_known_network_types{$network} = 1;
                        $well_known = $network;
                        last;
                    }
                }
            }
            if ( !defined($well_known) ) {
                $suspicious_relations{$relation_id} = 1;
                $number_of_suspicious_relations++;
            }
        } else {
            #printf STDERR "%s Suspicious: unhandled type '%s' for relation id %s\n", get_time(), $type, $relation_id;
            my $well_known = undef;
            foreach my $ot ( @well_known_other_types )
            {
                if ( $type eq $ot ) {
                    printf STDERR "%s Skipping well known other type: %s\n", get_time(), $type       if ( $debug );
                    $have_seen_well_known_other_types{$type} = 1;
                    $well_known = $type;
                    last;
                }
            }
            if ( !defined($well_known) ) {
                $suspicious_relations{$relation_id} = 1;
                $number_of_suspicious_relations++;
            }
        }
    } else {
        #printf STDERR "%s Suspicious: unset 'type' for relation id %s\n", get_time(), $relation_id;
        $suspicious_relations{$relation_id} = 1;
        $number_of_suspicious_relations++;
    }
}   

if ( $verbose ) {
    printf STDERR "%s Relations converted: %d, route_relations: %d, platform_mp_relations: %d, positive: %d, unassigned: %d, negative: %d, w/o ref: %d, suspicious: %d\n", 
                   get_time(),             
                   $number_of_relations, 
                   $number_of_route_relations,
                   $number_of_pl_mp_relations,
                   $number_of_positive_relations,
                   $number_of_unassigned_relations,
                   $number_of_negative_relations,
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
    
    foreach $way_id ( keys ( %WAYS ) ) {
        
        $number_of_ways++;
        
        $WAYS{$way_id}->{'first_node'} = ${$WAYS{$way_id}->{'chain'}}[0];
        $WAYS{$way_id}->{'last_node'}  = ${$WAYS{$way_id}->{'chain'}}[$#{$WAYS{$way_id}->{'chain'}}];
        
        #
        # lets categorize the way as member or route or platform or ...
        #
        if ( $WAYS{$way_id}->{'tag'}->{'public_transport'}               && 
             $WAYS{$way_id}->{'tag'}->{'public_transport'} eq 'platform'    ) {
            $platform_ways{$way_id} = $WAYS{$way_id};
            $number_of_platformways++;
            $platform_ways{$way_id}->{'is_area'}   = 1 if ( $platform_ways{$way_id}->{'tag'}->{'area'} && $platform_ways{$way_id}->{'tag'}->{'area'} eq 'yes' );
            #printf STDERR "WAYS{%s} is a platform\n", $way_id;
        } else { #if ( ($WAYS{$way_id}->{'tag'}->{'highway'}                && 
               #  $WAYS{$way_id}->{'tag'}->{'highway'} ne 'platform')                               ||
               # ($WAYS{$way_id}->{'tag'}->{'railway'}                && 
               #  $WAYS{$way_id}->{'tag'}->{'railway'} =~ m/^rail|tram|subway|construction|razed$/) ||
               # ($WAYS{$way_id}->{'tag'}->{'route'}                  && 
               #  $WAYS{$way_id}->{'tag'}->{'route'} =~ m/^ferry$/)                                     ) {
            $route_ways{$way_id} = $WAYS{$way_id};
            $number_of_routeways++;
            $WAYS{$way_id}->{'is_roundabout'}   = 1   if ( $WAYS{$way_id}->{'first_node'} == $WAYS{$way_id}->{'last_node'} );
            #printf STDERR "WAYS{%s} is a highway\n", $way_id;
        } #else {
        #    printf STDERR "Unmatched way type for way: %s\n", $way_id;
        #}
        
        map { $NODES{$_}->{'member_of_way'}->{$way_id} = 1; } @{$WAYS{$way_id}->{'chain'}};
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
    
    foreach $node_id ( keys ( %NODES ) ) {
        
        $number_of_nodes++;
        
        #
        # lets categorize the node as stop_position or platform or ...
        #
        if ( $NODES{$node_id}->{'tag'}->{'public_transport'}                    && 
             $NODES{$node_id}->{'tag'}->{'public_transport'} eq 'platform'    ) {
            $platform_nodes{$node_id} = $NODES{$node_id};
            $number_of_platformnodes++;
        } elsif ( $NODES{$node_id}->{'tag'}->{'public_transport'}                    && 
                $NODES{$node_id}->{'tag'}->{'public_transport'} eq 'stop_position'    ) {
            $stop_nodes{$node_id} = $NODES{$node_id};
            $number_of_stop_positions++;
        } else {
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
    my @list_of_matching_relation_ids   = ();
    my $number_of_matching_entries      = 0;

    printTableInitialization( 'name', 'type', 'relation', 'PTv', 'issues', 'notes' );
    
    foreach my $entryref ( RoutesList::GetRoutesList() ) {

        #printf STDERR "Entry: type = %s\n", $entryref->{'type'};
        
        if ( $entryref->{'type'} eq 'header' ) {
            printf STDERR "    header = %s\n", $entryref->{'header'}  if ( $debug );
            printTableFooter()                                          if ( $table_headers_printed ); 
            $table_headers_printed = 0;
            printHeader( $entryref->{'header'}, $entryref->{'level'} );
        } elsif ( $entryref->{'type'} eq 'text' ) {
            printf STDERR "    text = %s\n", $entryref->{'text'}  if ( $debug );
            printTableFooter()                                          if ( $table_headers_printed ); 
            $table_headers_printed = 0;
            printText( $entryref->{'text'} );
        } elsif ( $entryref->{'type'} eq 'error' ) {
            printf STDERR "    error = %s\n", $entryref->{'error'}  if ( $debug );
            if ( $table_headers_printed == 0 ) {
                printTableHeader();
                $table_headers_printed++;
            }
            printTableSubHeader( 'ref' => $entryref->{'ref'} );
            printTableLine( 'issues' => $entryref->{'error'} );
        } elsif ( $entryref->{'type'} eq 'route' ) {
            
            printf STDERR "    ref = %s, ref-or-list = '%s', ref-and-list = '%s', route = %s, comment = %s, from = %s, to = %s, operator = %s\n", $entryref->{'ref'}, join( ', ', @{$entryref->{'ref-or-list'}} ), join( ', ', @{$entryref->{'ref-and-list'}} ), $entryref->{'route'}, $entryref->{'comment'}, $entryref->{'from'}, $entryref->{'to'}, $entryref->{'operator'}  if ( $debug );

            if ( $table_headers_printed == 0 ) {
                printTableHeader();
                $table_headers_printed++;
            }
            
            @list_of_matching_relation_ids = search_matching_relations( 'ref'           =>  $entryref->{'ref'},
                                                                        'ref-or-list'   =>  $entryref->{'ref-or-list'},
                                                                        'ref-and-list'  =>  $entryref->{'ref-and-list'},
                                                                        'route_type'    =>  $entryref->{'route'},
                                                                        'section'       =>  $section,
                                                                        'operator'      =>  $entryref->{'operator'},
                                                                        'from'          =>  $entryref->{'from'},
                                                                        'from-list'     =>  $entryref->{'from-list'},
                                                                        'to'            =>  $entryref->{'to'},
                                                                        'to-list'       =>  $entryref->{'to-list'},
                                                                      );

            $number_of_matching_entries = scalar @list_of_matching_relation_ids;

            if ( $number_of_matching_entries ) {

                for ( my $i=0; $i < $number_of_matching_entries; $i++ ) {
                    $relation_id  = $list_of_matching_relation_ids[$i];
                    $relation_ptr = $RELATIONS{$relation_id};

                    printf STDERR "%s Found: Relation-ID %s, Type: %s, Ref: %s, RouteType: %s\n", get_time(), $relation_id, $RELATIONS{$relation_id}->{'tag'}->{'type'}, $RELATIONS{$relation_id}->{'tag'}->{'ref'}, $RELATIONS{$relation_id}->{'tag'}->{$RELATIONS{$relation_id}->{'tag'}->{'type'}}    if ( $debug );

                    if ( $i == 0 ) {
                        printTableSubHeader( 'ref-or-list'   => $entryref->{'ref-or-list'},                 # is a pointer to an array: ('23') or also ('43', 'E43') for multiple 'ref' values
                                             'network'       => $relation_ptr->{'tag'}->{'network'},     # take 'network' value from first relation, undef outside this for-loop
                                             'pt_type'       => $entryref->{'route'},
                                             'colour'        => $relation_ptr->{'tag'}->{'colour'},      # take 'colour' value from first relation, undef outside this for-loop
                                             'Comment'       => $entryref->{'comment'},
                                             'From'          => $entryref->{'from'},
                                             'From-List'     => $entryref->{'from-list'},
                                             'To'            => $entryref->{'to'},
                                             'To-List'       => $entryref->{'to-list'},
                                             'Operator'      => $entryref->{'operator'},
                                           );
                    }
                    
                    @{$relation_ptr->{'__issues__'}} = ();  # just in case that this route has already been analyzed before (--multiple-ref-type-enries=allow)
                    @{$relation_ptr->{'__notes__'}}  = ();  # just in case that this route has already been analyzed before (--multiple-ref-type-enries=allow)

                    $status = analyze_environment( \@list_of_matching_relation_ids, $entryref->{'ref-or-list'}, $relation_ptr->{'tag'}->{'type'}, $entryref->{'route'}, $relation_id );

                    $status = analyze_relation( $relation_ptr, $relation_id );
                    
                    printTableLine( 'ref'           =>    $relation_ptr->{'tag'}->{'ref'},
                                    'relation'      =>    $relation_id,
                                    'type'          =>    $relation_ptr->{'tag'}->{'type'},
                                    'route_type'    =>    $entryref->{'route'},
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
                    $relation_ptr->{'__printed__'}++;
                    $number_of_positive_relations++;
                }
            } else {
                #
                # we do not have a line which fits to the requested 'ref' and 'route_type' combination
                #
                printTableSubHeader( 'ref-or-list'   => $entryref->{'ref-or-list'},
                                     'Comment'       => $entryref->{'comment'},
                                     'From'          => $entryref->{'from'},
                                     'From-List'     => $entryref->{'from-list'},
                                     'To'            => $entryref->{'to'},
                                     'To-List'       => $entryref->{'to-list'},
                                     'Operator'      => $entryref->{'operator'},
                                   );
                if ( $entryref->{'ref-or-list'} ) {
                    printTableLine( 'issues' => sprintf(gettext("Missing route for ref='%s' and route='%s'"), join(gettext("' or ref='"),@{$entryref->{'ref-or-list'}}), $entryref->{'route'} ) );
                } else {
                    printTableLine( 'issues' => sprintf(gettext("Missing route for ref='%s' and route='%s'"), '???', $entryref->{'route'} ) );
                }
            }
        } else {
            printf STDERR "%s Internal error: ref and route_type not set in CSV file. %d\n", get_time(), $entryref->{'NR'};
        }
    }
    
    printTableFooter()  if ( $table_headers_printed ); 
    
    printFooter();

}

printf STDERR "%s Printed positives: %d\n", get_time(), $number_of_positive_relations       if ( $verbose );


#############################################################################################
#
# now we print the list of all unassigned relations/lines that could not be associated correctly (multiple entries for same ref/type values and ...)
#
#############################################################################################

printf STDERR "%s Printing unassigned\n", get_time()       if ( $verbose );
$number_of_unassigned_relations = 0;

if ( $routes_file ) {
    
    $section = 'positive';
    
    my @relation_ids = ();

    foreach $ref ( sort( keys( %{$PT_relations_with_ref{$section}} ) ) ) {
        foreach $type ( reverse ( sort( keys( %{$PT_relations_with_ref{$section}->{$ref}} ) ) ) ) {
            foreach $route_type ( sort( keys( %{$PT_relations_with_ref{$section}->{$ref}->{$type}} ) ) ) {
                foreach $relation_id ( sort( keys( %{$PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}} ) ) ) {
                    if ( $PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}->{$relation_id}->{'__printed__'} < 1 ) {
                        push( @relation_ids, $relation_id );
                    }
                }
            }
        }
    }
        
    if ( scalar(@relation_ids) ) {
    
        printTableInitialization( 'ref', 'relation', 'type', 'route_type', 'name', 'network', 'operator', 'from', 'via', 'to', 'PTv', 'issues', 'notes' );
    
        printHeader( gettext('Not clearly assigned routes'), 1, 'unassigned' );
        printHintUnassignedRelations();
        printTableHeader();
    
        foreach $relation_id ( @relation_ids ) {
            $relation_ptr = $RELATIONS{$relation_id};
    
            $status = analyze_relation( $relation_ptr, $relation_id );
                        
            printTableLine( 'ref'           =>    $relation_ptr->{'tag'}->{'ref'},
                            'relation'      =>    $relation_id,
                            'type'          =>    $relation_ptr->{'tag'}->{'type'},
                            'route_type'    =>    $relation_ptr->{'tag'}->{$relation_ptr->{'tag'}->{'type'}},
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
            $number_of_unassigned_relations++;
        }
    
        printTableFooter(); 
    
    }
}

printf STDERR "%s Printed unassigned: %d\n", get_time(), $number_of_unassigned_relations       if ( $verbose );

        
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
        printHeader( gettext('Other Public Transport Lines'), 1, 'otherlines' );
    } else {
        printHeader( gettext('Public Transport Lines'), 1, 'otherslines' );
    }


    foreach $route_type ( @supported_route_types ) {
        
        $route_type_lines = 0;
        foreach $ref ( @line_refs ) {
            foreach $type ( 'route_master', 'route' ) {
                $route_type_lines += scalar(keys(%{$PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}}));
            }
        }
        if ( $route_type_lines ) {
            $help = sprintf( "%s", ($transport_types{$route_type} ? $transport_types{$route_type} : $route_type) );
            printHeader( $help, 2 );
            printTableHeader();
            foreach $ref ( @line_refs ) {
                foreach $type ( 'route_master', 'route' ) {
                    foreach $relation_id ( sort( { $PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}->{$a}->{'__sort_name__'} cmp 
                                                   $PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}->{$b}->{'__sort_name__'}     } 
                                                 keys(%{$PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}})) ) {
                        $relation_ptr = $PT_relations_with_ref{$section}->{$ref}->{$type}->{$route_type}->{$relation_id};
    
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
    
    printHeader( gettext("Public Transport Lines without 'ref'"), 1, 'withoutref' );
    
    foreach $route_type ( @route_types ) {
        $help = sprintf( "%s", ($transport_types{$route_type} ? $transport_types{$route_type} : $route_type) );
        printHeader( $help, 2 );
        printTableHeader();
        foreach $relation_id ( sort( { $PT_relations_without_ref{$route_type}->{$a}->{'__sort_name__'} cmp 
                                       $PT_relations_without_ref{$route_type}->{$b}->{'__sort_name__'}     } 
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

    printHeader( gettext('More Relations'), 1, 'morerelations' );

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

printf STDERR "%s 'network' details\n", get_time()       if ( $verbose );

printHeader( gettext("Details for 'network'-Values"), 1, 'networkdetails' );

if ( $network_long_regex || $network_short_regex ) {
    printHintNetworks();
}

if ( keys( %used_networks ) ) {
    printHintUsedNetworks();
}

if ( keys( %unused_networks ) ) {
    printHintUnusedNetworks();
}

printf STDERR "%s Printed network details\n", get_time()       if ( $verbose );


#############################################################################################

printFinalFooter(); 

printf STDERR "%s Done ...\n", get_time()       if ( $verbose );


#############################################################################################

sub match_route_type {
    my $route_type = shift;
    my $rt         = undef;

    if ( $route_type ) {
        foreach my $rt ( @supported_route_types )
        {
            if ( $route_type eq $rt ) {
                printf STDERR "%s Keeping route type: %s\n", get_time(), $route_type       if ( $debug );
                return 'keep';
            } elsif ( $route_type =~ m/\Q$rt\E/ ) {
                printf STDERR "%s Suspicious route type: %s\n", get_time(), $route_type    if ( $debug );
                return 'suspicious';
            }
        }
        foreach my $rt ( @well_known_other_route_types )
        {
            if ( $route_type eq $rt ) {
                printf STDERR "%s Skipping well known other route type: %s\n", get_time(), $route_type       if ( $debug );
                $have_seen_well_known_other_route_types{$route_type} = 1;
                return 'well_known';
            }
        }
    }

    printf STDERR "%s Finally other route type: %s\n", get_time(), $route_type       if ( $debug );

    return 'other';
}


#############################################################################################

sub match_network {
    my $network = shift;

    if ( $network ) {
        if ( $network_long_regex || $network_short_regex ) {
            if ( $network_long_regex  && $network =~ m/$network_long_regex/ ) {
                return 'keep long';
            } elsif ( $network_short_regex && $network =~ m/$network_short_regex/ ) {
                return 'keep short';
            } else {
                printf STDERR "%s Skipping network: %s\n", get_time(), $network        if ( $debug );
                return 'skip';
            }
        }
    } else {
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
    } else {
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
        return 'keep positive'      if ( RoutesList::RefTypeCount( $ref, $pt_type ) );
    } else {
        printf STDERR "%s Skipping unset ref or unset type: %s/%s\n", get_time()        if ( $verbose );
        return 'skip';
    }
    printf STDERR "%s Keeping negative ref/type: %s/%s\n", get_time(), $ref, $pt_type   if ( $debug );
    return 'keep negative';
}


#############################################################################################

sub search_matching_relations {
    my %hash                        = ( @_ );
    my $ExpRef                      = $hash{'ref'};
    my $ExpRefOrList                = $hash{'ref-or-list'};
    my $ExpRefAndList               = $hash{'ref-and-list'};    # currently no used
    my $ExpRouteType                = $hash{'route_type'};
    my $section                     = $hash{'section'}      || 'positive';
    my $ExpOperator                 = $hash{'operator'}     || '';
    my $ExpFrom                     = $hash{'from'}         || '';
    my $ExpFromList                 = $hash{'from-list'};
    my $ExpTo                       = $hash{'to'}           || '';
    my $ExpToList                   = $hash{'to-list'};
    my $RelOperator                 = undef;
    my $RelFrom                     = undef;
    my $RelTo                       = undef;
    my $match                       = undef;

    my @route_master_list           = ();
    my @route_list                  = ();
    
    my %selected_route_masters      = ();
    my %selected_routes             = ();

    my $number_of_ref_type          = 1;
    my $number_of_ref_type_operator = 1;
    my $handle_multiple             = $multiple_ref_type_entries;
    
    my @ExpRefOrArray               = ();
    my @ExpRefAndArray              = ();    # currently no used
    my @ExpFromArray                = ();
    my @ExpToArray                  = ();
    
    if ( $ExpRefOrList ) {
        @ExpRefOrArray = @{$ExpRefOrList};
    } elsif ( $ExpRef ) {
        push( @ExpRefOrArray, $ExpRef );
    }
    if ( $ExpFromList ) {
        @ExpFromArray = @{$ExpFromList};
    } elsif ( $ExpFrom ) {
        push( @ExpFromArray, $ExpFrom );
    }
    if ( $ExpToList ) {
        @ExpToArray = @{$ExpToList};
    } elsif ( $ExpRef ) {
        push( @ExpToArray, $ExpTo );
    }
        
    if ( scalar @ExpRefOrArray && $ExpRouteType ) {

        foreach $ExpRef ( @ExpRefOrArray ) {
            $number_of_ref_type             = RoutesList::RefTypeCount( $ExpRef, $ExpRouteType );
            $number_of_ref_type_operator    = RoutesList::RefTypeOperatorCount( $ExpRef, $ExpRouteType, $ExpOperator );
        
            my $relations_for_this_route_type = scalar(keys(%{$PT_relations_with_ref{$section}->{$ExpRef}->{'route_master'}->{$ExpRouteType}})) + 
                                                scalar(keys(%{$PT_relations_with_ref{$section}->{$ExpRef}->{'route'}->{$ExpRouteType}}));
            if ( $relations_for_this_route_type ) {
                foreach my $type ( 'route', 'route_master' ) {
                    #
                    # check 'route' first 
                    # so that in case of a neded to check 'from' and 'to', 'route_master' can rely on 'route' information.
                    # i.e. if 'route' is selected, then it's 'route_master' also?
                    #
                    if ( $PT_relations_with_ref{$section}->{$ExpRef}->{$type} && $PT_relations_with_ref{$section}->{$ExpRef}->{$type}->{$ExpRouteType} ) {
                        foreach my $rel_id ( sort( { $PT_relations_with_ref{$section}->{$ExpRef}->{$type}->{$ExpRouteType}->{$a}->{'__sort_name__'} cmp 
                                                     $PT_relations_with_ref{$section}->{$ExpRef}->{$type}->{$ExpRouteType}->{$b}->{'__sort_name__'}     } 
                                                     keys(%{$PT_relations_with_ref{$section}->{$ExpRef}->{$type}->{$ExpRouteType}})) ) {
                            printf STDERR "Relation %s, __sort_name__ = %s\n", $rel_id, $RELATIONS{$rel_id}->{'__sort_name__'} if ( $debug );
                            if ( $number_of_ref_type > 1 && $handle_multiple eq 'analyze' ) {
                                #
                                # for this 'ref' and 'route_type' we have more than one entry in the CSV file
                                # i.e. there are doubled lines (example: DE-HB-VBN: bus routes 256, 261, 266, ... appear twice in different areas of the network)
                                # we should be able to distinguish them by their 'operator' values
                                # this requires the operator to be stated in the CSV file as Expected Operator and the tag 'operator' being set in the relation
                                #
                                $RelOperator = $RELATIONS{$rel_id}->{'tag'}->{'operator'} || '';
    
                                if ( $ExpOperator && $RelOperator ) {
                                    if ( $ExpOperator eq $RelOperator ) {
                                        if ( $number_of_ref_type_operator > 1 ) {
                                            printf STDERR "%s Checking %s relation %s, 'ref' %s and  'operator' %s, count %d\n", get_time(), $type, $rel_id, $ExpRef, $ExpOperator, $number_of_ref_type_operator     if ( $debug ); 
                                            
                                            #
                                            # check also from and to
                                            #
                                            $RelFrom = $RELATIONS{$rel_id}->{'tag'}->{'from'} || '';
                                            $RelTo   = $RELATIONS{$rel_id}->{'tag'}->{'to'}   || '';
                                            
                                            if ( ( scalar @ExpFromArray || scalar @ExpToArray ) &&
                                                 ( $RelFrom             || $RelTo )                ) {
                                                # minimum one of each pair must be defined
    
                                                $match = undef;
                                                foreach $ExpFrom ( @ExpFromArray ) {
                                                    if ( $ExpFrom ) {
                                                        if ( $RelFrom ) {
                                                            if ( $ExpFrom =~ m/\Q$RelFrom\E/ ) {
                                                                $match = "$ExpFrom =~ m/$RelFrom/";
                                                                last;
                                                            } elsif ( $RelFrom =~ m/\Q$ExpFrom\E/ ) {
                                                                $match = "$RelFrom =~ m/$ExpFrom/";
                                                                last;
                                                            }
                                                        }
                                                        if ( $RelTo ) {
                                                            if ( $ExpFrom =~ m/\Q$RelTo\E/ ) {
                                                                $match = "$ExpFrom =~ m/$RelTo/";
                                                                last;
                                                            } elsif ( $RelTo =~ m/\Q$ExpFrom\E/ ) {
                                                                $match = "$RelTo =~ m/$ExpFrom/";
                                                                last;
                                                            }
                                                        }
                                                    }
                                                }
                                                if ( !defined($match) ) {
                                                    foreach $ExpTo ( @ExpToArray ) {
                                                        if ( $ExpTo ) {
                                                            if ( $RelFrom ) {
                                                                if ( $ExpTo =~ m/\Q$RelFrom\E/ ) {
                                                                   $match = "$ExpTo =~ m/$RelFrom/";
                                                                   last;
                                                                } elsif ( $RelFrom =~ m/\Q$ExpTo\E/ ) {
                                                                   $match = "$RelFrom =~ m/$ExpTo/";
                                                                   last;
                                                                }
                                                            }
                                                            if ( $RelTo ) {
                                                                if ( $ExpTo =~ m/\Q$RelTo\E/ ) {
                                                                   $match = "$ExpTo =~ m/$RelTo/";
                                                                   last;
                                                                } elsif ( $RelTo =~ m/\Q$ExpTo\E/ ) {
                                                                   $match = "$RelTo =~ m/$ExpTo/";
                                                                   last;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                if ( $match ) {
                                                    printf STDERR "%s Selecting relation %s, 'ref' %s and  'operator' %s: match for From/To\n", get_time(), $rel_id, $ExpRef, $ExpOperator     if ( $debug ); 
                                                } else {
                                                    printf STDERR "%s Skipping relation %s, 'ref' %s and  'operator' %s: no match for From/To\n", get_time(), $rel_id, $ExpRef, $ExpOperator     if ( $debug ); 
                                                    next;
                                                }
                                            } else {
                                                $match = undef;
                                                if ( $type eq 'route_master' ) {
                                                    printf STDERR "%s Route-Master w/o values: %s\n", get_time(), $rel_id   if ( $debug ); 
                                                    # route_masters usually don't have 'from' or 'to' set: let's try something different
                                                    foreach my $member_rel_ref ( @{$RELATIONS{$rel_id}->{'route_master_relation'}} ) {
                                                        printf STDERR "%s Route-Master w/o values: %s - check Member %s\n", get_time(), $rel_id, $member_rel_ref->{'ref'}   if ( $debug ); 
                                                        if ( $selected_routes{$member_rel_ref->{'ref'}} ) {
                                                            # member route has been selected, from and/or to match, so let's assume, the route_aster matches as well
                                                            $match = $member_rel_ref->{'ref'};
                                                            last;
                                                        }
                                                    }
                                                }
                                                if ( $match ) {
                                                    printf STDERR "%s Selecting relation %s, 'ref' %s and  'operator' %s: match for From/To\n", get_time(), $rel_id, $ExpRef, $ExpOperator     if ( $debug ); 
                                                } else {
                                                    printf STDERR "%s Skipping relation %s, 'ref' %s and  'operator' %s: not enough values set for a comparison of From/To\n", get_time(), $rel_id, $ExpRef, $ExpOperator     if ( $debug ); 
                                                    next;
                                                }
                                            }
                                        }
                                    } else {
                                        printf STDERR "%s Skipping relation %s, 'ref' %s: 'operator' does not match expected operator (%s vs %s)\n", get_time(), $rel_id, $ExpRef, $RelOperator, $ExpOperator       if ( $debug ); 
                                        next;
                                    }
                                }
                                else {
                                    printf STDERR "%s Skipping relation %s, 'ref' %s: Relation: 'operator' = '%s', CSV file: 'operator' = '%s'\n", get_time(), $rel_id, $ExpRef, $RelOperator, $ExpOperator         if ( $debug );
                                    next;
                                }
                            } 
                            if ( $type eq 'route_master' ) {
                                push( @route_master_list, $rel_id )    unless ( $selected_route_masters{$rel_id} );
                                $selected_route_masters{$rel_id} = 1;
                            } else {
                                push( @route_list, $rel_id )    unless ( $selected_routes{$rel_id} );
                                $selected_routes{$rel_id} = 1;
                            }
                        }
                    }
                }
            }
        }
    }
    
    return ( @route_master_list, @route_list );
}


#############################################################################################

sub analyze_environment {
    my $matching_ref    = shift;
    my $ref_or_list     = shift;
    my $type            = shift;
    my $route_type      = shift;
    my $relation_id     = shift;
    my $return_code     = 0;
    
    my $relation_ptr    = undef;
    my $env_ref         = undef;
    my %environment     = ();
    my $temptype        = undef;
    my $temproutetype   = undef;
    
    
    if ( $matching_ref && $ref_or_list && $type && $route_type && $relation_id ) {
        
        foreach my $relid ( @{$matching_ref} ) {
            $temptype       = $RELATIONS{$relid}->{'tag'}->{'type'};
            $temproutetype  = $RELATIONS{$relid}->{'tag'}->{$temptype};
            $environment{'dummy'}->{$temptype}->{$temproutetype}->{$relid} = $RELATIONS{$relid};
        }
        $env_ref = $environment{'dummy'};
        
        $relation_ptr = $env_ref->{$type}->{$route_type}->{$relation_id};
        
        if ( $relation_ptr ) {

            if ( $type eq 'route_master' ) {
                $return_code = analyze_route_master_environment( $env_ref, $ref_or_list, $type, $route_type, $relation_id );
            } elsif ( $type eq 'route') {
                $return_code = analyze_route_environment( $env_ref, $ref_or_list, $type, $route_type, $relation_id );
            }
        }
    }

    return $return_code;
}


#############################################################################################

sub analyze_route_master_environment {
    my $env_ref         = shift;
    my $ref_or_list     = shift;
    my $type            = shift;
    my $route_type      = shift;
    my $relation_id     = shift;
    my $return_code     = 0;
    
    my $relation_ptr            = undef;
    my $number_of_route_masters = 0;
    my $number_of_routes        = 0;
    my $number_of_my_routes     = 0;
    my %my_routes               = ();
    my %allowed_refs            = ();
    my $masters_ref             = undef;
    my $members_ref             = undef;
    
    if ( $env_ref && $ref_or_list && $type && $type eq 'route_master' && $route_type && $relation_id ) {
        
        # do we have more than one route_master here for this "ref_or_list" and "route_type"?
        $number_of_route_masters    = scalar( keys( %{$env_ref->{'route_master'}->{$route_type}} ) );
        
        # how many routes do we have at all for this "ref_or_list" and "route_type"?
        $number_of_routes           = scalar( keys( %{$env_ref->{'route'}->{$route_type}} ) );

        # reference to this relation, the route_master under examination
        $relation_ptr               = $env_ref->{'route_master'}->{$route_type}->{$relation_id};
        
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
            foreach my $rel_id ( keys( %{$env_ref->{'route_master'}->{$route_type}} ) ) {
                $temp_relation_ptr = $env_ref->{'route_master'}->{$route_type}->{$rel_id};
                
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
                push( @{$relation_ptr->{'__issues__'}}, gettext('There is more than one Route-Master') );
            }
            if ( $number_of_my_routes > $number_of_routes ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route-Masters have more Routes than actually match (%d versus %d) in the given data set"), $number_of_my_routes, $number_of_routes) );
            } elsif ( $number_of_my_routes < $number_of_routes ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route-Masters have less Routes than actually match (%d versus %d) in the given data set"), $number_of_my_routes, $number_of_routes) );
            }
        } else {
            # how many routes are members of this route_master?
            $number_of_my_routes        = scalar( @{$relation_ptr->{'route_master_relation'}} );
        
            if ( $number_of_my_routes > $number_of_routes ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route-Master has more Routes than actually match (%d versus %d) in the given data set"), $number_of_my_routes, $number_of_routes) );
            } elsif ( $number_of_my_routes < $number_of_routes ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route-Master has less Routes than actually match (%d versus %d) in the given data set"), $number_of_my_routes, $number_of_routes) );
            }
        }
        
        # check whether all my member routes actually exist, tell us which one does not
        foreach my $member_ref ( @{$relation_ptr->{'route_master_relation'}} ) {
            $my_routes{$member_ref->{'ref'}} = 1;
            if ( !defined($env_ref->{'route'}->{$route_type}->{$member_ref->{'ref'}}) ) {
                #
                # relation_id points to a route which has different 'ref' or does not exist in data set
                #
                if ( $RELATIONS{$member_ref->{'ref'}} && $RELATIONS{$member_ref->{'ref'}}->{'tag'} ) {
                    #
                    # relation is included in XML input file cehck for settings
                    #
                    if ( $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'type'} ) {

                        if ( $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'type'} eq 'route' ) {

                            if ( $relation_ptr->{'tag'}->{'route_master'} && $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'route'} ) {

                                if ( $relation_ptr->{'tag'}->{'route_master'} eq $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'route'} ) {

                                    if ( $RELATIONS{$relation_id}->{'tag'}->{'ref'} ) {
                                        $masters_ref = $RELATIONS{$relation_id}->{'tag'}->{'ref'};
                                    }
                                    if ( $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'ref'} ) {
                                        foreach $members_ref ( @{$ref_or_list} ) {
                                            $allowed_refs{$members_ref} = 1;
                                        }
                                        $members_ref = $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'ref'};
                                        if ( $allowed_refs{$members_ref} ) {
                                            #
                                            # 'members_ref' is in the list, check for other problems
                                            #
                                            if ( $relation_ptr->{'tag'}->{'network'} && $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'} ) {
                                                if ( $relation_ptr->{'tag'}->{'network'} eq $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'} ) {
 #                                                    #printf STDERR "%s Route of Route-Master not found although 'ref' is valid and 'network' are equal. Route-Master: %s, Route: %s, 'ref': %s, 'network': %s\n", get_time(), $relation_id, $member_ref->{'ref'}, $members_ref, html_escape($relation_ptr->{'tag'}->{'network'});
                                                    if ( $relation_ptr->{'tag'}->{'operator'} && $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'operator'} ) {
                                                        if ( $relation_ptr->{'tag'}->{'operator'} eq $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'operator'} ) {
                                                            #printf STDERR "%s Route of Route-Master not found although 'ref' is valid and 'operator' are equal. Route-Master: %s, Route: %s, 'ref': %s, 'operator': %s\n", get_time(), $relation_id, $member_ref->{'ref'}, $members_ref, html_escape($relation_ptr->{'tag'}->{'operator'});
                                                            # 'ref' tag is valid (in the list) 'operator' is OK, any other reason
                                                             push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route might be listed with 'ref' = '%s' in a different section or in section 'Not clearly assigned routes' of this analysis: %s"), $members_ref, printRelationTemplate($member_ref->{'ref'}) ) );
                                                        } else {
                                                            # 'ref' tag is valid (in the list) but 'operator' is set and differs
                                                            push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route has different 'operator' = '%s' than Route-Master 'operator' = '%s': %s"), html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'operator'}), html_escape($relation_ptr->{'tag'}->{'operator'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                                        }
                                                    } elsif ( $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'operator'} ) {
                                                        # 'ref' tag is valid (in the list) but 'operator' is strange
                                                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route has 'operator' = '%s' value which is considered as not relevant: %s"), html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'operator'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                                    }
                                                } else {
                                                    # 'ref' tag is valid (in the list) but 'network' is set and differs
                                                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route has different 'network' = '%s' than Route-Master 'network' = '%s': %s"), html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'}), html_escape($relation_ptr->{'tag'}->{'network'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                                }
                                            } elsif ( $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'} ) {
                                                # 'ref' tag is valid (in the list) but 'network' is strange
                                                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route has 'network' = '%s' value which is considered as not relevant: %s"), html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                            }
                                           if ( $members_ref ne $masters_ref ) {
                                                # 'members_ref' is valid (in the list) but differs from 'ref' of route-master, so we have at least two refs in the list (a real list)
                                                push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("Route has different 'ref' = '%s' than Route-Master 'ref' = '%s' - this should be avoided: %s"), $members_ref, $masters_ref, printRelationTemplate($member_ref->{'ref'}) ) );
                                            }
                                        } else {
                                            # 'ref' tag is set but is not valid, not in list
                                            push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route has not matching 'ref' = '%s': %s"), $members_ref, printRelationTemplate($member_ref->{'ref'}) ) );
                                        }
                                    } else {
                                        # 'ref' tag is not set
                                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route exists in the given data set but 'ref' tag is not set: %s"), printRelationTemplate($member_ref->{'ref'}) ) );
                                    }
                                } else {
                                    # 'ref' tag is valid (in the list) but 'route' is set and differs from 'route_master'
                                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route has different 'route' = '%s' than Route-Master 'route_master' = '%s': %s"), html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'route'}), html_escape($relation_ptr->{'tag'}->{'route_master'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                }
                            } else {
                                if ( $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'route'} ) {
                                    # 'route' is strange
                                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route has 'route' = '%s' value which is considered as not relevant: %s"), html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'route'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                } else {
                                    # 'route' is not set
                                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route: 'route' tag is not set: %s"), printRelationTemplate($member_ref->{'ref'}) ) );
                                }
                            }
                        } else {
                            # 'type' is strange
                            push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route: 'type' = '%s' is not 'route': %s"), html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'type'}), printRelationTemplate($member_ref->{'ref'}) ) );
                        }
                    } else {
                        # 'type' is not set
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route: 'type' tag is not set: %s"), printRelationTemplate($member_ref->{'ref'}) ) );
                    }
                } else {
                    #
                    # relation is not included in XML input file
                    #
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route does not exist in the given data set: %s"), printRelationTemplate($member_ref->{'ref'}) ) );
                }
            }
        }
        # check whether all found relations are member of this/these route master(s), tell us which one is not
        foreach my $rel_id ( sort( keys( %{$env_ref->{'route'}->{$route_type}} ) ) ) {
            if ( !defined($my_routes{$rel_id}) ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route is not member of Route-Master: %s"), printRelationTemplate($rel_id) ) );
            }
        }
    }

    return $return_code;
}


#############################################################################################

sub analyze_route_environment {
    my $env_ref         = shift;
    my $ref_or_list     = shift;
    my $type            = shift;
    my $route_type      = shift;
    my $relation_id     = shift;
    my $return_code     = 0;
    
    my $relation_ptr                        = undef;
    my $number_of_direct_route_masters      = 0;
    my $number_of_route_masters             = 0;
    my $number_of_routes                    = 0;
    my %direct_and_matching_route_masters   = ();
    my %allowed_refs                        = ();
    my $masters_ref                         = undef;
    my $routes_ref                          = undef;
    
    if ( $env_ref && $ref_or_list && $type && $type eq 'route' && $route_type && $relation_id ) {
        
        $relation_ptr = $env_ref->{'route'}->{$route_type}->{$relation_id};
        
        #
        # 1. find all direct and matching route_masters here (also those where only 'ref' and 'route_type' match)
        #
        foreach my $direct_route_master_rel_id ( keys( %{$RELATIONS{$relation_id}->{'member_of_route_master'}}  ) ) {
            $direct_and_matching_route_masters{$direct_route_master_rel_id} = 1;
            $number_of_direct_route_masters++;
        }
        foreach my $indirect_route_master_rel_id ( keys( %{$env_ref->{'route_master'}->{$route_type}} ) ) {
            $direct_and_matching_route_masters{$indirect_route_master_rel_id} = 1;
        }
        $number_of_route_masters = scalar( keys ( %direct_and_matching_route_masters ) );

        if ( $number_of_route_masters > 1 && $number_of_direct_route_masters < $number_of_route_masters ) {
            # number_of_direct_route_masters < y : because number_of_direct_route_masters == number_of_route_masters will be checked some lines below if number_of_direct_route_masters > 1
            push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext('There is more than one Route-Master')) );
        }
        if ( $number_of_direct_route_masters > $number_of_route_masters ) {
            foreach my $direct_route_master_rel_id ( keys( %{$RELATIONS{$relation_id}->{'member_of_route_master'}}  ) ) {
                if ( !defined($env_ref->{'route_master'}->{$route_type}->{$direct_route_master_rel_id}) ) {
                    if ( $RELATIONS{$direct_route_master_rel_id} && $RELATIONS{$direct_route_master_rel_id}->{'tag'} && $RELATIONS{$direct_route_master_rel_id}->{'tag'}->{'ref'} ) {
                        $masters_ref = $RELATIONS{$direct_route_master_rel_id}->{'tag'}->{'ref'};
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route-Master might be listed with 'ref' = '%s' in a different section or in section 'Not clearly assigned routes' of this analysis: %s"), $masters_ref, printRelationTemplate($direct_route_master_rel_id) ) );
                    } else {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route-Master might be listed with unknown 'ref' in section 'Public Transport Lines without 'ref'' of this analysis: %s"), $masters_ref, printRelationTemplate($direct_route_master_rel_id) ) );
                    }
                }
            }
        }
        
        #
        # 2. check direct environment of this route: route_master(s) where this route is member of (independent of PTv2 or not)
        #

        $number_of_routes = scalar( keys( %{$env_ref->{'route'}->{$route_type}} ) );

        if ( $number_of_direct_route_masters > 1 ) {
            push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("This Route is direct member of more than one Route-Master: %s"), join(', ', map { printRelationTemplate($_); } sort( keys( %{$RELATIONS{$relation_id}->{'member_of_route_master'}} ) ) ) ) );
        } else {
            if ( $number_of_routes > 1 ) {
                if ( $number_of_route_masters == 0 ) {
                    push( @{$relation_ptr->{'__issues__'}}, gettext("Multiple Routes but no Route-Master") );
                } elsif ( $number_of_direct_route_masters == 0 ) {
                    push( @{$relation_ptr->{'__issues__'}}, gettext("Multiple Routes but this Route is not a member of any Route-Master") );
                }
            } else {
                # only one route but ... check if there is a route_master
                if ( $number_of_route_masters > 0 && $number_of_direct_route_masters == 0 ) {
                    # there is at least one route_master, but this route is not a member of any
                    push( @{$relation_ptr->{'__issues__'}}, gettext("This Route is not a member of any Route-Master") );
                }
            }
        }
        
        #
        # 3. check major tags of this route and the route_masters: they should match
        #

        foreach my $route_master_rel_id ( sort( keys( %direct_and_matching_route_masters ) ) ) {
            if ( $relation_ptr->{'tag'}->{'route'}   && $RELATIONS{$route_master_rel_id}->{'tag'}->{'route_master'} &&
                 $relation_ptr->{'tag'}->{'route'}   ne $RELATIONS{$route_master_rel_id}->{'tag'}->{'route_master'}     ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("'route' = '%s' of Route does not fit to 'route_master' = '%s' of Route-Master: %s"), $relation_ptr->{'tag'}->{'route'}, $RELATIONS{$route_master_rel_id}->{'tag'}->{'route_master'}, printRelationTemplate($route_master_rel_id)) );
            }
            if ( $RELATIONS{$route_master_rel_id}->{'tag'}->{'ref'} ) {
                foreach $masters_ref ( @{$ref_or_list} ) {
                    $allowed_refs{$masters_ref} = 1;
                }
                $masters_ref = $RELATIONS{$route_master_rel_id}->{'tag'}->{'ref'};
                if ( $allowed_refs{$masters_ref} ) {
                    $routes_ref = $relation_ptr->{'tag'}->{'ref'};
                    #
                    # 'masters_ref' is in the list, check for other problems
                    #
                    if ( $routes_ref && $routes_ref ne $masters_ref ) {
                        # 'masters_ref' is valid (in the list) but differs from 'ref' of route, so we have at least two refs in the list (a real list)
                        push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("Route has different 'ref' = '%s' than Route-Master 'ref' = '%s' - this should be avoided: %s"), $routes_ref, $masters_ref, printRelationTemplate($route_master_rel_id) ) );
                    }
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route-Master has not matching 'ref' = '%s': %s"), $masters_ref, printRelationTemplate($route_master_rel_id)) );
                }
            }
            if ( $relation_ptr->{'tag'}->{'network'} && $RELATIONS{$route_master_rel_id}->{'tag'}->{'network'} &&
                 $relation_ptr->{'tag'}->{'network'} ne $RELATIONS{$route_master_rel_id}->{'tag'}->{'network'}     ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("'network' = '%s' of Route does not fit to 'network' = '%s' of Route-Master: %s"), html_escape($relation_ptr->{'tag'}->{'network'}), html_escape($RELATIONS{$route_master_rel_id}->{'tag'}->{'network'}), printRelationTemplate($route_master_rel_id)) );
            }
#            if ( $relation_ptr->{'tag'}->{'operator'} && $RELATIONS{$route_master_rel_id}->{'tag'}->{'operator'} &&
#                 $relation_ptr->{'tag'}->{'operator'} ne $RELATIONS{$route_master_rel_id}->{'tag'}->{'operator'}     ) {
#                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("'operator' = '%s' of Route does not fit to 'operator' = '%s' of Route-Master: %s"), html_escape($relation_ptr->{'tag'}->{'operator'}), html_escape($RELATIONS{$route_master_rel_id}->{'tag'}->{'operator'}), printRelationTemplate($route_master_rel_id)) );
#            }
            if ( $relation_ptr->{'tag'}->{'colour'} ) {
                if ( $RELATIONS{$route_master_rel_id}->{'tag'}->{'colour'} ) {
                    if ( uc($relation_ptr->{'tag'}->{'colour'}) ne uc($RELATIONS{$route_master_rel_id}->{'tag'}->{'colour'}) ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("'colour' of Route does not fit to 'colour' of Route-Master: %s"), printRelationTemplate($route_master_rel_id)) );
                    }
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("'colour' of Route is set but 'colour' of Route-Master is not set: %s"), printRelationTemplate($route_master_rel_id)) );
                }
            } elsif ( $RELATIONS{$route_master_rel_id}->{'tag'}->{'colour'} ) {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("'colour' of Route is not set but 'colour' of Route-Master is set: %s"), printRelationTemplate($route_master_rel_id)) );
            }
        }

        if ( $number_of_routes > 1 ) {
            if ( !$relation_ptr->{'tag'}->{'public_transport:version'} || $relation_ptr->{'tag'}->{'public_transport:version'} !~ m/^2$/ ) {
                push( @{$relation_ptr->{'__issues__'}}, gettext("Multiple Routes but 'public_transport:version' is not set to '2'") );
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
    
    if ( $relation_ptr ) {
        
        $ref                            = $relation_ptr->{'tag'}->{'ref'};
        $type                           = $relation_ptr->{'tag'}->{'type'};
        $route_type                     = $relation_ptr->{'tag'}->{$type};

        #
        # now, check existing and defined tags and report them to front of list (ISSUES, NOTES)
        #
        
        foreach $specialtag ( @specialtags ) {
            foreach my $tag ( sort(keys(%{$relation_ptr->{'tag'}})) ) {
                if ( $tag =~ m/^\Q$specialtag\E/i ) {
                    if ( $relation_ptr->{'tag'}->{$tag} ) {
                        $reporttype = ( $specialtag2reporttype{$specialtag} ) ? $specialtag2reporttype{$specialtag} : '__notes__';
                        if ( $tag =~ m/^note$/i ){
                            $help =  $relation_ptr->{'tag'}->{$tag};
                            $help =~ s|^https{0,1}://wiki.openstreetmap.org\S+\s*[;,_+#\.\-]*\s*||;
                            unshift( @{$relation_ptr->{$reporttype}}, sprintf("'%s' ~ '%s'", $tag, html_escape($help)) )  if ( $help );
                        } else {
                            unshift( @{$relation_ptr->{$reporttype}}, sprintf("'%s' = '%s'", $tag, html_escape($relation_ptr->{'tag'}->{$tag})) )
                        }
                    }
                }
            }
        }

        #
        # now check existance of required/optional tags
        #
        
        push( @{$relation_ptr->{'__issues__'}}, gettext("'ref' is not set") )        unless ( $ref ); 
        
        push( @{$relation_ptr->{'__issues__'}}, gettext("'name' is not set") )       unless ( $relation_ptr->{'tag'}->{'name'} );

        $network = $relation_ptr->{'tag'}->{'network'};

        if ( $network ) {
            my $count_error_semikolon_w_blank = 0;
            my $count_error_comma             = 0;
            my $match                         = '';

            if ( $network_short_regex ) {
                foreach my $short_value ( split('\|',$network_short_regex) ) {
                    if ( $network =~ m/(\Q$short_value\E)/ ) {
                        $match = $1;
                        if ( $positive_notes ) {
                            if ( $network eq $match ) {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf("'network' = '%s'",html_escape($match)) );
                            } else {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf("'network' ~ '%s'",html_escape($match)) );
                            }
                        }
                        if ( $network =~ m/;\s+\Q$match\E/    ||
                             $network =~ m/\Q$match\E\s+;/    ||
                             $network =~ m/\Q$match\E\s*;\s+/   ) {
                            $count_error_semikolon_w_blank++;
                        }
                        if ( $network =~ m/(,\s*)\Q$match\E/    ||
                             $network =~ m/\Q$match\E(\s*,)/       ) {
                            $count_error_comma++;
                        }
                    }
                }
            }
            if ( $network_long_regex ) {
                foreach my $long_value ( split('\|',$network_long_regex) ) {
                    if ( $network =~ m/(\Q$long_value\E)/ ) {
                        $match = $1;
                        if ( $positive_notes ) {
                            if ( $network eq $match ) {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf("'network' = '%s'",html_escape($match)) );
                            } else {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf("'network' ~ '%s'",html_escape($match)) );
                            }
                        }
                        if ( $network =~ m/;\s+\Q$match\E/    ||
                             $network =~ m/\Q$match\E\s+;/    ||
                             $network =~ m/\Q$match\E\s*;\s+/   ) {
                            $count_error_semikolon_w_blank++;
                        }
                        if ( $network =~ m/(,\s*)\Q$match\E/    ||
                             $network =~ m/\Q$match\E(\s*,)/       ) {
                            $count_error_comma++;
                        }
                    }
                }
            }
            
            if ( $check_osm_separator ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("'network' = '%s' includes the separator value ';' (semi-colon) with sourrounding blank"), html_escape($network)) )                 if ( $count_error_semikolon_w_blank );
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("'network' = '%s': ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank"), html_escape($network)) )  if ( $count_error_comma             );
            }

            if ( $expect_network_short  ) {
                my $match_short     = '';
                my $match_long      = '';
                my $expect_long_as  = '';
                my $expect_long_for = '';
                
                $match_short     = $1   if ( $network_short_regex     && $network =~ m/($network_short_regex)/     );
                $match_long      = $1   if ( $network_long_regex      && $network =~ m/($network_long_regex)/      );
                $expect_long_as  = $1   if ( $expect_network_long_as  && $network =~ m/(\Q$expect_network_long_as\E)/  );
                $expect_long_for = $1   if ( $expect_network_long_for && $network =~ m/(\Q$expect_network_long_for\E)/ );
                
                if ( $match_long ) {
                    if ( $match_long ne $expect_long_as ) {
                        push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("'network' = '%s' should be short form"),html_escape($match_long)) );
                    }
                } elsif ( $match_short ) {
                    if ( $match_short eq $expect_long_for ) {
                        push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("'network' = '%s' should be long form"),html_escape($match_short)) );
                    }
                }
            } elsif ( $expect_network_long  ) {
                my $match_long       = '';
                my $match_short      = '';
                my $expect_short_as  = '';
                my $expect_short_for = '';
                
                $match_long       = $1   if ( $network_long_regex       && $network =~ m/($network_long_regex)/       );
                $match_short      = $1   if ( $network_short_regex      && $network =~ m/($network_short_regex)/      );
                $expect_short_as  = $1   if ( $expect_network_short_as  && $network =~ m/(\Q$expect_network_short_as\E)/  );
                $expect_short_for = $1   if ( $expect_network_short_for && $network =~ m/(\Q$expect_network_short_for\E)/ );
                
                if ( $match_short ) {
                    if ( $match_short ne $expect_short_as ) {
                        push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("'network' = '%s' should be long form"),html_escape($match_short)) );
                    }
                } elsif ( $match_long ) {
                    if ( $match_long eq $expect_short_for ) {
                        push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("'network' = '%s' should be short form"),html_escape($match_long)) );
                    }
                }
            }
        } else {
            push( @{$relation_ptr->{'__issues__'}}, gettext("'network' is not set") );
        }

        if ( $relation_ptr->{'tag'}->{'colour'} ) {
                my $colour = GetColourFromString( $relation_ptr->{'tag'}->{'colour'} );
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("'colour' has unknown value '%s'"),html_escape($relation_ptr->{'tag'}->{'colour'})) )        unless ( $colour );
        }
        
        if ( $positive_notes ) {
            foreach my $special ( 'network:', 'route:', 'ref:', 'ref_', 'operator' ) {
                foreach my $tag ( sort(keys(%{$relation_ptr->{'tag'}})) ) {
                    if ( $tag =~ m/^\Q$special\E/i ) {
                        if ( $relation_ptr->{'tag'}->{$tag} ) {
                            if ( $tag =~ m/^network:long$/i && $network_long_regex){
                                if ( $relation_ptr->{'tag'}->{$tag} =~ m/^$network_long_regex$/ ) {
                                    push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("'%s' is long form"), html_escape($tag)) );
                                } elsif ( $relation_ptr->{'tag'}->{$tag} =~ m/$network_long_regex/ ) {
                                    push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("'%s' matches long form"), html_escape($tag)) );
                                } else {
                                    push( @{$relation_ptr->{'__notes__'}}, sprintf("'%s' = '%s'", html_escape($tag), html_escape($relation_ptr->{'tag'}->{$tag})) )
                                }
                            } else {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf("'%s' = '%s'", html_escape($tag), html_escape($relation_ptr->{'tag'}->{$tag})) )
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
        } elsif ( $type eq 'route') {
            $return_code = analyze_route_relation( $relation_ptr );
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
    my $member_index                   = scalar( @{$relation_ptr->{'members'}} );
    my $relation_index                 = scalar( @{$relation_ptr->{'relation'}} );
    my $route_master_relation_index    = scalar( @{$relation_ptr->{'route_master_relation'}} );
    my $route_relation_index           = scalar( @{$relation_ptr->{'route_relation'}} );
    my $way_index                      = scalar( @{$relation_ptr->{'way'}} );
    my $route_highway_index            = scalar( @{$relation_ptr->{'route_highway'}} );
    my $node_index                     = scalar( @{$relation_ptr->{'node'}} );

    push( @{$relation_ptr->{'__issues__'}}, gettext("Route-Master without Route(s)") )                                   unless ( $route_master_relation_index );
    #push( @{$relation_ptr->{'__notes__'}},  gettext("Route-Master with only 1 Route") )                                  if     ( $route_master_relation_index == 1 );
    push( @{$relation_ptr->{'__issues__'}}, gettext("Route-Master with Relation(s) unequal to 'route'") )                if     ( $route_master_relation_index != $relation_index );
    push( @{$relation_ptr->{'__issues__'}}, gettext("Route-Master with Way(s)") )                                        if     ( $way_index );
    push( @{$relation_ptr->{'__issues__'}}, gettext("Route-Master with Node(s)") )                                       if     ( $node_index );
    if ( $relation_ptr->{'tag'}->{'public_transport:version'} ) {
        if ( $relation_ptr->{'tag'}->{'public_transport:version'} !~ m/^2$/ ) {
            push( @{$relation_ptr->{'__issues__'}}, gettext("'public_transport:version' is not set to '2'") )        if ( $check_version ); 
        } else {
            ; #push( @{$relation_ptr->{'__notes__'}}, sprintf("'public_transport:version' = '%s'",html_escape($relation_ptr->{'tag'}->{'public_transport:version'})) )    if ( $positive_notes );
        }
    } else {
        push( @{$relation_ptr->{'__notes__'}}, gettext("'public_transport:version' is not set") )        if ( $check_version );
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
    my $member_index                   = scalar( @{$relation_ptr->{'members'}} );
    my $relation_index                 = scalar( @{$relation_ptr->{'relation'}} );
    my $route_relation_index           = scalar( @{$relation_ptr->{'route_relation'}} );
    my $way_index                      = scalar( @{$relation_ptr->{'way'}} );
    my $route_highway_index            = scalar( @{$relation_ptr->{'route_highway'}} );
    my $node_index                     = scalar( @{$relation_ptr->{'node'}} );

    $relation_ptr->{'missing_way_data'}   = 0;
    $relation_ptr->{'missing_node_data'}  = 0;

    $return_code += CheckCompletenessOfData( $relation_ptr );
    
    push( @{$relation_ptr->{'__issues__'}}, gettext("Route without Way(s)") )                    unless ( $route_highway_index );
    push( @{$relation_ptr->{'__issues__'}}, gettext("Route with only 1 Way") )                   if     ( $route_highway_index == 1 && $route_type ne 'ferry' && $route_type ne 'aerialway' && $route_type ne 'funicular' );
    push( @{$relation_ptr->{'__issues__'}}, gettext("Route without Node(s)") )                   unless ( $node_index );
    push( @{$relation_ptr->{'__issues__'}}, gettext("Route with only 1 Node") )                  if     ( $node_index == 1 );
    push( @{$relation_ptr->{'__issues__'}}, gettext("Route with Relation(s)") )                  if     ( $route_relation_index );

    if ( $relation_ptr->{'tag'}->{'public_transport:version'} ) {
        if ( $relation_ptr->{'tag'}->{'public_transport:version'} !~ m/^[12]$/ ) {
            push( @{$relation_ptr->{'__issues__'}}, gettext("'public_transport:version' is neither '1' nor '2'") ); 
        } else {
            #push( @{$relation_ptr->{'__notes__'}}, sprintf("'public_transport:version' = '%s'",html_escape($relation_ptr->{'tag'}->{'public_transport:version'})) )    if ( $positive_notes );
            
            if ( $relation_ptr->{'tag'}->{'public_transport:version'} == 2 ) {
                
                if ( $relation_ptr->{'missing_way_data'} == 0 && $relation_ptr->{'missing_node_data'} == 0 ) {
                    $return_code = analyze_ptv2_route_relation( $relation_ptr );
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, gettext("Skipping further analysis ...") );
                }
            }
        }
    } else {
        push( @{$relation_ptr->{'__notes__'}}, gettext("'public_transport:version' is not set") )        if ( $check_version );
    }
    
    #
    # for WAYS used by vehicles     vehicles must have access permission
    #
    if ( $check_access ) {
        $return_code += CheckAccessOnWays( $relation_ptr );
    }

    #
    # all WAYS          must not have "highway" = "bus_stop" set - allowed only on nodes
    # all RELATIONS     must not have "highway" = "bus_stop" set - allowed only on nodes
    #
    if ( $check_bus_stop ) {
        $return_code += CheckBusStopOnWaysAndRelations( $relation_ptr );
    }
    
    #
    # check tag 'route_ref' on stops (highway_bus_stop and public_transport=platform (and also public_transport=stop_position)) 
    #
    if ( $check_route_ref ) {
        $return_code += CheckRouteRefOnStops( $relation_ptr );
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
    my $help_string                   = '';
    my $num_of_errors                 = 0;
    my $access_restriction            = undef;
    
    @relation_route_ways            = FindRouteWays( $relation_ptr );
    
    @relation_route_stop_positions  = FindRouteStopPositions( $relation_ptr );
    
    $relation_ptr->{'non_platform_ways'}       = \@relation_route_ways;
    $relation_ptr->{'number_of_segments'}      = 0;
    $relation_ptr->{'number_of_roundabouts'}   = 0;
    $relation_ptr->{'sorted_in_reverse_order'} = '';
    
    if ( $check_name ) {
        $return_code += CheckNameRefFromViaToPTV2( $relation_ptr );
    }

    if ( $relation_route_ways[0] && $relation_route_ways[1] ) {
        #
        # special check for route being sorted in reverse order and starting with a oneway (except closed way)
        # another check for first way being a oneway way being used in wrong direction
        #
        my $first_way_id    = $relation_route_ways[0];
        my $second_way_id   = $relation_route_ways[1];
        my $entry_node_id   = undef;
        my $node_id         = undef;
        printf STDERR "analyze_ptv2_route_relation() : at least two ways exist: 1st = %d, 2nd = %s\n", $first_way_id, $second_way_id     if ( $debug );
        if ( !isClosedWay($first_way_id) ) {
            printf STDERR "analyze_ptv2_route_relation() : first way is not a closed way\n"     if ( $debug );
            if ( ($entry_node_id = isOneway($first_way_id,undef)) ) {
                printf STDERR "analyze_ptv2_route_relation() : first way is onway with entry_node_id = %d\n", $entry_node_id     if ( $debug );
                if ( $entry_node_id == $WAYS{$first_way_id}->{'first_node'} ) {
                    $node_id = $WAYS{$first_way_id}->{'last_node'};
                    printf STDERR "analyze_ptv2_route_relation() : node_id = %d is 'last_node\n", $node_id     if ( $debug );
                } else {
                    $node_id = $WAYS{$first_way_id}->{'first_node'};
                    printf STDERR "analyze_ptv2_route_relation() : node_id = %d is 'first_node\n", $node_id     if ( $debug );
                }
                printf STDERR "analyze_ptv2_route_relation() : node_id is in relations's stop node array\n" if ( isNodeInNodeArray($node_id,@relation_route_stop_positions) && $debug );
                if ( isNodeInNodeArray($node_id,@relation_route_stop_positions) ) {
                    #
                    # OK, let's check whether this stop-position is not a connecting node to the second way
                    #
                    if ( $node_id == $WAYS{$second_way_id}->{'first_node'} ||
                         $node_id == $WAYS{$second_way_id}->{'last_node'}     ) {
                        #
                        # OK: so it's: ->->->->Sn----Cn------Cn--- which means, the route starts too early (found and reported later on)
                        #
                        ;
                    } else {      # Sn == Stop-Node; Cn == Connecting-Node; ----- == normal Way; ->->->-> == Oneway
                        #
                        #
                        # Bad: it's: Sn<-<-<-<Cn---Cn----- and reverse it's OK: -----Cn---Cn->->->->Sn
                        #
                        $relation_ptr->{'sorted_in_reverse_order'} = 1;
                    }
                } elsif ( $entry_node_id == $WAYS{$second_way_id}->{'first_node'} ||
                          $entry_node_id == $WAYS{$second_way_id}->{'last_node'}     ) {
                    printf STDERR "analyze_ptv2_route_relation() : entering first way (=oneway) in wrong direction %s:", $first_way_id     if ( $debug );
                    $relation_ptr->{'wrong_direction_oneways'}->{$first_way_id} = 1;
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

        foreach my $item ( @{$relation_ptr->{'members'}} ) {
            if ( $item->{'type'} eq 'node' ) {
                if ( $stop_nodes{$item->{'ref'}} ) {
                    $have_seen_stop++;
                    $relation_ptr->{'wrong_sequence'}++     if ( $have_seen_highway_railway );
                    #printf STDERR "stop node after way for %s\n", $item->{'ref'};
                } elsif ( $platform_nodes{$item->{'ref'}} ) {
                    $have_seen_platform++;
                    $relation_ptr->{'wrong_sequence'}++     if ( $have_seen_highway_railway );
                    #printf STDERR "platform node after way for %s\n", $item->{'ref'};
                }
            } elsif ( $item->{'type'} eq 'way' ) {
                if ( $platform_ways{$item->{'ref'}} ) {
                    $have_seen_platform++;
                    $relation_ptr->{'wrong_sequence'}++     if ( $have_seen_highway_railway );
                    #printf STDERR "platform way after way for %s\n", $item->{'ref'};
                } elsif ( $WAYS{$item->{'ref'}}->{'tag'}->{'railway'} ) {
                    if ( $WAYS{$item->{'ref'}}->{'tag'}->{'railway'} ne 'platform' ) {
                        $have_seen_highway_railway++;
                    }
                } elsif ( $WAYS{$item->{'ref'}}->{'tag'}->{'highway'} ) {
                    if ( $WAYS{$item->{'ref'}}->{'tag'}->{'highway'} ne 'platform' &&
                         $WAYS{$item->{'ref'}}->{'tag'}->{'highway'} ne 'bus_stop'    ) {
                        $have_seen_highway_railway++;
                    }
                }
            } elsif ( $item->{'type'} eq 'relation' ) {
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
        push( @{$relation_ptr->{'__issues__'}}, gettext("PTv2 route: first way is a oneway road and ends in a 'stop_position' of this route and there is no exit. Is the route sorted in reverse order?") );
        $return_code++
    }
    if ( $relation_ptr->{'number_of_segments'} > 1 ) {
        my $error_string   = ngettext( "has a gap", "has gaps", $relation_ptr->{'number_of_segments'}-1 );
        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: %s, consists of %d segments"), $error_string, $relation_ptr->{'number_of_segments'}) );
        $return_code += $relation_ptr->{'number_of_segments'} - 1;
    }
    if ( $relation_ptr->{'wrong_sequence'} ) {
        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: incorrect order of 'stop_position', 'platform' and 'way' (stop/platform after way)") ) );
        $return_code++;
    }
    if ( $check_roundabouts  && $relation_ptr->{'number_of_roundabouts'} ) {
        my $error_string   = ngettext( "entire roundabout but uses only segments", "entire roundabouts but uses only segments", $relation_ptr->{'number_of_roundabouts'} );
        push( @{$relation_ptr->{'__notes__'}},  sprintf(gettext("PTv2 route: includes %d %s"), $relation_ptr->{'number_of_roundabouts'}, $error_string ) );
        $return_code++;
    }
    if ( $relation_ptr->{'wrong_direction_oneways'} ) {
        my @help_array     = sort(keys(%{$relation_ptr->{'wrong_direction_oneways'}}));
        my $num_of_errors  = scalar(@help_array);
        my $error_string   = ngettext( "PTv2 route: using oneway way in wrong direction", "PTv2 route: using oneway ways in wrong direction", $num_of_errors );
        if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
            push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $error_string, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
        } else {
            push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $error_string, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
        }
        $return_code++;
    }
    if ( $relation_ptr->{'number_of_segments'} == 1 && $check_motorway_link && $relation_ptr->{'expect_motorway_after'} ) {
        my $helpstring = ngettext( "PTv2 route: using motorway_link way without entering a motorway way:", "PTv2 route: using motorway_link ways without entering a motorway way:", scalar(keys(%{$relation_ptr->{'expect_motorway_after'}})) );
        push( @{$relation_ptr->{'__issues__'}}, sprintf("%s %s", $helpstring, join(', ', map { printWayTemplate($_,'name;ref'); } sort(keys(%{$relation_ptr->{'expect_motorway_after'}})))) );
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
                                            $role_mismatch{gettext("first node of oneway way has 'role' = 'stop_exit_only'")}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                        if ( $node_ref->{'role'} eq 'stop_entry_only' && isLastNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                            $role_mismatch{gettext("last node of oneway way has 'role' = 'stop_entry_only'")}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                    }
                                } elsif ( scalar(@relation_route_ways) > 1 ) {
                                    #
                                    # for routes with more than 1 way
                                    #
                                    # do not consider roundtrip routes where first and last node is the same node but passengers have to leave the bus/tram/...
                                    #
                                    if ( $node_ref->{'role'} eq 'stop_exit_only' ) {
                                        if ( isFirstNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) && !isLastNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                            $role_mismatch{gettext("first node of way has 'role' = 'stop_exit_only'. Is the route sorted in reverse order?")}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                    }
                                    if ( $node_ref->{'role'} eq 'stop_entry_only' ) {
                                        if ( isLastNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) && ! isFirstNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                            $role_mismatch{gettext("last node of way has 'role' = 'stop_entry_only'. Is the route sorted in reverse order?")}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                    }
                                }
                            } else {
                                $role_mismatch{gettext("'public_transport' = 'stop_position' is not part of way")}->{$node_ref->{'ref'}} = 1;
                                $role_mismatch_found++;
                            }
                            if ( $check_stop_position ) {
                                if (  $relation_ptr->{'tag'}->{'route'} eq 'bus'                     ||
                                     ($relation_ptr->{'tag'}->{'route'} eq 'coach' && $allow_coach)  ||
                                      $relation_ptr->{'tag'}->{'route'} eq 'tram'                    ||
                                      $relation_ptr->{'tag'}->{'route'} eq 'share_taxi'                 ) {
                                    if ( $NODES{$node_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}}          &&
                                         $NODES{$node_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}} eq "yes"    ) {
                                        ; # fine
                                    } else {
                                        $help_string = sprintf( gettext( "missing '%s' = 'yes' on 'public_transport' = 'stop_position'" ), $relation_ptr->{'tag'}->{'route'} );
                                        $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                                        $role_mismatch_found++;
                                    }
                                }
                            }
                        }
                        elsif ( $NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'} ) {
                            $help_string = sprintf( gettext( "mismatch between 'role' = '%s' and 'public_transport' = '%s'" ), $node_ref->{'role'}, $NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'} );
                            $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        } elsif ( $ptv1_compatibility ne "no"  ) {
                            my $compatible_tag = PTv2CompatibleNodeStopTag( $node_ref->{'ref'}, $relation_ptr->{'tag'}->{'route'} );
                            if ( $compatible_tag ) {
                                if ( $ptv1_compatibility eq "show" ) {
                                    $help_string = sprintf( gettext( "'role' = '%s' and %s: consider setting 'public_transport' = 'stop_position'" ), $node_ref->{'role'}, $compatible_tag ); 
                                    $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                                    $role_mismatch_found++;
                                }
                            } else {
                                $help_string = sprintf( gettext( "'role' = '%s' but 'public_transport' is not set" ), $node_ref->{'role'} );
                                $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                                $role_mismatch_found++;
                            }
                        } else {
                            $help_string = sprintf( gettext( "'role' = '%s' but 'public_transport' is not set" ), $node_ref->{'role'} );
                            $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        }
                    } else {           # matches any platform of the three choices
                        if ( $platform_nodes{$node_ref->{'ref'}} ) {
                            if ( isNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                $role_mismatch{gettext("'public_transport' = 'platform' is part of way")}->{$node_ref->{'ref'}} = 1;
                                $role_mismatch_found++;
                            } else {
                                ; # fine, what else can we check here?
                            }
                            #
                            # bus=yes, tram=yes or share_taxi=yes is not required on public_transport=platform
                            #
                            #if ( $check_platform ) {
                            #    if (  $relation_ptr->{'tag'}->{'route'} eq 'bus'                     ||
                            #         ($relation_ptr->{'tag'}->{'route'} eq 'coach' && $allow_coach)  ||
                            #          $relation_ptr->{'tag'}->{'route'} eq 'tram'                    ||
                            #          $relation_ptr->{'tag'}->{'route'} eq 'share_taxi'                 ) {
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
                        } elsif ( $NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'} ) {
                            $help_string = sprintf( gettext( "mismatch between 'role' = '%s' and 'public_transport' = '%s'" ), $node_ref->{'role'}, $NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'} );
                            $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        } elsif ( $ptv1_compatibility ne "no"  ) {
                            my $compatible_tag = PTv2CompatibleNodePlatformTag( $node_ref->{'ref'}, $relation_ptr->{'tag'}->{'route'} );
                            if ( $compatible_tag ) {
                                if ( $ptv1_compatibility eq "show" ) {
                                    $help_string = sprintf( gettext( "'role' = '%s' and %s: consider setting 'public_transport' = 'platform'" ), $node_ref->{'role'}, $compatible_tag );
                                    $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                                    $role_mismatch_found++;
                                }
                            } else {
                                $help_string = sprintf( gettext( "'role' = '%s' but 'public_transport' is not set" ), $node_ref->{'role'} );
                                $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                                $role_mismatch_found++;
                            }
                        } else {
                            $help_string = sprintf( gettext( "'role' = '%s' but 'public_transport' is not set" ), $node_ref->{'role'} );
                            $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        }
                    }
                }
            } else {
                $help_string = sprintf( gettext( "wrong 'role' = '%s'" ), ctrl_escape($node_ref->{'role'}) );
                $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        } else {
            $role_mismatch{gettext( "empty 'role'")}->{$node_ref->{'ref'}} = 1;
            $role_mismatch_found++;
        }
    }
    if ( $role_mismatch_found ) {
        foreach my $role ( sort ( keys ( %role_mismatch ) ) ) {
            @help_array     = sort(keys(%{$role_mismatch{$role}}));
            $num_of_errors  = scalar(@help_array);
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: %s: %s and %d more ..."), $role, join(', ', map { printNodeTemplate($_,'name'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: %s: %s"), $role, join(', ', map { printNodeTemplate($_,'name'); } @help_array )) );
            }
        }
    }
    $return_code += $role_mismatch_found;

    if ( $relation_ptr->{'number_of_segments'} == 1 ) {
        printf STDERR "Checking whether first node is member of relation_route_stop_positions: Route-Name: %s\n", $relation_ptr->{'tag'}->{'name'}      if ( $debug );
        if ( isNodeInNodeArray($sorted_way_nodes[0],@relation_route_stop_positions) ) {
            #
            # fine, first node of ways is actually a stop position of this route
            #
            if ( $sorted_way_nodes[0] == $relation_route_stop_positions[0] ) {
                #
                # fine, first stop position in the list is actually the first node of the way
                #
                ;
            } else {
                if ( scalar(@relation_route_ways) > 1 || isOneway($relation_route_ways[0],undef) ) {
                    #
                    # if we have more than one way or the single way is a oneway, and because we know: the ways are sorted and w/o gaps
                    #
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: first node of way is not the first stop position of this route: %s versus %s"), printNodeTemplate($sorted_way_nodes[0],'name'), printNodeTemplate($relation_route_stop_positions[0],'name') ) );            
                    $return_code++;
                }
            }
        } else {
            printf STDERR "No! Checking whether we can be relaxed: Route-Name: %s\n", $relation_ptr->{'tag'}->{'name'}      if ( $debug );
            my $relaxed_for =  $relaxed_begin_end_for || '';
            $relaxed_for    =~ s/;/,/g;
            $relaxed_for    =  ',' . $relaxed_for . ',';
            if ( $relaxed_for =~ m/,\Q$relation_ptr->{'tag'}->{'route'}\E,/ ) {
                my $first_way_ID     = $relation_route_ways[0];
                my @first_way_nodes  = ();
                my $found_it         = 0;
                my $found_nodeid     = 0;
                my $node_name       = '';

                if ( $sorted_way_nodes[0] == ${$WAYS{$first_way_ID}->{'chain'}}[0] ) {
                    @first_way_nodes  = @{$WAYS{$first_way_ID}->{'chain'}};
                } else {
                    @first_way_nodes  = reverse @{$WAYS{$first_way_ID}->{'chain'}};
                }
                
                foreach my $nodeid ( @first_way_nodes ) {
                    if ( $debug ) { $node_name = ( $NODES{$nodeid} && $NODES{$nodeid}->{'tag'} && $NODES{$nodeid}->{'tag'}->{'name'}) ? $NODES{$nodeid}->{'tag'}->{'name'} : ''; }
                    printf STDERR "WAY{%s}->{'chain'}->%s name='%s'\n", $first_way_ID, $nodeid, $node_name   if ( $debug );
                    if ( isNodeInNodeArray($nodeid,@relation_route_stop_positions) ) {
                        #
                        # fine, an inner node, or the last of the first way is a stop position of this route
                        #
                        $found_it++;
                        printf STDERR "WAY{%s}->{'chain'}->%s - %d\n", $first_way_ID, $nodeid, $found_it   if ( $debug );
                        if ( $nodeid == $relation_route_stop_positions[0] ) {
                            #
                            # fine the first node of the first way which is a stop position and is actually the first stop position
                            #
                            $found_it++;
                            printf STDERR "WAY{%s}->{'chain'}->%s - %d\n", $first_way_ID, $nodeid, $found_it   if ( $debug );
                        }
                        $found_nodeid = $nodeid;
                        last;
                    }
                }
                if ( $found_it == 1 ) {
                    printf STDERR "1: Number of ways: %s, found_nodeid = %s, last node of first way = %s\n", scalar(@relation_route_ways), $found_nodeid, $first_way_nodes[$#first_way_nodes]  if ( $debug );
                    if ( scalar(@relation_route_ways) > 1 && $found_nodeid == $first_way_nodes[$#first_way_nodes] ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: there is no stop position of this route on the first way, except the last node == first node of next way: %s"), printWayTemplate($first_way_ID,'name;ref') ) );            
                        $return_code++;
                    } else {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: first stop position on first way is not the first stop position of this route: %s versus %s"), printNodeTemplate($found_nodeid,'name'), printNodeTemplate($relation_route_stop_positions[0],'name') ) );            
                        $return_code++;
                    }
                }
                elsif ( $found_it == 2 ) {
                    printf STDERR "2: Number of ways: %s, found_nodeid = %s, last node of first way = %s\n", scalar(@relation_route_ways), $found_nodeid, $first_way_nodes[$#first_way_nodes]  if ( $debug );
                    if ( scalar(@relation_route_ways) > 1 && $found_nodeid == $first_way_nodes[$#first_way_nodes] ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: there is no stop position of this route on the first way, except the last node == first node of next way: %s"), printWayTemplate($first_way_ID,'name;ref') ) );            
                        $return_code++;
                    }
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: there is no stop position of this route on the first way: %s"), printWayTemplate($first_way_ID,'name;ref') ) );            
                    $return_code++;
                }
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: first node of way is not a stop position of this route: %s"), printNodeTemplate($sorted_way_nodes[0],'name') ) );            
                $return_code++;
            }
        }
        printf STDERR "Checking whether last node is member of relation_route_stop_positions: Route-Name: %s\n", $relation_ptr->{'tag'}->{'name'}      if ( $debug );
        if ( isNodeInNodeArray($sorted_way_nodes[$#sorted_way_nodes],@relation_route_stop_positions) ) {
            #
            # fine, last node of ways is actually a stop position of this route
            #
            if ( $sorted_way_nodes[$#sorted_way_nodes] == $relation_route_stop_positions[$#relation_route_stop_positions] ) {
                #
                # fine, last stop position in the list is actually the last node of the way
                #
                ;
            } else {
                if ( scalar(@relation_route_ways) > 1 || isOneway($relation_route_ways[0],undef) ) {
                    #
                    # if we have more than one way or the single way is a oneway, and because we know: the ways are sorted and w/o gaps
                    #
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: last node of way is not the last stop position of this route: %s versus %s"), printNodeTemplate($sorted_way_nodes[$#sorted_way_nodes],'name'), printNodeTemplate($relation_route_stop_positions[$#relation_route_stop_positions],'name') ) );            
                    $return_code++;
                }
            }
        } else {
            printf STDERR "No! Checking whether we can be relaxed: Route-Name: %s\n", $relation_ptr->{'tag'}->{'name'}      if ( $debug );
            my $relaxed_for =  $relaxed_begin_end_for || '';
            $relaxed_for    =~ s/;/,/g;
            $relaxed_for    =  ',' . $relaxed_for . ',';
            if ( $relaxed_for =~ m/,\Q$relation_ptr->{'tag'}->{'route'}\E,/ ) {
                my $last_way_ID     = $relation_route_ways[$#relation_route_ways];
                my @last_way_nodes  = ();
                my $found_it        = 0;
                my $found_nodeid    = 0;
                my $node_name       = '';

                if ( $sorted_way_nodes[$#sorted_way_nodes] == ${$WAYS{$last_way_ID}->{'chain'}}[0] ) {
                    @last_way_nodes  = @{$WAYS{$last_way_ID}->{'chain'}};
                } else {
                    @last_way_nodes  = reverse @{$WAYS{$last_way_ID}->{'chain'}};
                }
                
                foreach my $nodeid ( @last_way_nodes ) {
                    if ( $debug ) { $node_name = ( $NODES{$nodeid} && $NODES{$nodeid}->{'tag'} && $NODES{$nodeid}->{'tag'}->{'name'}) ? $NODES{$nodeid}->{'tag'}->{'name'} : ''; }
                    printf STDERR "WAY{%s}->{'chain'}->%s name='%s'\n", $last_way_ID, $nodeid, $node_name   if ( $debug );
                    if ( isNodeInNodeArray($nodeid,@relation_route_stop_positions) ) {
                        #
                        # fine, an inner node, or the first of the last way is a stop position of this route
                        #
                        $found_it++;
                        printf STDERR "WAY{%s}->{'chain'}->%s - %d\n", $last_way_ID, $nodeid, $found_it   if ( $debug );
                        if ( $nodeid == $relation_route_stop_positions[$#relation_route_stop_positions] ) {
                            #
                            # fine the last node of the last way which is a stop position and is actually the last stop position
                            #
                            $found_it++;
                            printf STDERR "WAY{%s}->{'chain'}->%s - %d\n", $last_way_ID, $nodeid, $found_it   if ( $debug );
                        }
                        $found_nodeid = $nodeid;
                        last;
                    }
                }
                if ( $found_it == 1 ) {
                    printf STDERR "1: Number of ways: %s, found_nodeid = %s, first node of last way = %s\n", scalar(@relation_route_ways), $found_nodeid, $last_way_nodes[0]  if ( $debug );
                    if ( scalar(@relation_route_ways) > 1 && $found_nodeid == $last_way_nodes[$#last_way_nodes] ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: there is no stop position of this route on the last way, except the first node == last node of previous way: %s"), printWayTemplate($last_way_ID,'name;ref') ) );            
                        $return_code++;
                    } else {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: last stop position on last way is not the last stop position of this route: %s versus %s"), printNodeTemplate($found_nodeid,'name'), printNodeTemplate($relation_route_stop_positions[$#relation_route_stop_positions],'name') ) );            
                        $return_code++;
                    }
                }
                elsif ( $found_it == 2 ) {
                    printf STDERR "2: Number of ways: %s, found_nodeid = %s, first node of last way = %s\n", scalar(@relation_route_ways), $found_nodeid, $last_way_nodes[0]  if ( $debug );
                    if ( scalar(@relation_route_ways) > 1 && $found_nodeid == $last_way_nodes[$#last_way_nodes] ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: there is no stop position of this route on the last way, except the first node == last node of previous way: %s"), printWayTemplate($last_way_ID,'name;ref') ) );            
                        $return_code++;
                    }
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: there is no stop position of this route on the last way: %s"), printWayTemplate($last_way_ID,'name;ref') ) );            
                    $return_code++;
                }
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: last node of way is not a stop position of this route: %s"), printNodeTemplate($sorted_way_nodes[$#sorted_way_nodes],'name') ) );            
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
                        #    if (  $relation_ptr->{'tag'}->{'route'} eq 'bus'                    ||
                        #         ($relation_ptr->{'tag'}->{'route'} eq 'coach' && $allow_coach) ||
                        #          $relation_ptr->{'tag'}->{'route'} eq 'tram'                   ||
                        #          $relation_ptr->{'tag'}->{'route'} eq 'share_taxi'                ) {
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
                    } elsif ( $WAYS{$highway_ref->{'ref'}}->{'tag'}->{'public_transport'} ) {
                        $help_string = sprintf( gettext( "mismatch between 'role' = '%s' and 'public_transport' = '%s'" ), $highway_ref->{'role'}, $WAYS{$highway_ref->{'ref'}}->{'tag'}->{'public_transport'} );
                        $role_mismatch{$help_string}->{$highway_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    } else {
                        $help_string = sprintf( gettext( "'role' = '%s' but 'public_transport' is not set" ), $highway_ref->{'role'} );
                        $role_mismatch{$help_string}->{$highway_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    }
                }
            } else {
                $help_string = sprintf( gettext( "wrong 'role' = '%s'" ), ctrl_escape($highway_ref->{'role'}) );
                $role_mismatch{$help_string}->{$highway_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        } else {
            if ( $platform_ways{$highway_ref->{'ref'}} ) {
                $role_mismatch{gettext("empty 'role'")}->{$highway_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        }
    }
    if ( $role_mismatch_found ) {
        foreach my $role ( sort ( keys ( %role_mismatch ) ) ) {
            @help_array     = sort(keys(%{$role_mismatch{$role}}));
            $num_of_errors  = scalar(@help_array);
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: %s: %s and %d more ..."), $role, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            }
            else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: %s: %s"), $role, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
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
                        #    if (  $relation_ptr->{'tag'}->{'route'} eq 'bus'                    ||
                        #         ($relation_ptr->{'tag'}->{'route'} eq 'coach' && $allow_coach) ||
                        #          $relation_ptr->{'tag'}->{'route'} eq 'tram'                   ||
                        #          $relation_ptr->{'tag'}->{'route'} eq 'share_taxi'               ) {
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
                    } elsif ( $RELATIONS{$rel_ref->{'ref'}}                                &&
                            $RELATIONS{$rel_ref->{'ref'}}->{'tag'}->{'public_transport'}   ) {
                        $help_string = sprintf( gettext( "mismatch between 'role' = '%s' and 'public_transport' = '%s'" ), $rel_ref->{'role'}, $RELATIONS{$rel_ref->{'ref'}}->{'tag'}->{'public_transport'} );
                        $role_mismatch{$help_string}->{$rel_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    } else {
                        $help_string = sprintf( gettext( "'role' = '%s' but 'public_transport' is not set" ), $rel_ref->{'role'} );
                        $role_mismatch{$help_string}->{$rel_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    }
                }
            } else {
                $help_string = sprintf( gettext( "wrong 'role' = '%s'" ), ctrl_escape($rel_ref->{'role'}) );
                $role_mismatch{$help_string}->{$rel_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        } else {
            $role_mismatch{gettext("empty 'role'")}->{$rel_ref->{'ref'}} = 1;
            $role_mismatch_found++;
        }
    }
    if ( $role_mismatch_found ) {
        foreach my $role ( sort ( keys ( %role_mismatch ) ) ) {
            @help_array     = sort(keys(%{$role_mismatch{$role}}));
            $num_of_errors  = scalar(@help_array);
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: %s: %s and %d more ..."), $role, join(', ', map { printRelationTemplate($_,'ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("PTv2 route: %s: %s"), $role, join(', ', map { printRelationTemplate($_,'ref'); } @help_array )) );
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
    my %expect_motorway_or_motorway_link_after = ();
    
    printf STDERR "SortRouteWayNodes() : processing Ways:\nWays: %s\n", join( ', ', @{$relations_route_ways_ref} )     if ( $debug );
    
    if ( $relation_ptr && $relations_route_ways_ref ) {
        
        $number_of_ways = scalar @{$relations_route_ways_ref} ;
        if ( $number_of_ways ) {
            # we have at least one way, so we start with one segment
            $relation_ptr->{'number_of_segments'} = 1;
        } else {
            # no ways, no segments
            $relation_ptr->{'number_of_segments'} = 0;
        }
        
        while ( ${$relations_route_ways_ref}[$way_index] ) {
            
            $current_way_id  = ${$relations_route_ways_ref}[$way_index];
            $next_way_id     = ${$relations_route_ways_ref}[$way_index+1];
            $way_index++;
            
            push( @control_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
    
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
                        if ( ($index=IndexOfNodeInNodeArray($connecting_node_id,@{$WAYS{$current_way_id}->{'chain'}})) >= 0 ) {
                            printf STDERR "SortRouteWayNodes() : handle Nodes of closed Way %s with Index %d:\nNodes: %s\n", $current_way_id, $index, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            my $i = 0;
                            for ( $i = $index+1; $i <= $#{$WAYS{$current_way_id}->{'chain'}}; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'chain'}}[$i] );
                            }
                            for ( $i = 1; $i <= $index; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'chain'}}[$i] );
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
                                                                    join( ', ', @{$WAYS{$current_way_id}->{'chain'}} ), 
                                                                    join( ', ', @{$WAYS{$next_way_id}->{'chain'}} )     if ( $debug );
                            } else {
                                printf STDERR "SortRouteWayNodes() : handle partially used roundabout %s at node %s for %s:\nNodes here : %s\nNodes there: %s\n",
                                                                    $current_way_id, 
                                                                    $sorted_nodes[$#sorted_nodes], 
                                                                    $next_way_id, 
                                                                    join( ', ', @{$WAYS{$current_way_id}->{'chain'}} ), 
                                                                    join( ', ', @{$WAYS{$next_way_id}->{'chain'}} )     if ( $debug );
                                
                                $relation_ptr->{'number_of_roundabouts'}++;
                                
                                if ( isNodeInNodeArray($WAYS{$next_way_id}->{'first_node'},@{$WAYS{$current_way_id}->{'chain'}}) || 
                                     isNodeInNodeArray($WAYS{$next_way_id}->{'last_node'}, @{$WAYS{$current_way_id}->{'chain'}})     ){
                                    #
                                    # there is a match with first or last node of next way and some node of this roundabout
                                    # so we're deleting superflous nodes from the top of sorted_nodes until we hit the connecting node
                                    #
                                    while ( $sorted_nodes[$#sorted_nodes] != $WAYS{$next_way_id}->{'first_node'} &&
                                            $sorted_nodes[$#sorted_nodes] != $WAYS{$next_way_id}->{'last_node'}     ) {
                                        printf STDERR "SortRouteWayNodes() : pop() Node %s from \@sorted_nodes\n", $sorted_nodes[$#sorted_nodes]     if ( $debug );
                                        pop( @sorted_nodes );
                                    }
                                } else {
                                    #
                                    # no way out, we do not have any connection between any node of this way and the next way
                                    #
                                    printf STDERR "SortRouteWayNodes() : no match between this closed Way %s and the next Way %s\n", $current_way_id, $next_way_id      if ( $debug );
                                    push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                                    $relation_ptr->{'number_of_segments'}++;
                                    printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at Way %s and the next Way %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, $next_way_id      if ( $debug );
                                }
                            }
                        } else {
                            printf STDERR "SortRouteWayNodes() : handle Nodes of first, closed, single Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                            push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                            $relation_ptr->{'number_of_segments'}++;
                            printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at first, closed, single Way %s:\nNodes: %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                        }
                    } elsif ( 0 != ($entry_node_id=isOneway($current_way_id,undef)) ) {
                        if ( $connecting_node_id == $entry_node_id ) {
                            #
                            # perfect, entering the oneway in the right or allowed direction
                            #
                            if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                #
                                # perfect order for this way (oneway=yes, junction=roundabout): last node of former segment is first node of this way
                                #
                                printf STDERR "SortRouteWayNodes() : handle Nodes of oneway Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                                pop( @sorted_nodes );     # don't add connecting node twice
                                push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                            } else {
                                #
                                # not so perfect (oneway=-1), but we can take the nodes of this way in reverse order
                                #
                                printf STDERR "SortRouteWayNodes() : handle Nodes of oneway Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                                pop( @sorted_nodes );     # don't add connecting node twice
                                push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                            }
                        } else {
                            if ( $connecting_node_id == $WAYS{$current_way_id}->{'last_node'}  ||
                                 $connecting_node_id == $WAYS{$current_way_id}->{'first_node'}    ) {
                                #
                                # oops! entering oneway in wrong direction, copying nodes assuming we are allowd to do so
                                #
                                if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                    printf STDERR "SortRouteWayNodes() : entering oneway in wrong direction Way %s:\nNodes: %s, reverse( %s )\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                                    push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                                } else {
                                    # not so perfect (oneway=-1), but we can take the nodes of this way in direct order
                                    printf STDERR "SortRouteWayNodes() : entering oneway in wrong direction Way %s:\nNodes: %s, %s\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                                    push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                                }
                                $relation_ptr->{'wrong_direction_oneways'}->{$current_way_id} = 1;
                            }
                            else {
                                #
                                # no match, i.e. a gap between this (current) way and the way before
                                #
                                push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                                if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                    printf STDERR "SortRouteWayNodes() : mark a gap before oneway Way %s:\nNodes: %s, G, %s\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                                    push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                                } else {
                                    # not so perfect (oneway=-1), but we can take the nodes of this way in revers order
                                    printf STDERR "SortRouteWayNodes() : mark a gap before oneway Way %s:\nNodes: %s, G, reverse(%)s\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                                    push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                                }
                                printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ at gap between this (current) way and the way before\n"     if ( $debug );
                                $relation_ptr->{'number_of_segments'}++;
                                $connecting_node_id = 0;
                            }
                        }
                    } elsif ( $connecting_node_id eq $WAYS{$current_way_id}->{'first_node'} ) {
                        #
                        # perfect order for this way: last node of former segment is first node of this way
                        #
                        printf STDERR "SortRouteWayNodes() : handle Nodes of Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                        pop( @sorted_nodes );     # don't add connecting node twice
                        push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                    } elsif ( $connecting_node_id eq $WAYS{$current_way_id}->{'last_node'} ) {
                        #
                        # not so perfect, but we can take the nodes of this way in reverse order
                        #
                        printf STDERR "SortRouteWayNodes() : handle Nodes of Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                        pop( @sorted_nodes );     # don't add connecting node twice
                        push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                    } else {
                        #
                        # no match, i.e. a gap between this (current) way and the way before
                        #
                        printf STDERR "SortRouteWayNodes() : mark a gap before Way %s:\nNodes: %s, G, %s\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                        push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                        push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                        $relation_ptr->{'number_of_segments'}++;
                        printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d before Way %s:\nNodes: %s, G, %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
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
                        if ( ($index=IndexOfNodeInNodeArray($WAYS{$next_way_id}->{'first_node'},@{$WAYS{$current_way_id}->{'chain'}})) >= 0 ||
                             ($index=IndexOfNodeInNodeArray($WAYS{$next_way_id}->{'last_node'}, @{$WAYS{$current_way_id}->{'chain'}})) >= 0    ) {
                            printf STDERR "SortRouteWayNodes() : handle Nodes of first, closed Way %s with Index %d:\nNodes: %s\n", $current_way_id, $index, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            my $i = 0;
                            for ( $i = $index+1; $i <= $#{$WAYS{$current_way_id}->{'chain'}}; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'chain'}}[$i] );
                            }
                            for ( $i = 1; $i <= $index; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'chain'}}[$i] );
                            }
                        } else {
                            printf STDERR "SortRouteWayNodes() : handle Nodes of first, closed, single Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                            push( @sorted_nodes, 0 );                   # mark a gap in the sorted nodes
                            $relation_ptr->{'number_of_segments'}++;
                            printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at Nodes of first, closed, single Way %s:\nNodes: %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
    
                        }
                    } elsif ( 0 != ($entry_node_id=isOneway($current_way_id,undef)) ) {
                        if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                            #
                            # perfect order for this way (oneway=yes, junction=roundabout): start at first node of this way
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes of first oneway Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                        } else {
                            #
                            # not so perfect (oneway=-1), but we can take the nodes of this way in reverse order
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes of first oneway Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                        }
                    } elsif ( isClosedWay($next_way_id) ) {
                        #
                        # no direct match, this current way shall connect to a closed way, roundabout or whatever, where first node is also last node
                        # check whether first or last node of this way is one of the nodes of the next, closed way, so that we have a connectting point
                        #
                        if ( ($index=IndexOfNodeInNodeArray($WAYS{$current_way_id}->{'last_node'},@{$WAYS{$next_way_id}->{'chain'}})) >= 0 ) {
                            #
                            # perfect match, last node of this way is a node of the next roundabout
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes for last Node %s of first Way %s connecting to a closed Way %s with Index %d:\nNodes: %s\n", $WAYS{$current_way_id}->{'first_node'}, $current_way_id, $next_way_id. $index, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                        } elsif ( ($index=IndexOfNodeInNodeArray($WAYS{$current_way_id}->{'first_node'},@{$WAYS{$next_way_id}->{'chain'}})) >= 0 ) {
                            #
                            # not so perfect match, but first node of this way is a node of the next roundabout
                            # take nodes of this way in reverse order
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes for first Node %s of first Way %s connecting to a closed Way %s with Index %d:\nNodes: reverse( %s )\n", $WAYS{$current_way_id}->{'first_node'}, $current_way_id, $next_way_id. $index, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                        } else {
                            #
                            # no match at all into next, closed way, i.e. a gap between this (current) way and the next, closed way
                            # take nodes of this way in normal order and mark a gap after that
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes of single Way %s before a closed Way %s:\nNodes: %s, G\n", $current_way_id, $next_way_id, oin( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                            push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                            push( @sorted_nodes, 0 );                   # mark a gap in the sorted nodes
                            $relation_ptr->{'number_of_segments'}++;
                            printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at Nodes of single Way %s before a closed Way %s:\nNodes: %s, G\n", $relation_ptr->{'number_of_segments'}, $current_way_id, $next_way_id, oin( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                        }
                    } elsif ( $WAYS{$current_way_id}->{'last_node'} == $WAYS{$next_way_id}->{'first_node'}   ||
                            $WAYS{$current_way_id}->{'last_node'} == $WAYS{$next_way_id}->{'last_node'}       ) {
                        #
                        # perfect order for this way: last node of this segment is first or last node of next segment
                        #
                        printf STDERR "SortRouteWayNodes() : handle Nodes of first Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                        push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                    } elsif ( $WAYS{$current_way_id}->{'first_node'} == $WAYS{$next_way_id}->{'first_node'}   ||
                            $WAYS{$current_way_id}->{'first_node'} == $WAYS{$next_way_id}->{'last_node'}       ) {
                        #
                        # not so perfect, but we can take the nodes of this way in reverse order
                        #
                        printf STDERR "SortRouteWayNodes() : handle Nodes of first Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                        push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                    } else {
                        #
                        # no match at all, i.e. a gap between this (current) way and the next way
                        #
                        printf STDERR "SortRouteWayNodes() : handle Nodes of single Way %s:\nNodes: %s, G\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                        push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                        push( @sorted_nodes, 0 );                   # mark a gap in the sorted nodes
                        $relation_ptr->{'number_of_segments'}++;
                        printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at Nodes of single Way %s:\nNodes: %s, G\n", $relation_ptr->{'number_of_segments'}, $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                    }
                }
            } else {
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
                        if ( ($index=IndexOfNodeInNodeArray($connecting_node_id,@{$WAYS{$current_way_id}->{'chain'}})) >= 0 ) {
                            printf STDERR "SortRouteWayNodes() : handle Nodes of last, closed Way %s with Index %d:\nNodes: %s\n", $current_way_id, $index, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            my $i = 0;
                            for ( $i = $index+1; $i <= $#{$WAYS{$current_way_id}->{'chain'}}; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'chain'}}[$i] );
                            }
                            for ( $i = 1; $i <= $index; $i++ ) {
                                push( @sorted_nodes, ${$WAYS{$current_way_id}->{'chain'}}[$i] );
                            }
                        } else {
                            push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                            printf STDERR "SortRouteWayNodes() : handle Nodes of last, closed, isolated Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                            $relation_ptr->{'number_of_segments'}++;
                            printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at Nodes of last, closed, isolated Way %s:\nNodes: %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                        }
                    } elsif ( 0 != ($entry_node_id=isOneway($current_way_id,undef)) ) {
                        if ( $connecting_node_id == $entry_node_id ) {
                            #
                            # perfect, entering the oneway in the right or allowed direction
                            #
                            if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                #
                                # perfect order for this way (oneway=yes, junction=roundabout): last node of former segment is first node of this way
                                #
                                printf STDERR "SortRouteWayNodes() : handle Nodes of oneway Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                                pop( @sorted_nodes );     # don't add connecting node twice
                                push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                            } else {
                                #
                                # not so perfect (oneway=-1), but we can take the nodes of this way in reverse order
                                #
                                printf STDERR "SortRouteWayNodes() : handle Nodes of oneway Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                                pop( @sorted_nodes );     # don't add connecting node twice
                                push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                            }
                        } else{
                            if ( $connecting_node_id == $WAYS{$current_way_id}->{'last_node'}  ||
                                 $connecting_node_id == $WAYS{$current_way_id}->{'first_node'}    ) {
                                #
                                # oops! entering oneway in wrong direction, copying nodes assuming we are allowd to do so
                                #
                                if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                    printf STDERR "SortRouteWayNodes() : entering oneway in wrong direction Way %s:\nNodes: %s, reverse( %s )\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                                    push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                                } else {
                                    # not so perfect (oneway=-1), but we can take the nodes of this way in direct order
                                    printf STDERR "SortRouteWayNodes() : entering oneway in wrong direction Way %s:\nNodes: %s, %s\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                                    push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                                }
                                $relation_ptr->{'wrong_direction_oneways'}->{$current_way_id} = 1;
                            } else {
                                #
                                # no match, i.e. a gap between this (current) way and the way before, we will follow the oneway in the intended direction
                                #
                                push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                                if ( $entry_node_id == $WAYS{$current_way_id}->{'first_node'} ) {
                                    printf STDERR "SortRouteWayNodes() : mark a gap before oneway Way %s:\nNodes: %s, G, %s, G\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                                    push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                                } else {
                                    # not so perfect (oneway=-1), but we can take the nodes of this way in reverse order
                                    printf STDERR "SortRouteWayNodes() : mark a gap before oneway Way %s:\nNodes: %s, G, reverse( %s ), G\n", $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                                    push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                                }
                                $relation_ptr->{'number_of_segments'}++;
                                printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at gap between this (current) way and the way before, we will follow the oneway in the intended direction\n", $relation_ptr->{'number_of_segments'}, $current_way_id, $connecting_node_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )    if ( $debug );
                                $connecting_node_id = 0;
                            }
                        }
                    } elsif ( $connecting_node_id eq $WAYS{$current_way_id}->{'first_node'} ) {
                        printf STDERR "SortRouteWayNodes() : handle Nodes of last, connected Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                        pop( @sorted_nodes );     # don't add connecting node twice
                        push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                    } elsif ( $connecting_node_id eq $WAYS{$current_way_id}->{'last_node'} ) {
                        printf STDERR "SortRouteWayNodes() : handle Nodes of last, connected Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                        pop( @sorted_nodes );     # don't add connecting node twice
                        push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                    } else {
                        printf STDERR "SortRouteWayNodes() : last, isolated Way %s and Node %s\n", $current_way_id, $connecting_node_id     if ( $debug );
                        push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                        push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                        $relation_ptr->{'number_of_segments'}++;
                        printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d last, isolated Way %s and Node %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, $connecting_node_id     if ( $debug );
                    }
                } else {
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
                            printf STDERR "SortRouteWayNodes() : handle Nodes of last, isolated, single oneway Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            pop( @sorted_nodes );     # don't add connecting node twice
                            push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                        } else {
                            #
                            # not so perfect (oneway=-1), but we can take the nodes of this way in reverse order
                            #
                            printf STDERR "SortRouteWayNodes() : handle Nodes of last, isolated, single oneway Way %s:\nNodes: reverse( %s )\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            pop( @sorted_nodes );     # don't add connecting node twice
                            push( @sorted_nodes, reverse(@{$WAYS{$current_way_id}->{'chain'}}) );
                        }
                    } else {
                        printf STDERR "SortRouteWayNodes() : handle Nodes of last, isolated Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                        push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                    }
                    $relation_ptr->{'number_of_segments'}++ unless ( $number_of_ways == 1 );  # a single way cannot have 2 segments
                    printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'} = %d at handle Nodes of last, isolated Way\n", $relation_ptr->{'number_of_segments'}    if ( $debug );
                }
            }
            
            $connecting_node_id = $sorted_nodes[$#sorted_nodes];
            
            #
            # check whether we entered a motorway_link and did not enter motorway before entering another type of way
            #
            if ( $current_way_id && $WAYS{$current_way_id} && $WAYS{$current_way_id}->{'tag'} && $WAYS{$current_way_id}->{'tag'}->{'highway'} && 
                 $next_way_id    && $WAYS{$next_way_id}    && $WAYS{$next_way_id}->{'tag'}    && $WAYS{$next_way_id}->{'tag'}->{'highway'}        ) {
                if ( $WAYS{$next_way_id}->{'tag'}->{'highway'} eq 'motorway_link' ) {
                    #
                    # next way is a motorway_link - be carefull
                    #
                    if ( $WAYS{$current_way_id}->{'tag'}->{'highway'} eq 'motorway' || 
                         $WAYS{$current_way_id}->{'tag'}->{'highway'} eq 'trunk'       ) {
                        #
                        # current way is motorway or trunk and next way is motorway_link - everthings is fine, no problem
                        #
                        %expect_motorway_or_motorway_link_after = ();
                    } elsif ( $WAYS{$current_way_id}->{'tag'}->{'highway'} eq 'motorway_link' ) {
                        #
                        # current way is motorway_link and next way is motorway_link
                        #
                        if ( scalar ( keys ( %expect_motorway_or_motorway_link_after ) ) ) {
                            #
                            # a problem only if it has been a problem already
                            #
                            $expect_motorway_or_motorway_link_after{$next_way_id} = 1;
                        }
                    } else {
                        #
                        # current way is anything except motorway/motorway-link and next way is motorway_link - be carefull, start watching this
                        #
                        $expect_motorway_or_motorway_link_after{$next_way_id} = 1;
                    }
                } elsif ( $WAYS{$next_way_id}->{'tag'}->{'highway'} eq 'motorway' ||
                          $WAYS{$next_way_id}->{'tag'}->{'highway'} eq 'trunk'       ) {
                    if ( $WAYS{$current_way_id}->{'tag'}->{'highway'} eq 'motorway_link' ) {
                        #
                        # current way is motorway_link and next way is motorway or trunk - everthings is fine, no problem
                        #
                        %expect_motorway_or_motorway_link_after = ();
                    }
                }
            }
        }
    
        foreach my $k ( keys ( %expect_motorway_or_motorway_link_after ) ) {
            $relation_ptr->{'expect_motorway_after'}->{$k} = 1;
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

sub PTv2CompatibleNodeStopTag {
    my $node_id         = shift;
    my $vehicle_type    = shift;
    
    return '';
}


#############################################################################################

sub PTv2CompatibleNodePlatformTag {
    my $node_id         = shift;
    my $vehicle_type    = shift;
    my $ret_val         = '';
    
    if ( $NODES{$node_id}->{'member_of_way'} ) {
        # this node is a member of a way,  yet don't know which type
        if ( !defined($vehicle_type)                    || 
              $vehicle_type eq 'bus'                    || 
             ($vehicle_type eq 'coach' && $allow_coach) || 
              $vehicle_type eq 'share_taxi'             || 
              $vehicle_type eq 'trolleybus'                ) {
            if ( $NODES{$node_id}->{'tag'}->{'highway'} ) {
                if ( $NODES{$node_id}->{'tag'}->{'highway'} eq 'bus_stop' || $NODES{$node_id}->{'tag'}->{'highway'} eq 'platform' ) {
                    foreach my $way_id ( keys (  %{$NODES{$node_id}->{'member_of_way'}} ) ) {
                        if ( $WAYS{$way_id}->{'tag'} ) {
                            if ( ($WAYS{$way_id}->{'tag'}->{'highway'}          && $WAYS{$way_id}->{'tag'}->{'highway'}          eq 'platform') ||
                                 ($WAYS{$way_id}->{'tag'}->{'public_transport'} && $WAYS{$way_id}->{'tag'}->{'public_transport'} eq 'platform')    ) {
                                     $ret_val = "'highway' = " . $NODES{$node_id}->{'tag'}->{'highway'} . "'";
                            }
                        }
                    }
                }
            }
        }
    } else {
        # this node is a solitary node
        if ( !defined($vehicle_type)                    || 
              $vehicle_type eq 'bus'                    || 
             ($vehicle_type eq 'coach' && $allow_coach) || 
              $vehicle_type eq 'share_taxi'             || 
              $vehicle_type eq 'trolleybus'                ) {
            if ( $NODES{$node_id}->{'tag'} && $NODES{$node_id}->{'tag'}->{'highway'} ) {
                if ( $NODES{$node_id}->{'tag'}->{'highway'} eq 'bus_stop' || $NODES{$node_id}->{'tag'}->{'highway'} eq 'platform' ) {
                    $ret_val = "'highway' = " . $NODES{$node_id}->{'tag'}->{'highway'} . "'";
                }
            }
        }
    }
    
    return $ret_val;
}


#############################################################################################

sub isOneway {
    my $way_id          = shift;
    my $vehicle_type    = shift;        # optional !
    
    my $entry_node_id   = 0;
    
    if ( $way_id && $WAYS{$way_id} ) {
        if ( $vehicle_type ) {
            ; # todo
        } else {
            if ( ($WAYS{$way_id}->{'tag'}->{'oneway:bus'} && $WAYS{$way_id}->{'tag'}->{'oneway:bus'} eq 'no')            ||
                 ($WAYS{$way_id}->{'tag'}->{'oneway:psv'} && $WAYS{$way_id}->{'tag'}->{'oneway:psv'} eq 'no')            || 
                 ($WAYS{$way_id}->{'tag'}->{'busway'}     && $WAYS{$way_id}->{'tag'}->{'busway'}     eq 'opposite_lane')    ) {
                # bus may enter the road in either direction, return 0: don't care about entry point
                printf STDERR "isOneway() : no for bus/psv for Way %d\n", $way_id       if ( $debug );
                return 0;
            } elsif ( $WAYS{$way_id}->{'tag'}->{'oneway'} && $WAYS{$way_id}->{'tag'}->{'oneway'} eq 'yes' ) {
                $entry_node_id = $WAYS{$way_id}->{'first_node'};
                printf STDERR "isOneway() : yes for all for Way %d, entry at first Node %d\n", $way_id, $entry_node_id       if ( $debug );
                return $entry_node_id;
            } elsif ( $WAYS{$way_id}->{'tag'}->{'oneway'} && $WAYS{$way_id}->{'tag'}->{'oneway'} eq '-1'  ) {
                $entry_node_id = $WAYS{$way_id}->{'last_node'};
                printf STDERR "isOneway() : yes for all for Way %d, entry at last Node %d\n", $way_id, $entry_node_id       if ( $debug );
                return $entry_node_id;
            } elsif ( $WAYS{$way_id}->{'tag'}->{'junction'} && $WAYS{$way_id}->{'tag'}->{'junction'} eq 'roundabout' ) {
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
    my $ptv             = shift;        # optional !
    
    if ( $way_id && $WAYS{$way_id} && $WAYS{$way_id}->{'tag'} ) {
        my $way_tag_ref = $WAYS{$way_id}->{'tag'};

        if ( $way_tag_ref->{'psv'} && ($way_tag_ref->{'psv'} eq 'yes' || $way_tag_ref->{'psv'} eq 'designated' || $way_tag_ref->{'psv'} eq 'permissive' || $way_tag_ref->{'psv'} eq 'official') ) {
            #
            # fine for all public service vehicles
            #
            printf STDERR "noAccess() : access for all psv for way %d\n", $way_id       if ( $debug );
            return '';
        } elsif ( $vehicle_type && $way_tag_ref->{$vehicle_type} && 
                  ($way_tag_ref->{$vehicle_type} eq 'yes' || $way_tag_ref->{$vehicle_type} eq 'designated' || $way_tag_ref->{$vehicle_type} eq 'permissive' || $way_tag_ref->{$vehicle_type} eq 'official') ) {
            #
            # fine for this specific type of vehicle (bus, train, subway, ...) == @supported_route_types
            #
            printf STDERR "noAccess() : access for %s for way %d\n", $vehicle_type, $way_id       if ( $debug );
            return '';
        } elsif ( $vehicle_type && $vehicle_type eq 'ferry' && $way_tag_ref->{'route'} && ($way_tag_ref->{'route'} eq 'ferry' || $way_tag_ref->{'route'} eq 'boat') ) {
            #
            # fine for ferries on ferry ways
            #
            printf STDERR "noAccess() : access for %s for way %d\n", $vehicle_type, $way_id       if ( $debug );
            return '';
        } elsif ( $vehicle_type             && ($vehicle_type             eq 'tram' || $vehicle_type             eq 'train' || $vehicle_type             eq 'light_rail' || $vehicle_type             eq 'subway')                                        &&
                  $way_tag_ref->{'railway'} && ($way_tag_ref->{'railway'} eq 'tram' || $way_tag_ref->{'railway'} eq 'train' || $way_tag_ref->{'railway'} eq 'light_rail' || $way_tag_ref->{'railway'} eq 'subway' || $way_tag_ref->{'railway'} eq 'rail')    ) {
            #
            # fine for rail bounded vehivles rails
            #
            printf STDERR "noAccess() : access for %s for way %d railway=%s)\n", $vehicle_type, $way_id, $way_tag_ref->{'railway'}       if ( $debug );
            return '';
        } elsif ( (!defined($ptv) || $ptv ne '2') && $way_tag_ref->{'public_transport'} && $way_tag_ref->{'public_transport'} eq 'platform' ) {
            #
            # don't check for public_transport=platform (for PTv2 defined only) even if PTv2 is not defined or not '2'
            #
            printf STDERR "noAccess() : access for %s for way %d for non-PTv2 on Platforms\n", $vehicle_type, $way_id       if ( $debug );
            return '';
        } else {
            foreach my $access_restriction ( 'no', 'private' ) {
                foreach my $access_type ( 'access', 'vehicle', 'motor_vehicle', 'motor_car' ) {
                    if ( $way_tag_ref->{$access_type} && $way_tag_ref->{$access_type} eq $access_restriction ) {
                        printf STDERR "noAccess() : no access for way %d (%s=%s)\n", $way_id, $access_type, $access_restriction       if ( $debug );
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
                    } else {
                        printf STDERR "noAccess() : no access for way %d (%s=%s)\n", $way_id, 'highway', $highway_type       if ( $debug );
                        return 'highway=' . $highway_type;
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
# for syntx of 'name' with 'ref', 'from', 'to' and maybe 'via' included (also ref:*)
#
#############################################################################################

sub CheckNameRefFromViaToPTV2 {
    my $relation_ptr = shift;
    my $return_code  = 0;
    
    if ( $relation_ptr && $relation_ptr->{'tag'} ) {
        my $preconditions_failed = 0;
        my $name = $relation_ptr->{'tag'}->{'name'}; 
        my $ref  = $relation_ptr->{'tag'}->{'ref'}; 
        my $from = $relation_ptr->{'tag'}->{'from'}; 
        my $to   = $relation_ptr->{'tag'}->{'to'}; 
        my $via  = $relation_ptr->{'tag'}->{'via'};

        my $number_of_ref_colon_tags = 0;
        my $ref_string               = '';

        if ( $name ) {
            #
            # basic checks for 'name' w/o any other dependencies to 'ref', 'from', 'to' and 'via'
            #
            if ( $name =~ m/<=>/ ) {
                push( @{$relation_ptr->{'__notes__'}}, gettext("PTv2 route: 'name' includes deprecated '<=>'") );
                $preconditions_failed++;
                $return_code++;
            }
            if ( $name =~ m/==>/ ) {
                push( @{$relation_ptr->{'__notes__'}}, gettext("PTv2 route: 'name' includes deprecated '==>'") );
                $preconditions_failed++;
                $return_code++;
            }
        }

        if ( $name && $ref && $preconditions_failed == 0) {
#            if ( $from ) {
#                if ( !$check_name_relaxed ) {
#                    if ( index($name,$from) == -1 ) {
#                        push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("PTv2 route: 'from' = '%s' is not part of 'name'"), html_escape($from)) );
#                        $preconditions_failed++;
#                        $return_code++;
#                    }
#                }
#            }
#            if ( $to ) {
#                if ( !$check_name_relaxed ) {
#                    if ( index($name,$to) == -1 ) {
#                        push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("PTv2 route: 'to' = '%s' is not part of 'name'"), html_escape($to)) );
#                        $preconditions_failed++;
#                        $return_code++;
#                    }
#                }
#            }
            
            if ( $name =~ m/^(.*):\s{0,1}(.*?)\s{0,1}=>\s{0,1}(.*)\s{0,1}=>\s{0,1}(.*)$/ ||
                 $name =~ m/^(.*):\s{0,1}(.*?)\s{0,1}=>\s{0,1}(.*)$/                         ) {
                
                my $ref_in_name       = $1;
                my $from_in_name      = $2;
                my $vias_in_name      = $3;
                my $to_in_name        = $4;
                my @via_parts_in_name = ();
                
                if ( $to_in_name) {
                    @via_parts_in_name = split( '=>', $vias_in_name );
                    foreach ( @via_parts_in_name ) {
                       s/^\s*//;
                       s/\s*$//;
                    }
                } else {
                    $to_in_name        = $vias_in_name;
                    $vias_in_name      = undef;
                    @via_parts_in_name = ();
                }

                if ( index($ref_in_name,$ref) == -1 ) {
                    #
                    # this will check only combinations of verious ref's: ref='025/9567/11'
                    #                                                     name='Bus LAVV 025/RVO 9567/VLK 11 .....'
                    #                                                     ref:LAV='025'
                    #                                                     ref:RVO='9567'
                    #                                                     ref:VLK='11'
                    foreach my $tag ( sort ( keys ( %{$relation_ptr->{'tag'}} ) ) ) {
                        if ( $tag =~ m/^ref:(\S+)$/ ) {
                            $number_of_ref_colon_tags++;
                            $ref_string = $1 . ' ' . $relation_ptr->{'tag'}->{$tag};
                            if ( index($ref_in_name,$ref_string) == -1 ) {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("PTv2 route: '%s' is not part of 'name' (derived from '%s' = '%s')"),html_escape($ref_string),html_escape($tag),html_escape($relation_ptr->{'tag'}->{$tag})) );
                                $return_code++;
                            }
                        }
                    }
                    if ( $number_of_ref_colon_tags == 0 ) {     # there are no 'ref:*' tags, so check 'ref' being present in 'name'
                        push( @{$relation_ptr->{'__notes__'}}, gettext("PTv2 route: 'ref' is not part of 'name'") );
                        $return_code++;
                    }
                }

                if ( $from ) {
                    if ( $from_in_name ne $from ) {
                        if ( $check_name_relaxed ) {
                            if ( index($from,$from_in_name) == -1 ) {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("PTv2 route: from-part ('%s') of 'name' is not part of 'from' = '%s'"), html_escape($from_in_name), html_escape($from)) );
                                $return_code++;
                            }
                        } else {
                            push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("PTv2 route: 'from' = '%s' is not part of 'name'"), html_escape($from)) );
                            $return_code++;
                        }
                    }
                } else {
                    push( @{$relation_ptr->{'__notes__'}}, gettext("PTv2 route: 'from' is not set") );
                    $return_code++;
                }

                if ( $to ) {
                    if ( $to_in_name ne $to ) {
                        if ( $check_name_relaxed ) {
                            if ( index($to,$to_in_name) == -1 ) {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("PTv2 route: to-part ('%s') of 'name' is not part of 'to' = '%s'"), html_escape($to_in_name), html_escape($to)) );
                                $return_code++;
                            }
                        } else {
                            push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("PTv2 route: 'to' = '%s' is not part of 'name'"), html_escape($to)) );
                            $return_code++;
                        }
                    }
                } else {
                    push( @{$relation_ptr->{'__notes__'}}, gettext("PTv2 route: 'to' is not set") );
                    $return_code++;
                }

                if ( scalar(@via_parts_in_name) ) {
                    if ( $via ) {
                        my @via_values  = split( ";", $via );
                        
                        if ( !$check_name_relaxed ) {
                            if ( scalar(@via_parts_in_name) == scalar(@via_values) ) {
                                for ( my $index = 0; $index < scalar(@via_parts_in_name); $index++ ) {
                                    if ( $via_parts_in_name[$index] ne $via_values[$index] ) {
                                        push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("PTv2 route: 'via' is set: %d. via-value = '%s' is not equal to %d. via-part = '%s' of 'name'"),$index+1,html_escape($via_values[$index]),$index+1,html_escape($via_parts_in_name[$index])) );
                                        $return_code++;
                                    }
                                }
                            } elsif ( scalar(@via_parts_in_name) > scalar(@via_values) ) {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("PTv2 route: there are more via-parts in 'name' (%d) than in 'via' (%d) "),scalar(@via_parts_in_name),scalar(@via_values)) );
                                $return_code++;
                            } else {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("PTv2 route: there are less via-parts in 'name' (%d) than in 'via' (%d) "),scalar(@via_parts_in_name),scalar(@via_values)) );
                                $return_code++;
                            }
                        }
                    } else {
                        push( @{$relation_ptr->{'__notes__'}}, gettext("PTv2 route: 'name' has more than one '=>' but 'via' is not set") );
                        $return_code++;
                    }
                }
            } else {
                if ( $check_name_relaxed ) {
                    push( @{$relation_ptr->{'__notes__'}}, gettext("PTv2 route: 'name' should be similar to the form '... ref ...: from => to'") );
                } else {
                    push( @{$relation_ptr->{'__notes__'}}, gettext("PTv2 route: 'name' should (at least) be of the form '... ref ...: from => to'") );
                }
                $return_code++;
            }
        } else {
            if ( !$name ) {
                # already checked at a very early position, but must increase return_code here
                #push( @{$relation_ptr->{'__issues__'}}, gettext("'name' is not set") );
                $return_code++;
            }
            if ( !$ref ) {
                # already checked at a very early position, but must increase return_code here
                #push( @{$relation_ptr->{'__issues__'}}, gettext("'ref' is not set") );
                $return_code++;
            }
        }
    }
    
    return $return_code;
}


#############################################################################################
#
# for WAYS used by vehicles     vehicles must have access permission
#
#############################################################################################

sub CheckAccessOnWays {
    my $relation_ptr = shift;
    my $ret_val      = 0;

    if ( $relation_ptr ) {
        my $access_restriction  = undef;
        my %restricted_access   = ();

        foreach my $route_highway ( @{$relation_ptr->{'route_highway'}} ) {
            $access_restriction = noAccess( $route_highway->{'ref'}, $relation_ptr->{'tag'}->{'route'}, $relation_ptr->{'tag'}->{'public_transport:version'}  );
            if ( $access_restriction ) {
                $restricted_access{$access_restriction}->{$route_highway->{'ref'}} = 1;
                $ret_val++;
            }
        }
        if ( %restricted_access ) {
            my $helpstring = '';
            foreach $access_restriction ( sort(keys(%restricted_access)) ) {
                $helpstring = ngettext( "Route: restricted access (%s) to way without 'psv'='yes', '%s'='yes', '%s'='designated', or ...: %s",
                                        "Route: restricted access (%s) to ways without 'psv'='yes', '%s'='yes', '%s'='designated', or ...: %s", scalar(keys(%{$restricted_access{$access_restriction}})) );
                push( @{$relation_ptr->{'__issues__'}}, sprintf( $helpstring, $access_restriction, $relation_ptr->{'tag'}->{'route'}, $relation_ptr->{'tag'}->{'route'}, join(', ', map { printWayTemplate($_,'name;ref'); } sort(keys(%{$restricted_access{$access_restriction}})))) );
            }
        }
    }
}

#############################################################################################
#
# all WAYS          must not have "highway" = "bus_stop" set - allowed only on nodes
# all RELATIONS     must not have "highway" = "bus_stop" set - allowed only on nodes
#
#############################################################################################

sub CheckBusStopOnWaysAndRelations {
    my $relation_ptr = shift;
    my $ret_val      = 0;
    
    if ( $relation_ptr ) {
        my %bus_stop_ways = ();
        
        foreach my $highway_ref ( @{$relation_ptr->{'way'}} ) {
            if ( $WAYS{$highway_ref->{'ref'}}->{'tag'}->{'highway'} && $WAYS{$highway_ref->{'ref'}}->{'tag'}->{'highway'} eq 'bus_stop' ) {
                $bus_stop_ways{$highway_ref->{'ref'}} = 1;
            }
        }
        if ( %bus_stop_ways ) {
            my @help_array     = sort(keys(%bus_stop_ways));
            my $num_of_errors  = scalar(@help_array);
               $ret_val       += $num_of_errors;
            my $error_string   = ngettext( "Route: 'highway' = 'bus_stop' is set on way. Allowed on nodes only!",
                                           "Route: 'highway' = 'bus_stop' is set on ways. Allowed on nodes only!", $num_of_errors);
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $error_string, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $error_string, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
            }
        }
    }
    
    return $ret_val;
}


#############################################################################################
#
# check the 'route_ref' tag on all highway=bus_stop or all public_transport=platform members of this route to have 'ref' of this route included
# check for tags 'bus_lines', 'bus_routes, 'lines', 'line' and 'routes' on stops and propose converting them to 'route_ref'
#
#############################################################################################

sub CheckRouteRefOnStops {
    my $relation_ptr = shift;
    my $ret_val      = 0;
    
    if ( $relation_ptr ) {
        if ( $relation_ptr->{'tag'} && $relation_ptr->{'tag'}->{'ref'} ) {
            my $ref                     = $relation_ptr->{'tag'}->{'ref'};
            my $object_ref              = undef;
            my $platform_or_stop        = undef;
            my $temp_route_ref          = undef;
            my $temp_stop_ref           = undef;
            my $num_of_errors           = undef;
            my $hint                    = undef;
            my $replace_by              = undef;
            my %not_set_on              = ();
            my %separator_with_blank_on = ();
            my %comma_as_separator      = ();
            my %to_be_replaced          = ();
            my %to_be_deleted           = ();
            my %included_refs           = ();
            my @help_array              = ();
    
            foreach $member ( @{$relation_ptr->{'members'}} ) {
                if ( $member->{'ref'} && $member->{'type'} ) {
                    if ( $member->{'type'} eq 'node' ) {
                        $object_ref = $NODES{$member->{'ref'}};
                    } elsif ( $member->{'type'} eq 'way' ) {
                        $object_ref = $WAYS{$member->{'ref'}};
                    } elsif ( $member->{'type'} eq 'relation' ) {
                        $object_ref = $RELATIONS{$member->{'ref'}};
                    } else {
                        $object_ref = undef;
                    }
                    if ( $object_ref && $object_ref->{'tag'} ) {
                        if ( $object_ref->{'tag'}->{'public_transport'} && $object_ref->{'tag'}->{'public_transport'} eq 'platform' ) {
                            $platform_or_stop = "'public_transport' = 'platform'";
                        } elsif ( $object_ref->{'tag'}->{'highway'} && $object_ref->{'tag'}->{'highway'} eq 'bus_stop') {
                            $platform_or_stop = "'highway' = 'bus_stop'";
                        } elsif ( $object_ref->{'tag'}->{'public_transport'} && $object_ref->{'tag'}->{'public_transport'} eq 'stop_position') {
                            $platform_or_stop = "'public_transport' = 'stop_position'";
                        } else {
                            $platform_or_stop = undef;
                        }
                        if ( $platform_or_stop ) {
                            if ( $object_ref->{'tag'}->{'route_ref'} ) {
                                $temp_route_ref =  ';' . $object_ref->{'tag'}->{'route_ref'} . ';';
                                $temp_route_ref =~ s/\s*;\s*/;/g;

                                foreach my $sub_ref ( split( $ref_separator, $ref ) ) {
                                    if ( $temp_route_ref =~ m/;\Q$sub_ref\E;/ ) {
                                        ; # fine
                                    } else {
                                        $hint = '';
                                        if ( $object_ref->{'tag'}->{'route_ref'} =~ m/,/ ) {
                                            $hint = ' (' . gettext("separate multiple values by ';' (semi-colon) without blank") . ')';
                                        }
                                        $not_set_on{sprintf(gettext("'route_ref' = '%s' of stop does not include 'ref' = '%s' value of this route%s"),html_escape($object_ref->{'tag'}->{'route_ref'}),html_escape($sub_ref),$hint)}->{$member->{'ref'}} = $member->{'type'};
                                    }
                                }
    
                                if ( $check_osm_separator ) {
                                    if ( $object_ref->{'tag'}->{'route_ref'} =~ m/\s+;/ ||
                                         $object_ref->{'tag'}->{'route_ref'} =~ m/;\s+/    ) {
                                        $separator_with_blank_on{sprintf(gettext("'route_ref' = '%s' of stop includes the separator value ';' (semi-colon) with sourrounding blank"),html_escape($object_ref->{'tag'}->{'route_ref'}))}->{$member->{'ref'}} = $member->{'type'};
                                    }
                                    if ( $object_ref->{'tag'}->{'route_ref'} =~ m/,/ ) {
                                        $comma_as_separator{sprintf(gettext("'route_ref' = '%s' of stop: ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank"),html_escape($object_ref->{'tag'}->{'route_ref'}))}->{$member->{'ref'}} = $member->{'type'};
                                    }
                                }

                                foreach my $tag ( 'bus_lines', 'bus_routes', 'lines', 'routes', 'line' ) {
                                    if ( $object_ref->{'tag'}->{$tag} ) {
                                        $to_be_deleted{sprintf(gettext("'%s' = '%s' of stop should be deleted, 'route_ref' = '%s' exists"),$tag,html_escape($object_ref->{'tag'}->{$tag}),html_escape($object_ref->{'tag'}->{'route_ref'}))}->{$member->{'ref'}} = $member->{'type'};
                                    }
                                }
                                if ( $object_ref->{'tag'}->{'ref'} ) {
                                    $temp_stop_ref =  ';' . $object_ref->{'tag'}->{'ref'} . ';';
                                    $temp_stop_ref =~ s/\s*;\s*/;/g;
    
                                    foreach my $sub_ref ( split( $ref_separator, $ref ) ) {
                                        if ( $temp_stop_ref =~ m/;\Q$sub_ref\E;/ ) {
                                            $hint = sprintf( gettext( "(consider adding '%s' to the 'route_ref' tag of the stop)" ), html_escape($sub_ref) );
                                            $to_be_replaced{sprintf(gettext("'ref' = '%s' of stop should represent the reference of the stop, but includes the 'ref' ='%s' of this route %s"),html_escape($object_ref->{'tag'}->{'ref'}),html_escape($sub_ref),$hint)}->{$member->{'ref'}} = $member->{'type'};
                                        }
                                    }
                                }
                            } else {
                                foreach my $tag ( 'bus_lines', 'bus_routes', 'lines', 'routes', 'line' ) {
                                    if ( $object_ref->{'tag'}->{$tag} ) {
                                        $replace_by     =  $object_ref->{'tag'}->{$tag};
                                        $replace_by     =~ s/\s*[;,]\s*/;/g;
                                        %included_refs  =  ();
                                        foreach my $set_ref ( split( ';', $replace_by ) ) {
                                            $included_refs{$set_ref} = 1;
                                        }
                                        foreach my $sub_ref ( split( $ref_separator, $ref ) ) {
                                            $included_refs{$sub_ref} = 1;
                                        }
                                        delete( $included_refs{'yes'} );
                                        $replace_by = join( ';', sort( { if ( $a =~ m/^[0-9]+$/ && $b =~ m/^[0-9]+$/ ) { $a <=> $b } else { $a cmp $b } } keys( %included_refs ) ) );
                                        $to_be_replaced{sprintf(gettext("'%s' = '%s' of stop should be replaced by 'route_ref' = '%s'"),$tag,html_escape($object_ref->{'tag'}->{$tag}),html_escape($replace_by))}->{$member->{'ref'}} = $member->{'type'};
                                    }
                                }
                                if ( $object_ref->{'tag'}->{'ref'} ) {
                                    $temp_stop_ref =  ';' . $object_ref->{'tag'}->{'ref'} . ';';
                                    $temp_stop_ref =~ s/\s*;\s*/;/g;
    
                                    foreach my $sub_ref ( split( $ref_separator, $ref ) ) {
                                        if ( $temp_stop_ref =~ m/;\Q$sub_ref\E;/ ) {
                                            $hint = sprintf( gettext( "(consider creating a 'route_ref' = '%s' tag for the stop)" ), html_escape($sub_ref) );
                                            $to_be_replaced{sprintf(gettext("'ref' = '%s' of stop should represent the reference of the stop, but includes the 'ref' ='%s' of this route %s"),html_escape($object_ref->{'tag'}->{'ref'}),html_escape($sub_ref),$hint)}->{$member->{'ref'}} = $member->{'type'};
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            foreach my $message ( sort( keys( %not_set_on ) ) ) {
                @help_array     = sort( keys( %{$not_set_on{$message}} ) );
                $num_of_errors  = scalar( @help_array );
                $ret_val       += $num_of_errors;
                if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route: %s: %s and %d more ..."), $message, join(', ', map { printXxxTemplate($not_set_on{$message}->{$_},$_,'name'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route: %s: %s"), $message, join(', ', map { printXxxTemplate($not_set_on{$message}->{$_},$_,'name'); } @help_array )) );
                }
            }
            foreach my $message ( sort( keys( %separator_with_blank_on ) ) ) {
                @help_array     = sort( keys( %{$separator_with_blank_on{$message}} ) );
                $num_of_errors  = scalar( @help_array );
                $ret_val       += $num_of_errors;
                if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route: %s: %s and %d more ..."), $message, join(', ', map { printXxxTemplate($separator_with_blank_on{$message}->{$_},$_,'name'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route: %s: %s"), $message, join(', ', map { printXxxTemplate($separator_with_blank_on{$message}->{$_},$_,'name'); } @help_array )) );
                }
            }
            foreach my $message ( sort( keys( %comma_as_separator ) ) ) {
                @help_array     = sort( keys( %{$comma_as_separator{$message}} ) );
                $num_of_errors  = scalar( @help_array );
                $ret_val       += $num_of_errors;
                if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route: %s: %s and %d more ..."), $message, join(', ', map { printXxxTemplate($comma_as_separator{$message}->{$_},$_,'name'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("Route: %s: %s"), $message, join(', ', map { printXxxTemplate($comma_as_separator{$message}->{$_},$_,'name'); } @help_array )) );
                }
            }
            foreach my $message ( sort( keys( %to_be_replaced ) ) ) {
                @help_array     = sort( keys( %{$to_be_replaced{$message}} ) );
                $num_of_errors  = scalar( @help_array );
                $ret_val       += $num_of_errors;
                if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("Route: %s: %s and %d more ..."), $message, join(', ', map { printXxxTemplate($to_be_replaced{$message}->{$_},$_,'name'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("Route: %s: %s"), $message, join(', ', map { printXxxTemplate($to_be_replaced{$message}->{$_},$_,'name'); } @help_array )) );
                }
            }
            foreach my $message ( sort( keys( %to_be_deleted ) ) ) {
                @help_array     = sort( keys( %{$to_be_deleted{$message}} ) );
                $num_of_errors  = scalar( @help_array );
                $ret_val       += $num_of_errors;
                if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("Route: %s: %s and %d more ..."), $message, join(', ', map { printXxxTemplate($to_be_deleted{$message}->{$_},$_,'name'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("Route: %s: %s"), $message, join(', ', map { printXxxTemplate($to_be_deleted{$message}->{$_},$_,'name'); } @help_array )) );
                }
            }
        }
    }
    
    return $ret_val;
}


#############################################################################################
#
# for all WAYS  check for completeness of data
# for all NODES  check for completeness of data
#
#############################################################################################

sub CheckCompletenessOfData {
    my $relation_ptr = shift;
    my $ret_val      = 0;
    
    #
    # for all WAYS  check for completeness of data
    #
    if ( $xml_has_ways ) {
        my %incomplete_data_for_ways   = ();
        foreach my $highway_ref ( @{$relation_ptr->{'way'}} ) {
            if ( $WAYS{$highway_ref->{'ref'}} ) {
                # way exists in downloaded data
                # check for more
                $incomplete_data_for_ways{$highway_ref->{'ref'}} = 1    if ( !$WAYS{$highway_ref->{'ref'}}->{'tag'} );
                $incomplete_data_for_ways{$highway_ref->{'ref'}} = 1    if ( !$WAYS{$highway_ref->{'ref'}}->{'chain'} || scalar @{$WAYS{$highway_ref->{'ref'}}->{'chain'}} == 0 );
            } else {
                $incomplete_data_for_ways{$highway_ref->{'ref'}} = 1;
            }
        }
        if ( keys(%incomplete_data_for_ways) ) {
            my @help_array     = sort(keys(%incomplete_data_for_ways));
            my $num_of_errors  = scalar(@help_array);
               $ret_val       += $num_of_errors;
            my $error_string   = gettext("Error in input data: insufficient data for ways");
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $error_string, join(', ', map { printWayTemplate($_); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $error_string, join(', ', map { printWayTemplate($_); } @help_array )) );
            }
            $relation_ptr->{'missing_way_data'}   = 1;
            printf STDERR "%s Error in input data: insufficient data for ways of route ref=%s\n", get_time(), ( $relation_ptr->{'tag'}->{'ref'} ? $relation_ptr->{'tag'}->{'ref'} : 'no ref' );
        }
    }
    #
    # for all NODES  check for completeness of data
    #
    if ( $xml_has_nodes ) {
        my %incomplete_data_for_nodes   = ();
        foreach my $node_ref ( @{$relation_ptr->{'node'}} ) {
            if ( $NODES{$node_ref->{'ref'}} ) {
                # node exists in downloaded data
                # check for more
                # $incomplete_data_for_nodes{$node_ref->{'ref'}} = 1    if ( !$NODES{$node_ref->{'ref'}}->{'tag'} );
            } else {
                $incomplete_data_for_nodes{$node_ref->{'ref'}} = 1;
            }
        }
        if ( keys(%incomplete_data_for_nodes) ) {
            my @help_array     = sort(keys(%incomplete_data_for_nodes));
            my $num_of_errors  = scalar(@help_array);
               $ret_val       += $num_of_errors;
            my $error_string   = gettext("Error in input data: insufficient data for nodes");
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $error_string, join(', ', map { printWayTemplate($_); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $error_string, join(', ', map { printWayTemplate($_); } @help_array )) );
            }
            $relation_ptr->{'missing_node_data'}   = 1;
            printf STDERR "%s Error in input data: insufficient data for nodes of route ref=%s\n", get_time(), ( $relation_ptr->{'tag'}->{'ref'} ? $relation_ptr->{'tag'}->{'ref'} : 'no ref' );
        }
    }
    
    return $ret_val;
}


#############################################################################################
#
# functions for printing HTML code
#
#############################################################################################

my $no_of_columns               = 0;
my @columns                     = ();
my @table_columns               = ();
my @html_header_anchors         = ();
my @html_header_anchor_numbers  = (0,0,0,0,0,0,0);
my $printText_buffer            = '';
    


sub printInitialHeader {
    my $title       = shift;
    my $osm_base    = shift;
    my $areas       = shift;
    
    $no_of_columns               = 0;
    @columns                     = ();
    @table_columns               = ();

    push( @HTML_start, "<!DOCTYPE html>\n" );
    push( @HTML_start, "<html lang=\"de\">\n" );
    push( @HTML_start, "    <head>\n" );
    push( @HTML_start, sprintf( "        <title>%sPTNA - Public Transport Network Analysis</title>\n", ($title ? html_escape($title) . ' - ' : '') ) );
    push( @HTML_start, "        <meta charset=\"utf-8\" />\n" );
    push( @HTML_start, "        <meta name=\"generator\" content=\"PTNA\">\n" );
    push( @HTML_start, "        <meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\" />\n" );
    push( @HTML_start, "        <meta name=\"keywords\" content=\"OSM Public Transport PTv2\">\n" );
    push( @HTML_start, "        <meta name=\"description\" content=\"PTNA - Public Transport Network Analysis\">\n" );
    push( @HTML_start, "        <style>\n" );
    push( @HTML_start, "              table { border-width: 1px; border-style: solid; border-collapse: collapse; vertical-align: center; }\n" );
    push( @HTML_start, "              th    { border-width: 1px; border-style: solid; border-collapse: collapse; padding: 0.2em; }\n" );
    push( @HTML_start, "              td    { border-width: 1px; border-style: solid; border-collapse: collapse; padding: 0.2em; }\n" );
    push( @HTML_start, "              img   { width: 20px; }\n" );
    push( @HTML_start, "              #toc ol           { list-style: none; }\n" );
    push( @HTML_start, "              .tableheaderrow   { background-color: LightSteelBlue;   }\n" );
    push( @HTML_start, "              .sketchline       { background-color: LightBlue;        }\n" );
    push( @HTML_start, "              .sketch           { text-align:left;  font-weight: 500; }\n" );
    push( @HTML_start, "              .csvinfo          { text-align:right; font-size: 0.8em; }\n" );
    push( @HTML_start, "              .ref              { white-space:nowrap; }\n" );
    push( @HTML_start, "              .relation         { white-space:nowrap; }\n" );
    push( @HTML_start, "              .PTv              { text-align:center; }\n" );
    push( @HTML_start, "              .number           { text-align:right; }\n" );
    push( @HTML_start, "              .attention        { background-color: yellow; font-weight: 500; font-size: 1.2em; }\n" );
    push( @HTML_start, "        </style>\n" );
    push( @HTML_start, "    </head>\n" );
    push( @HTML_start, "    <body>\n" );
    if ( $osm_base || $areas ) {
        printHeader( gettext("Date of Data"), 1, 'dates' );
        push( @HTML_main, sprintf( "%8s<p>\n", ' ') );
        push( @HTML_main, sprintf( "%12sOSM-Base Time : %s\n", ' ', $osm_base ) )       if ( $osm_base );
        push( @HTML_main, sprintf( "%12s<br>\n",               ' ' ) )                  if ( $osm_base && $areas );
        push( @HTML_main, sprintf( "%12sAreas Time    : %s\n", ' ', $areas ) )          if ( $areas    );
        push( @HTML_main, sprintf( "%8s</p>\n", ' ') );
        push( @HTML_main, "\n" );
    } else {
        printHeader( gettext("Hints"), 1, 'hints' );
    }
    push( @HTML_main, "<p>\n    " );
    push( @HTML_main, gettext("The data will be updated when the result of the analysis has changed.") );
    push( @HTML_main, "\n</p>\n" );
    push( @HTML_main, "<p>\n    " );
    push( @HTML_main, gettext("An explanation of the error texts can be found in the documentation at <a href='/documentation.html#checks'>'Check'</a>.") );
    push( @HTML_main, "\n</p>\n" );

}


#############################################################################################

sub printFinalFooter {

    push( @HTML_main, "    </body>\n" );
    push( @HTML_main, "</html>\n" );
    
    foreach my $line ( @HTML_start ) {
        print $line;
    }

    printTableOfContents();

    foreach my $line ( @HTML_main ) {
        print $line;
    }
}


#############################################################################################

sub printTableOfContents {
    
    my $toc_line        = undef;
    my $last_level      = 0;
    my $anchor_level    = undef;
    my $header_number   = undef;
    my $label           = undef;
    my $header_text     = undef;

    print "        <div id=\"toc\">\n";
    print "        <h1>";
    print gettext("Contents");
    printf "</h1>\n";
    foreach $toc_line ( @html_header_anchors ) {
        if ( $toc_line =~ m/^A(\d+)\s+N([0-9\.]+)\s+L([^ ]+)\s+T(.*)$/ ) {
            $anchor_level   = $1;
            $header_number  = $2;
            $label          = $3;
            $header_text    = wiki2html($4);
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
            printf "        <li>%s <a href=\"#%s\">%s</a>\n", $header_number, $label, $header_text;
        } else {
            printf STDERR "%s Missmatch in TOC line '%s'\n", get_time(), $toc_line;
        }
    }
    while ( $last_level > 0) {
        print "        </li>\n        </ol>\n";
        $last_level--;
    }
    print "        </div> <!-- toc -->\n";
}


#############################################################################################

sub printHintUnassignedRelations {
    push( @HTML_main, "<p>\n" );
    push( @HTML_main, "Dieser Abschnitt listet die Linien auf, die nicht eindeutig zugeordnet werden konnten. " );
    push( @HTML_main, "Die Liniennummern 'ref' sind in der CSV-Datei mehrfach angegeben worden. " );
    push( @HTML_main, "Das bedeutet, dass die selbe Liniennummer im Verkehrsverbund mehrfach in verscheidenen Gemeinden/Städten vorhanden ist. " );
    push( @HTML_main, "Um die Linien eindeutig zuordnen zu können sollte folgendes angegeben werden:\n" );
    push( @HTML_main, "</p>" );
    push( @HTML_main, "<ul>\n" );
    push( @HTML_main, "    <li>Relation:\n" );
    push( @HTML_main, "        <ul>\n" );
    push( @HTML_main, "            <li>'network', 'operator', sowie 'from' und 'to' sollten bei der Relation getagged sein.\n" );
    push( @HTML_main, "                <ul>\n" );
    push( @HTML_main, "                    <li>Wenn der Wert von 'operator' zur Differenzierung eindeutig ist, müssen 'from' und 'to' nicht angegeben werden.</li>\n" );
    push( @HTML_main, "                </ul>\n" );
    push( @HTML_main, "            </li>\n" );
    push( @HTML_main, "        </ul>\n" );
    push( @HTML_main, "    </li>\n" );
    push( @HTML_main, "    <li>CSV-Datei:\n" );
    push( @HTML_main, "        <ul>\n" );
    push( @HTML_main, "            <li>'Betreiber', sowie 'Von' und 'Nach' sollten in der CSV-Datei mit den selben Werten wie bei der Relation angegeben werden.\n" );
    push( @HTML_main, "                <ul>\n" );
    push( @HTML_main, "                    <li>Siehe hierzu die Anleitung für solche Einträge am Anfang der CSV-Datei.</li>\n" );
    push( @HTML_main, "                </ul>\n" );
    push( @HTML_main, "            </li>\n" );
    push( @HTML_main, "        </ul>\n" );
    push( @HTML_main, "    </li>\n" );
    push( @HTML_main, "</ul>\n" );
    push( @HTML_main, "<p>\n" );
    push( @HTML_main, "Beispiele aus dem VMS für einen Eintrag in der CSV-Datei der Form: 'ref;type;Kommentar;Von;Nach;Betreiber':\n" );
    push( @HTML_main, "</p>\n" );
    push( @HTML_main, "<table>\n" );
    push( @HTML_main, "    <thead class=\"tableheaderrow\">\n" );
    push( @HTML_main, "        <tr><th>&nbsp;</th><th>ref</th><th>type</th><th>Kommentar</th><th>Von</th><th>Nach</th><th>Betreiber</th></tr>\n" );
    push( @HTML_main, "    </thead>\n" );
    push( @HTML_main, "    <tbody>\n" );
    push( @HTML_main, "        <tr><td><strong>1.)</strong> </td><td>A</td><td>bus</td><td>Bus A fährt in Annaberg-Buchholz</td><td>Barbara-Uthmann-Ring</td><td>Buchholz</td><td>RVE</td></tr>\n" );
    push( @HTML_main, "        <tr><td><strong>2.)</strong> </td><td>A</td><td>bus</td><td>Bus A fährt in Aue</td><td>Postplatz</td><td>Postplatz</td><td>RVE</td></tr>\n" );
    push( @HTML_main, "        <tr><td><strong>3.)</strong> </td><td>A</td><td>bus</td><td>Bus A fährt in Burgstädt</td><td>Sportzentrum</td><td>Heiersdorf</td><td>RBM</td></tr>\n" );
    push( @HTML_main, "    </tbody>\n" );
    push( @HTML_main, "</table>\n" );
    push( @HTML_main, "<p>\n" );
    push( @HTML_main, "   1.) und 2.) sind nur mit Hilfe von 'Von'/'from' und 'Nach'/'to' unterscheidbar, da 'Betreiber'/'operator' identisch (='RVE') sind.<br>\n" );
    push( @HTML_main, "   1.) und 3.) sowie 2.) und 3.) sind an Hand von 'Betreiber'/'operator' unterscheidbar, da diese unterschiedlich sind (='RVE' bzw. ='RBM').\n" );
    push( @HTML_main, "</p>\n" );

}


#############################################################################################

sub printHintSuspiciousRelations {
    my $hswkort = scalar( keys ( %have_seen_well_known_other_route_types ) );
    my $hswknt  = scalar( keys ( %have_seen_well_known_network_types ) );
    my $hswkot  = scalar( keys ( %have_seen_well_known_other_types ) );

    push( @HTML_main, "<p>\n" );
    push( @HTML_main, gettext("This section lists further relations of the environment of the routes:") );
    push( @HTML_main, "\n</p>\n" );
    push( @HTML_main, "<ul>\n    <li>" );
    push( @HTML_main, gettext("potentially wrong 'route' or 'route_master' values?") );
    push( @HTML_main, "\n        <ul>\n        <li>" );
    push( @HTML_main, gettext("e.g. 'route' = 'suspended_bus' instead of 'route' = 'bus'") );
    push( @HTML_main, "</li>\n        </ul>\n" );
    push( @HTML_main, "    </li>\n    <li>" );
    push( @HTML_main, gettext("but also 'type' = 'network', 'type' = 'set' or 'route' = 'network', i.e. a collection of all routes and route-masters belonging to the 'network'.") );
    push( @HTML_main, "\n        <ul>\n            <li>" );
    push( @HTML_main, gettext("such <strong>collections are strictly spoken errors</strong>, since relations shall not represent collections:") );
    push( @HTML_main, gettext(" <a href=\"https://wiki.openstreetmap.org/wiki/Relations/Relations_are_not_Categories\">Relations/Relations are not Categories</a>") );
    push( @HTML_main, "</li>\n        </ul>\n" );
    push( @HTML_main, "    </li>\n" );
    push( @HTML_main, "</ul>\n" );
    if ( $hswkort || $hswknt || $hswkot ) {
        push( @HTML_main, "<p>\n" );
        push( @HTML_main, gettext("The following values and combinations have been found in the provided data but they will not be listed here. ") );
        push( @HTML_main, gettext("They represent so called 'well defined' values and are not considered as errors.") );
        push( @HTML_main, "\n</p>\n" );
        push( @HTML_main, "<ul>\n" );
        if ( $hswkort ) {
            push( @HTML_main, "    <li>'type' = 'route_master', 'type' = 'route''\n" );
            push( @HTML_main, "        <ul>\n" );
            foreach my $rt (  sort ( keys %have_seen_well_known_other_route_types ) ) {
                push( @HTML_main, sprintf( "    <li>'route_master' = '%s', 'route' = '%s'</li>\n", $rt, $rt ) );
            }
            push( @HTML_main, "        </ul>\n" );
            push( @HTML_main, "    </li>\n" );
        }
        if ( $hswknt ) {
            push( @HTML_main, "    <li>'type' = 'network'\n" );
            push( @HTML_main, "        <ul>\n" );
            foreach my $nt (  sort ( keys %have_seen_well_known_network_types ) ) {
                push( @HTML_main, sprintf( "    <li>'network' = '%s'</li>\n", $nt ) );
            }
            push( @HTML_main, "        </ul>\n" );
            push( @HTML_main, "    </li>\n" );
        }
        if ( $hswkot ) {
            foreach my $ot ( sort ( keys %have_seen_well_known_other_types ) ) {
                push( @HTML_main, sprintf( "    <li>'type' = '%s'</li>\n", $ot ) );
            }
        }
        push( @HTML_main, "</ul>\n" );
    }
    push( @HTML_main, "\n" );

}


#############################################################################################

sub printHintNetworks {

    push( @HTML_main, "<p>\n" );
    push( @HTML_main, gettext("The contents of the 'network' tag will be searched for:") );
    push( @HTML_main, "\n</p>\n" );

    if ( $network_long_regex || $network_short_regex ) {
        push( @HTML_main, "<ul>\n" );
        if ( $network_long_regex ) {
            foreach my $nw ( split( '\|', $network_long_regex ) ) {
                push( @HTML_main, sprintf( "    <li>%s</li>\n", html_escape($nw) ) );
            }
        }
        if ( $network_short_regex ) {
            foreach my $nw ( split( '\|', $network_short_regex ) ) {
                push( @HTML_main, sprintf( "    <li>%s</li>\n", html_escape($nw) ) );
            }
        }
        if ( !$strict_network ) {
            push( @HTML_main, sprintf( "    <li>%s</li>\n", gettext("'network' is not set") ) );
        }
        push( @HTML_main, "</ul>\n" );
    }

    if ( $operator_regex ) {
        push( @HTML_main, "<p>\n" );
        push( @HTML_main, gettext("The contents of the 'operator' tag will be searched for:") );
        push( @HTML_main, "\n</p>\n" );

        push( @HTML_main, "<ul>\n" );
        if ( $operator_regex ) {
            foreach my $nw ( split( '\|', $operator_regex ) ) {
                push( @HTML_main, sprintf( "    <li>%s</li>\n", html_escape($nw) ) );
            }
        }
        if ( !$strict_operator ) {
            push( @HTML_main, sprintf( "    <li>%s</li>\n", gettext("'operator' is not set") ) );
        }
        push( @HTML_main, "</ul>\n" );
    }
}
    

#############################################################################################

sub printHintUsedNetworks {

    my @relations_of_network  = ();
    my @relations_of_operator = ();
    
    printHeader( gettext("Considered 'network'-Values"), 2, 'considerednetworks' );
    
    push( @HTML_main, "<p>\n" );
    push( @HTML_main, gettext("This section lists the 'network'-values which have been considered; i.e. which match to one of the values above.") );
    push( @HTML_main, "\n</p>\n" );

    printTableInitialization( 'network', 'number', 'relations' );
    printTableHeader();
    foreach my $network ( sort( keys( %used_networks ) ) ) {
        @relations_of_network    = sort( keys( %{$used_networks{$network}} ) );
        $network = $network eq '__unset_network__' ? '' : $network;
        if ( scalar @relations_of_network <= 10 ) {
            printTableLine( 'network'           =>    $network,
                            'number'            =>    scalar @relations_of_network, 
                            'relations'         =>    join( ',', @relations_of_network )
                          );
        } else {
            printTableLine( 'network'           =>    $network,
                            'number'            =>    scalar @relations_of_network, 
                            'relations'         =>    sprintf( gettext("%s and more ..."), join( ',', splice(@relations_of_network,0,10) ) )
                          );
        }
    }
    printTableFooter(); 

    if ( scalar keys (%unused_operators) ) {
        push( @HTML_main, "<p>\n" );
        push( @HTML_main, gettext("This section lists the 'operator'-values which have not been considered. ") );
        push( @HTML_main, gettext("They might include typos in values which otherwise should have been considered. ") );
        push( @HTML_main, "\n</p>\n" );
    
        printTableInitialization( 'operator', 'number', 'relations' );
        printTableHeader();
        foreach my $operator ( sort( keys( %unused_operators ) ) ) {
            @relations_of_operator    = sort( keys( %{$unused_operators{$operator}} ) );
            $operator = $operator eq '__unset_operator__' ? '' : $operator;
            if ( scalar @relations_of_network <= 10 ) {
                printTableLine( 'operator'          =>    $operator,
                                'number'            =>    scalar @relations_of_operator, 
                                'relations'         =>    join( ',', @relations_of_operator )
                              );
            } else {
                printTableLine( 'operator'          =>    $operator,
                                'number'            =>    scalar @relations_of_operator, 
                                'relations'         =>    sprintf( gettext("%s and more ..."), join( ',', splice(@relations_of_operator,0,10) ) )
                              );
            }
        }
        printTableFooter();
    }

}
    

#############################################################################################

sub printHintUnusedNetworks {

    my @relations_of_network = ();
    
    printHeader( gettext("Not Considered 'network'-Values"), 2, 'notconsiderednetworks' );
    
    push( @HTML_main, "<p>\n" );
    push( @HTML_main, gettext("This section lists the 'network'-values which have not been considered. ") );
    push( @HTML_main, gettext("They might include typos in values which otherwise should have been considered. ") );
    push( @HTML_main, "\n</p>\n" );

    printTableInitialization( 'network', 'number', 'relations' );
    printTableHeader();
    foreach my $network ( sort( keys( %unused_networks ) ) ) {
        @relations_of_network    = sort( keys( %{$unused_networks{$network}} ) );
        $network = $network eq '__unset_network__' ? '' : $network;
        if ( scalar @relations_of_network <= 10 ) {
            printTableLine( 'network'           =>    $network,
                            'number'            =>    scalar @relations_of_network, 
                            'relations'         =>    join( ',', @relations_of_network )
                          );
        } else {
            printTableLine( 'network'           =>    $network,
                            'number'            =>    scalar @relations_of_network, 
                            'relations'         =>    sprintf( gettext("%s and more ..."), join( ',', splice(@relations_of_network,0,10) ) )
                          );
        }
    }
    printTableFooter(); 

}
    

#############################################################################################

sub printHeader {
    my $text  = shift;
    my $level = shift || 1;
    my $label = shift;
    
    my $header_numbers = undef;

    if ( $printText_buffer ) {
        if ( $printText_buffer eq "<p>\n" ) {
            push( @HTML_main, $printText_buffer . "&nbsp;\n</p>\n" );
        } else {
            push( @HTML_main, $printText_buffer . "\n</p>\n" );
        }
        $printText_buffer = '';
    }

    if ( $text ) {
        $level = 1   if ( $level < 1 );
        $level = 6   if ( $level > 6 );
        if ( $level == 1 ) {
            $header_numbers = ++$html_header_anchor_numbers[1];
            $html_header_anchor_numbers[2] = 0;
            $html_header_anchor_numbers[3] = 0;
            $html_header_anchor_numbers[4] = 0;
            $html_header_anchor_numbers[5] = 0;
            $html_header_anchor_numbers[6] = 0;
        } elsif ( $level == 2 ) {
            $header_numbers = $html_header_anchor_numbers[1] . '.' . ++$html_header_anchor_numbers[2];
            $html_header_anchor_numbers[3] = 0;
            $html_header_anchor_numbers[4] = 0;
            $html_header_anchor_numbers[5] = 0;
            $html_header_anchor_numbers[6] = 0;
        } elsif ( $level == 3 ) {
            $header_numbers = $html_header_anchor_numbers[1] . '.' . $html_header_anchor_numbers[2] . '.' . ++$html_header_anchor_numbers[3];
            $html_header_anchor_numbers[4] = 0;
            $html_header_anchor_numbers[5] = 0;
            $html_header_anchor_numbers[6] = 0;
        } elsif ( $level == 4 ) {
            $header_numbers = $html_header_anchor_numbers[1] . '.' . $html_header_anchor_numbers[2] . '.' . $html_header_anchor_numbers[3] . '.' . ++$html_header_anchor_numbers[4];
            $html_header_anchor_numbers[5] = 0;
            $html_header_anchor_numbers[6] = 0;
        } elsif ( $level == 5 ) {
            $header_numbers = $html_header_anchor_numbers[1] . '.' . $html_header_anchor_numbers[2] . '.' . $html_header_anchor_numbers[3] . '.' . $html_header_anchor_numbers[4] . '.' . ++$html_header_anchor_numbers[5];
            $html_header_anchor_numbers[6] = 0;
        } elsif ( $level == 6 ) {
            $header_numbers = $html_header_anchor_numbers[1] . '.' . $html_header_anchor_numbers[2] . '.' . $html_header_anchor_numbers[3] . '.' . $html_header_anchor_numbers[4] . '.' . $html_header_anchor_numbers[5] . '.' . ++$html_header_anchor_numbers[6];
        }
        
        if ( $label ) {
            push( @html_header_anchors, sprintf( "A%d N%s L%s T%s", $level, $header_numbers, $label, $text ) );
            push( @HTML_main,          "        <hr />\n" )   if ( $level == 1 );
            push( @HTML_main, sprintf( "        <h%d id=\"%s\">%s %s</h%d>\n", $level, $label, $header_numbers, wiki2html($text), $level ) );
        } else {
            push( @html_header_anchors, sprintf( "A%d N%s LA%s T%s", $level, $header_numbers, $header_numbers, $text ) );
            push( @HTML_main,          "        <hr />\n" )   if ( $level == 1 );
            push( @HTML_main, sprintf( "        <h%d id=\"A%s\">%s %s</h%d>\n", $level, $header_numbers, $header_numbers, wiki2html($text), $level ) );
        }

        printf STDERR "%s %s %s\n", get_time(), $level, $text    if ( $verbose );
    }
}


#############################################################################################

sub printText {
    my $text = shift;

    $printText_buffer = "<p>\n"   unless ( $printText_buffer );

    if ( $text ) {
        $printText_buffer .= sprintf( "%s\n", wiki2html($text) );
    } else {
        if ( $printText_buffer eq "<p>\n" ) {
            push( @HTML_main, $printText_buffer . "&nbsp;\n</p>\n" );
        } else {
            push( @HTML_main, $printText_buffer . "\n</p>\n" );
        }
        $printText_buffer = '';
    }
}


#############################################################################################

sub printFooter {
    ;
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

    if ( $printText_buffer ) {
        if ( $printText_buffer eq "<p>\n" ) {
            push( @HTML_main, $printText_buffer . "&nbsp;\n</p>\n" );
        } else {
            push( @HTML_main, $printText_buffer . "\n</p>\n" );
        }
        $printText_buffer = '';
    }

    if ( scalar(@table_columns) ) {
        push( @HTML_main, sprintf( "%8s<table class=\"oepnvtable\">\n", ' ' ) );
        push( @HTML_main, sprintf( "%12s<thead>\n", ' ' ) );
        push( @HTML_main, sprintf( "%16s<tr class=\"tableheaderrow\">", ' ' ) );
        if ( $no_of_columns == 0 ) {
            push( @HTML_main, "<th class=\"name\">Linienverlauf (name=)</th>" );
            push( @HTML_main, "<th class=\"type\">Typ (type=)</th>" );
            push( @HTML_main, "<th class=\"relation\">Relation (id=)</th>" ); 
            push( @HTML_main, "<th class=\"PTv\">PTv</th>" );
            push( @HTML_main, "<th class=\"issues\">Fehler</th>" );
            push( @HTML_main, "<th class=\"notes\">Anmerkungen</th>" );
        } else {
            foreach $element ( @columns ) {
                push( @HTML_main, sprintf( "<th class=\"%s\">%s</th>", $element, ($column_name{$element} ? $column_name{$element} : $element ) ) );
            }
        }
        push( @HTML_main, "</tr>\n" );
        push( @HTML_main, sprintf( "%12s</thead>\n", ' ' ) );
        push( @HTML_main, sprintf( "%12s<tbody>\n", ' ' ) );
    }
}


#############################################################################################

sub printTableSubHeader {
    my %hash            = ( @_ );
    my $ref             = $hash{'ref'}           || '';
    my $ref_or_list     = $hash{'ref-or-list'};
    my $network         = $hash{'network'}       || '';
    my $pt_type         = $hash{'pt_type'}       || '';
    my $colour          = $hash{'colour'}        || '';
    my $ref_text        = undef;
    my $csv_text        = '';       # some information comming from the CSV input file
    my $info            = '';
    my @ref_or_array       = ();
    my $ref_or_list_text   = '';

    if ( $ref_or_list ) {
        @ref_or_array = @{$ref_or_list};
        $ref_or_list_text = join(' ', @ref_or_array );
    } elsif ( $ref ) {
        push( @ref_or_array, $ref );
        $ref_or_list_text = $ref;
    }

    if ( scalar @ref_or_array && $network ) {
        $ref_text = join(' ', map { printSketchLineTemplate( $_, $network, $pt_type, $colour ) } @ref_or_array );
    } elsif ( scalar @ref_or_array ) {
        $ref_text = join(' ', @ref_or_array );
    }

    if ( $hash{'Comment'}  ) {
        $csv_text .= sprintf( "%s: %s; ", ( $column_name{'Comment'}  ? $column_name{'Comment'}  : 'Comment' ),  html_escape($hash{'Comment'})  );
        $csv_text =~ s|!([^!]+)!|<span class=\"attention\">$1</span>|;
    }
    $csv_text .= sprintf( "%s: %s; ", ( $column_name{'From'}     ? $column_name{'From'}     : 'From' ),     html_escape($hash{'From'})     )  if ( $hash{'From'}     );
    $csv_text .= sprintf( "%s: %s; ", ( $column_name{'To'}       ? $column_name{'To'}       : 'To' ),       html_escape($hash{'To'})       )  if ( $hash{'To'}       );
    $csv_text .= sprintf( "%s: %s; ", ( $column_name{'Operator'} ? $column_name{'Operator'} : 'Operator' ), html_escape($hash{'Operator'}) )  if ( $hash{'Operator'} );
    $csv_text =~ s/; $//;
    
    $info = $csv_text ? $csv_text : '???';
    $info =~ s/\"/_/g;

    if ( $no_of_columns > 1 && $ref_or_list_text && $ref_text ) {
        push( @HTML_main, sprintf( "%16s<tr data-info=\"%s\" data-ref=\"%s\" class=\"sketchline\"><td class=\"sketch\">%s</td><td class=\"csvinfo\" colspan=\"%d\">%s</td></tr>\n", ' ', $info, $ref_or_list_text, $ref_text, $no_of_columns-1, $csv_text ) );
    }
}


#############################################################################################

sub printTableLine {
    my %hash    = ( @_ );
    my $val     = undef;
    my $i       = 0;
    my $ref     = $hash{'ref'} || '???';
    my $info    = $hash{'relation'} ? $hash{'relation'} : ( $hash{'network'} ? $hash{'network'} : $ref);

    $info =~ s/\"/_/g;
    push( @HTML_main, sprintf( "%16s<tr data-info=\"%s\" data-ref=\"%s\" class=\"line\">", ' ', $info, $ref ) );
    for ( $i = 0; $i < $no_of_columns; $i++ ) {
        $val =  $hash{$columns[$i]} || '';
        if ( $columns[$i] eq "relation" ) {
            push( @HTML_main, sprintf( "<td class=\"relation\">%s</td>", printRelationTemplate($val) ) );
        } elsif ( $columns[$i] eq "relations"  ){
            my $and_more = '';
            my $searchfor = gettext(' and more ...');
            if ( $val =~ m/\Q$searchfor\E/ ) {
                $and_more = $searchfor;
                $val =~ s/\Q$searchfor\E//;
            }
            push( @HTML_main, sprintf( "<td class=\"relations\">%s%s</td>", join( ', ', map { printRelationTemplate($_,'ref'); } split( ',', $val ) ), $and_more ) );
        } elsif ( $columns[$i] eq "issues"  ){
            $val =~ s/__separator__/<br>/g;
            push( @HTML_main, sprintf( "<td class=\"%s\">%s</td>", $columns[$i], $val ) );
        } elsif ( $columns[$i] eq "notes"  ){
            $val =~ s/__separator__/<br>/g;
            push( @HTML_main, sprintf( "<td class=\"%s\">%s</td>", $columns[$i], $val ) );
        } else {
            $val = html_escape($val);
            $val =~ s/__separator__/<br>/g;
            push( @HTML_main, sprintf( "<td class=\"%s\">%s</td>", $columns[$i], $val ) );
        }
    }
    push( @HTML_main, "</tr>\n" );
}


#############################################################################################

sub printTableFooter {

    push( @HTML_main, sprintf( "%12s</tbody>\n",  ' ' ) );
    push( @HTML_main, sprintf( "%8s</table>\n\n", ' ' ) );
}


#############################################################################################

sub printXxxTemplate {
    my $node_or_way_or_relation  = shift;
    my $val                      = $_[0];

    if ( $val ) {
        if ( $node_or_way_or_relation ) {
            if ( $node_or_way_or_relation eq 'node' ) {
                $val = printNodeTemplate( @_ );
            } elsif ( $node_or_way_or_relation eq 'way' ) {
                $val = printWayTemplate( @_ );
            } elsif ( $node_or_way_or_relation eq 'relation' ) {
                $val = printRelationTemplate( @_ );
            }
        }
    } else {
        $val = '';
    }

    return $val;
}


#############################################################################################

sub printRelationTemplate {
    my $val  = shift;
    my $tags = shift;
    
    if ( $val ) {
        my $info_string = '';
        if ( $tags ) {
            foreach my $tag ( split( ';', $tags ) ) {
                if ( $RELATIONS{$val} && $RELATIONS{$val}->{'tag'} && $RELATIONS{$val}->{'tag'}->{$tag} ) {
                    $info_string .= sprintf( "'%s' ", $RELATIONS{$val}->{'tag'}->{$tag} );
                    last;
                }
            }
        }
        
        my $image_url = "<img src=\"/img/Relation.svg\" alt=\"Relation\" />";

        if ( $val > 0 ) {
            my $relation_url = sprintf( "<a href=\"https://osm.org/relation/%s\" title=\"Browse on map\">%s</a>", $val, $val );
            my $id_url       = sprintf( "<a href=\"https://osm.org/edit?editor=id&amp;relation=%s\" title=\"Edit in iD\">iD</a>", $val );
            my $josm_url     = sprintf( "<a href=\"https://localhost:8112/import?url=https://api.openstreetmap.org/api/0.6/relation/%s/full\" title=\"Edit in JOSM\">JOSM</a>", $val );

            $val = sprintf( "%s %s%s <small>(%s, %s)</small>", $image_url, $info_string, $relation_url, $id_url, $josm_url );    
        } else {
            $val = sprintf( "%s %s%s", $image_url, $info_string, $val );
        }
    } else {
        $val = '';
    }
    
    return $val;
}


#############################################################################################

sub printWayTemplate {
    my $val  = shift;
    my $tags = shift;
    
    if ( $val ) {
        my $info_string = '';
        if ( $tags ) {
            foreach my $tag ( split( ';', $tags ) ) {
                if ( $WAYS{$val} && $WAYS{$val}->{'tag'} && $WAYS{$val}->{'tag'}->{$tag} ) {
                    $info_string .= sprintf( "'%s' ", $WAYS{$val}->{'tag'}->{$tag} );
                    last;
                }
            }
        }

        my $image_url = "<img src=\"/img/Way.svg\" alt=\"Way\" />";

        if ( $val > 0 ) {
            my $way_url   = sprintf( "<a href=\"https://osm.org/way/%s\" title=\"Browse on map\">%s</a>", $val, $val );
            my $id_url    = sprintf( "<a href=\"https://osm.org/edit?editor=id&amp;way=%s\" title=\"Edit in iD\">iD</a>", $val );
            my $josm_url  = sprintf( "<a href=\"https://localhost:8112/import?url=https://api.openstreetmap.org/api/0.6/way/%s/full\" title=\"Edit in JOSM\">JOSM</a>", $val );

            $val = sprintf( "%s %s%s <small>(%s, %s)</small>", $image_url, $info_string, $way_url, $id_url, $josm_url );    
        } else {
            $val = sprintf( "%s %s%s", $image_url, $info_string, $val );
        }
    } else {
        $val = '';
    }
    
    return $val;
}


#############################################################################################

sub printNodeTemplate {
    my $val  = shift;
    my $tags = shift;
    
    if ( $val ) {
        my $info_string     = '';
        if ( $tags ) {
            foreach my $tag ( split( ';', $tags ) ) {
                if ( $NODES{$val} && $NODES{$val}->{'tag'} && $NODES{$val}->{'tag'}->{$tag} ) {
                    $info_string = sprintf( "'%s' ", $NODES{$val}->{'tag'}->{$tag} );
                    last;
                }
            }
        }

        my $image_url = "<img src=\"/img/Node.svg\" alt=\"Node\" />";
        
        if ( $val > 0 ) {
            my $node_url = sprintf( "<a href=\"https://osm.org/node/%s\" title=\"Brose on map\">%s</a>", $val, $val );
            my $id_url   = sprintf( "<a href=\"https://osm.org/edit?editor=id&amp;node=%s\" title=\"Edit in iD\">iD</a>", $val );
            my $josm_url = sprintf( "<a href=\"https://localhost:8112/import?url=https://api.openstreetmap.org/api/0.6/node/%s\" title=\"Edit in JOSM\">JOSM</a>", $val );

            $val = sprintf( "%s %s%s <small>(%s, %s)</small>", $image_url, $info_string, $node_url, $id_url, $josm_url );    
        } else {
            $val = sprintf( "%s %s%s", $image_url, $info_string, $val );
        }
    } else {
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
    my $textdeco      = '';
    my $span_begin    = '';
    my $span_end      = '';
    my $bg_colour     = GetColourFromString( $colour );
    my $fg_colour     = GetForeGroundFromBackGround( $bg_colour );
    
    if ( $bg_colour && $fg_colour && $coloured_sketchline ) {
        $colour_string = "\&amp;bg=" . $bg_colour . "\&amp;fg=". $fg_colour;
        $pt_string     = "\&amp;r=1"                                        if ( $pt_type eq 'train' || $pt_type eq 'light_rail'     );
        $textdeco      = ' style="text-decoration:none;"';
        $span_begin    = sprintf( "<span style=\"color:%s;background-color:%s;\">&nbsp;", $fg_colour, $bg_colour );
        $span_end      = "&nbsp;</span>";
    }
    $ref_escaped    =~ s/ /+/g;
    $network        =~ s/ /+/g;
    $text           = sprintf( "<a href=\"https://overpass-api.de/api/sketch-line?ref=%s\&amp;network=%s\&amp;style=wuppertal%s%s\" title=\"Sketch-Line\"%s>%s%s%s</a>", $ref_escaped, uri_escape($network), uri_escape($colour_string), $pt_string, $textdeco, $span_begin, $ref, $span_end ); # some manual expansion of the template
    
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
        $text =~ s/ /%20/g;
        $text =~ s/#/%23/g;
    }
    return $text;
}


#############################################################################################

sub ctrl_escape {
    my $text = shift;
    if ( $text ) {
        $text =~ s/\t/<tab>/g;
        $text =~ s/\r/<cr>/g;
        $text =~ s/\n/<lf>/g;
        $text =~ s/ /<blank>/g;
    }
    return html_escape($text);
}


#############################################################################################

sub wiki2html {
    my $text = shift;
    my $sub  = undef;
    if ( $text ) {
        # ignore: [[Category:Nürnberg]]
        $text =~ s/\[\[Category:[^\]]+\]\]//g;
        # convert: [[Nürnberg/Transportation/Analyse/DE-BY-VGN-Linien|VGN Linien]]
        while ( $text =~ m/\[\[([^|]+)\|([^\]]+)\]\]/g ) {
            $sub = sprintf( "<a href=\"https://wiki.openstreetmap.org/wiki/%s\">%s</a>", $1, $2 );
            $text =~ s/\[\[[^|]+\|[^\]]+\]\]/$sub/;
        }
        # convert: [[Nürnberg/Transportation/Analyse/DE-BY-VGN-Linien]]
        while ( $text =~ m/\[\[([^\]]+)\]\]/g ) {
            $sub = sprintf( "<a href=\"https://wiki.openstreetmap.org/wiki/%s\">%s</a>", $1, $1 );
            $text =~ s/\[\[[^\]]+\]\]/$sub/;
        }
        # convert: [https://example.com/index.html External Link]
        while ( $text =~ m/\[([^ ]+) ([^\]]+)\]/g ) {
            $sub = sprintf( "<a href=\"%s\">%s</a>", $1, $2 );
            $text =~ s/\[[^ ]+ [^\]]+\]/$sub/;
        }
        # convert: [https://example.com/index.html]
        while ( $text =~ m/\[([^\]]+)\]/g ) {
            $sub = sprintf( "<a href=\"%s\">%s</a>", $1, $1 );
            $text =~ s/\[[^\]]+\]/$sub/;
        }
        while ( $text =~ m/!!!(.+?)!!!/g ) {
            $sub = sprintf( "<span class=\"attention\">%s</span>", $1 );
            $text =~ s/!!!(.+?)!!!/$sub/;
        }
        while ( $text =~ m/'''''(.+?)'''''/g ) {
            $sub = sprintf( "<strong><em>%s</em></strong>", $1 );
            $text =~ s/'''''(.+?)'''''/$sub/;
        }
        while ( $text =~ m/'''(.+?)'''/g ) {
            $sub = sprintf( "<strong>%s</strong>", $1 );
            $text =~ s/'''(.+?)'''/$sub/;
        }
        while ( $text =~ m/''(.+?)''/g ) {
            $sub = sprintf( "<em>%s</em>", $1 );
            $text =~ s/''(.+?)''/$sub/;
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
            $ret_value= lc($string);
        } elsif ( $string =~ m/^#([A-Fa-f0-9])([A-Fa-f0-9])([A-Fa-f0-9])$/ ) {
            $ret_value= lc("#" . $1 . $1 . $2 . $2 . $3 . $3);
        } else {
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
        my $g           = ($rgbval & 0x00ff00) >> 8;
        my $b           = $rgbval & 0xff;
        my $brightness  = $r * 0.299 + $g * 0.587 + $b * 0.114;
        $ret_value      = ($brightness > 160) ? "#000000" : "#ffffff";
    }
    return $ret_value;
}
    

#############################################################################################

sub get_time {
    
    my ($sec,$min,$hour,$day,$month,$year) = localtime();
    
    return sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $month+1, $day, $hour, $min, $sec ); 
}
    


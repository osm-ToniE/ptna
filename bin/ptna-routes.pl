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

use Locale::gettext qw();       # 'gettext()' will be overwritten in this file (at the end), so don't import from module into our name space

use Getopt::Long;
use OSM::XML            qw( parse );
use OSM::Data           qw( %META %NODES %WAYS %RELATIONS );
use RoutesList;
use GTFS::PtnaSQLite    qw( getGtfsRouteIdHtmlTag getGtfsTripIdHtmlTag getGtfsShapeIdHtmlTag );
use Data::Dumper;
use Encode;


####################################################################################################################
#
# Some OSM specific stuff, settings
#
####################################################################################################################

my @supported_route_types                   = ( 'train', 'subway', 'light_rail', 'tram', 'trolleybus', 'bus', 'ferry', 'monorail', 'aerialway', 'funicular', 'share_taxi' );
my @well_known_other_route_types            = ( 'bicycle', 'mtb', 'hiking', 'road', 'foot', 'inline_skates', 'canoe', 'detour', 'fitness_trail', 'horse', 'motorboat', 'nordic_walking', 'pipeline', 'piste', 'power', 'running', 'ski', 'snowmobile', 'cycling' , 'historic', 'motorcycle', 'riding' );
my @well_known_network_types                = ( 'international', 'national', 'regional', 'local', 'icn', 'ncn', 'rcn', 'lcn', 'iwn', 'nwn', 'rwn', 'lwn', 'road' );
my @well_known_other_types                  = ( 'restriction', 'enforcement', 'destination_sign' );

my %transport_type_uses_way_type = ( 'train'     => { 'railway'   => [ 'rail',   'light_rail', 'tram', 'narrow_gauge', 'preserved',  'construction' ] },
                                     'subway'    => { 'railway'   => [ 'subway', 'light_rail', 'tram' ] },
                                     'tram'      => { 'railway'   => [ 'tram',   'rail',       'light_rail', 'narrow_gauge', 'subway' ] },
                                     'monorail'  => { 'railway'   => [ 'monorail'  ] },
                                     'funicular' => { 'railway'   => [ 'funicular' ] },
                                     'ferry'     => { 'route'     => [ 'ferry'     ] },
                                     'aerialway' => { 'aerialway' => [ 'cable_car',     'gondola',        'mixed_lift',   'chair_lift' ] },
                                     'bus'       => { 'highway'   => [ 'motorway',      'motorway_link',  'trunk',        'trunk_link',    'primary',      'primary_link',
                                                                       'secondary',     'secondary_link', 'tertiary',     'tertiary_link', 'unclassified', 'residential',
                                                                       'service',       'track',          'footway',      'cycleway',      'path',         'pedestrian',
                                                                       'living_street', 'road',           'bus_guideway', 'construction'
                                                                     ]
                                                    },
                                   );
   $transport_type_uses_way_type{'coach'}       = $transport_type_uses_way_type{'bus'};
   $transport_type_uses_way_type{'share_taxi'}  = $transport_type_uses_way_type{'bus'};
   $transport_type_uses_way_type{'trolleybus'}  = $transport_type_uses_way_type{'bus'};
   $transport_type_uses_way_type{'light_rail'}  = $transport_type_uses_way_type{'train'};


####################################################################################################################
#
# Handling options from command line
#
####################################################################################################################

my $opt_language                    = undef;
my $opt_test                        = undef;
my $verbose                         = undef;
my $debug                           = undef;
my $osm_xml_file                    = undef;
my $routes_file                     = undef;
my $relaxed_begin_end_for           = undef;
my $network_guid                    = undef;
my $network_long_regex              = undef;
my $network_short_regex             = undef;
my $no_additional_navigation        = undef;
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
my $check_way_type                  = undef;
my $check_gtfs                      = undef;
my $expect_network_long             = undef;
my $expect_network_long_as          = undef;
my $expect_network_long_for         = undef;
my $expect_network_short            = undef;
my $expect_network_short_as         = undef;
my $expect_network_short_for        = undef;
my $opt_gtfs_feed                   = undef;
my $link_gtfs                       = undef;
my $multiple_ref_type_entries       = "analyze";
my $path_to_work_dir                = '/osm/ptna/work';
my $ptv1_compatibility              = "no";
my $show_gtfs                       = undef;
my $strict_network                  = undef;
my $strict_operator                 = undef;
my $max_error                       = undef;
my $help                            = undef;
my $man_page                        = undef;
my $positive_notes                  = undef;
my $csv_separator                   = ';';
my $or_separator                    = '|';                 # used to separate several 'ref' values in CSV entry "43|E43;bus;;;;"
my $ref_separator                   = '/';                 # used to separate several 'ref' values in CSV entry "602/50;bus;;;;" for 'ref' from different 'network' (ref:xxx=602 and ref:yyy=50)
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
            'check-way-type'                =>  \$check_way_type,               # --check-way-type                  check for routes: do vehicles use the right way type
            'check-gtfs'                    =>  \$check_gtfs,                   # --check-gtfs                      check "gtfs:*" tags for validity/uniqueness/...
            'coloured-sketchline'           =>  \$coloured_sketchline,          # --coloured-sketchline             force SketchLine to print coloured icons
            'expect-network-long'           =>  \$expect_network_long,          # --expect-network-long             note if 'network' is not long form in general
            'expect-network-long-as:s'      =>  \$expect_network_long_as,       # --expect-network-long-as="Münchner Verkehrs- und Tarifverbund|Biberger Bürgerbus"
            'expect-network-long-for:s'     =>  \$expect_network_long_for,      # --expect-network-long-for="MVV|BBB"         note if 'network' is not long form for ...
            'expect-network-short'          =>  \$expect_network_short,         # --expect-network-short            note if 'network' is not short form in general
            'expect-network-short-as:s'     =>  \$expect_network_short_as,      # --expect-network-short-as='BOB'
            'expect-network-short-for:s'    =>  \$expect_network_short_for,     # --expect-network-short-for='Bayerische Oberlandbahn'        note if 'network' is not short form for ...
            'gtfs-feed=s'                   =>  \$opt_gtfs_feed,                # --gtfs-feed='DE-BY-MVV'
            'link-gtfs'                     =>  \$link_gtfs,                    # --link-gtfs                       create a link to GTFS-Analysis for "gtfs:*" tags
            'routes-file=s'                 =>  \$routes_file,                  # --routes-file=zzz                 CSV file with a list of routes of the of the network
            'max-error=i'                   =>  \$max_error,                    # --max-error=10                    limit number of templates printed for identical error messages
            'multiple-ref-type-entries=s'   =>  \$multiple_ref_type_entries,    # --multiple-ref-type-entries=analyze|allow    how to handle multiple "ref;type" in routes-file
            'network-guid=s'                =>  \$network_guid,                 # --network-guid='DE-BY-MVV'
            'network-long-regex:s'          =>  \$network_long_regex,           # --network-long-regex='Münchner Verkehrs- und Tarifverbund|Grünwald|Bayerische Oberlandbahn'
            'network-short-regex:s'         =>  \$network_short_regex,          # --network-short-regex='MVV|BOB'
            'no-additional-navigation'      =>  \$no_additional_navigation,     # --no-additional-navigation
            'operator-regex:s'              =>  \$operator_regex,               # --operator-regex='MVG|Münchner'
            'positive-notes'                =>  \$positive_notes,               # --positive-notes                  print positive information for notes, if e.g. something is fulfilled
            'ptv1-compatibility=s'          =>  \$ptv1_compatibility,           # --ptv1-compatibility=no|show|allow    how to handle "highway=bus_stop" in PTv2
            'relaxed-begin-end-for:s'       =>  \$relaxed_begin_end_for,        # --relaxed-begin-end-for=...       for train/tram/light_rail: first/last stop position does not have to be on first/last node of way, but within first/last way
            'osm-xml-file=s'                =>  \$osm_xml_file,                 # --osm-xml-file=yyy                XML output of Overpass APU query
            'path-to-work-dir=s'            =>  \$path_to_work_dir,             # --path-to-work-dir=abc            XML output of Overpass APU query
            'separator=s'                   =>  \$csv_separator,                # --separator=';'                   separator in the CSV file
            'or-separator=s'                =>  \$or_separator,                 # --or-separator='|'                separator in the CSV file inside 'ref' values to allow multiple values
            'ref-separator=s'               =>  \$ref_separator,                # --ref-separator='/'               separator in the CSV file inside 'ref' values to show cooperations
            'show-gtfs'                     =>  \$show_gtfs,                    # --show-gtfs                       print positive information for "gtfs:*" tags
            'strict-network'                =>  \$strict_network,               # --strict-network                  do not consider empty network tags
            'strict-operator'               =>  \$strict_operator,              # --strict-operator                 do not consider empty operator tags
            'test'                          =>  \$opt_test,                     # --test                            to test the SW
            'title=s'                       =>  \$page_title,                   # --title=...                       Title for the HTML page
          );

$page_title                 = decode( 'utf8', $page_title )                  if ( $page_title                );
$opt_gtfs_feed              = decode( 'utf8', $opt_gtfs_feed )               if ( $opt_gtfs_feed             );
$network_guid               = decode( 'utf8', $network_guid )                if ( $network_guid              );
$network_long_regex         = decode( 'utf8', $network_long_regex )          if ( $network_long_regex        );
$network_short_regex        = decode( 'utf8', $network_short_regex )         if ( $network_short_regex       );
$operator_regex             = decode( 'utf8', $operator_regex )              if ( $operator_regex            );
$expect_network_long_as     = decode( 'utf8', $expect_network_long_as )      if ( $expect_network_long_as    );
$expect_network_long_for    = decode( 'utf8', $expect_network_long_for )     if ( $expect_network_long_for   );
$expect_network_short_as    = decode( 'utf8', $expect_network_short_as )     if ( $expect_network_short_as   );
$expect_network_short_for   = decode( 'utf8', $expect_network_short_for )    if ( $expect_network_short_for  );


if ( $opt_language ) {
    my $PATH = $0;
    $PATH =~ s|bin/[^/]*$|locale|;
    printf STDERR "%s\n", gettext("Language test");
    $ENV{'LANGUAGE'} = $opt_language;
    Locale::gettext::setlocale( LC_MESSAGES, '' );
    Locale::gettext::bindtextdomain( 'ptna', $PATH );
    Locale::gettext::textdomain( "ptna" );
    printf STDERR "%s\n", gettext("Language test");
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
        $ref_separator = '/';
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

unless ( $opt_gtfs_feed ) {
    $opt_gtfs_feed = $network_guid;
}


if ( $verbose ) {
    printf STDERR "%s ptna-routes.pl -v\n", get_time();
    printf STDERR "%20s--title='%s'\n",                    ' ', $page_title                 ? $page_title   : '';
    printf STDERR "%20s--network-guid='%s'\n",             ' ', $network_guid               ? $network_guid : '';
    printf STDERR "%20s--language='%s'\n",                 ' ', $opt_language               ? $opt_language : 'en';
    printf STDERR "%20s--allow-coach='%s'\n",              ' ', $allow_coach                ? 'ON'          :'OFF';
    printf STDERR "%20s--check-access='%s'\n",             ' ', $check_access               ? 'ON'          :'OFF';
    printf STDERR "%20s--check-bus-stop='%s'\n",           ' ', $check_bus_stop             ? 'ON'          :'OFF';
    printf STDERR "%20s--check-gtfs='%s'\n",               ' ', $check_gtfs                 ? 'ON'          :'OFF';
    printf STDERR "%20s--check-motorway-link='%s'\n",      ' ', $check_motorway_link        ? 'ON'          :'OFF';
    printf STDERR "%20s--check-name='%s'\n",               ' ', $check_name                 ? 'ON'          :'OFF';
    printf STDERR "%20s--check-name-relaxed='%s'\n",       ' ', $check_name_relaxed         ? 'ON'          :'OFF';
    printf STDERR "%20s--check-osm-separator='%s'\n",      ' ', $check_osm_separator        ? 'ON'          :'OFF';
    printf STDERR "%20s--check-platform='%s'\n",           ' ', $check_platform             ? 'ON'          :'OFF';
    printf STDERR "%20s--check-roundabouts='%s'\n",        ' ', $check_roundabouts          ? 'ON'          :'OFF';
    printf STDERR "%20s--check-route-ref='%s'\n",          ' ', $check_route_ref            ? 'ON'          :'OFF';
    printf STDERR "%20s--check-sequence='%s'\n",           ' ', $check_sequence             ? 'ON'          :'OFF';
    printf STDERR "%20s--check-stop-position='%s'\n",      ' ', $check_stop_position        ? 'ON'          :'OFF';
    printf STDERR "%20s--check-version='%s'\n",            ' ', $check_version              ? 'ON'          :'OFF';
    printf STDERR "%20s--check-way-type='%s'\n",           ' ', $check_way_type             ? 'ON'          :'OFF';
    printf STDERR "%20s--coloured-sketchline='%s'\n",      ' ', $coloured_sketchline        ? 'ON'          :'OFF';
    printf STDERR "%20s--expect-network-long='%s'\n",      ' ', $expect_network_long        ? 'ON'          :'OFF';
    printf STDERR "%20s--expect-network-long-as='%s'\n",   ' ', $expect_network_long_as     ? $expect_network_long_as      : '';
    printf STDERR "%20s--expect-network-long-for='%s'\n",  ' ', $expect_network_long_for    ? $expect_network_long_for     : '';
    printf STDERR "%20s--expect-network-short='%s'\n",     ' ', $expect_network_short       ? 'ON'          :'OFF';
    printf STDERR "%20s--expect-network-short-as='%s'\n",  ' ', $expect_network_short_as    ? $expect_network_short_as     : '';
    printf STDERR "%20s--expect-network-short-for='%s'\n", ' ', $expect_network_short_for   ? $expect_network_short_for    : '';
    printf STDERR "%20s--gtfs-feed='%s'\n",                ' ', $opt_gtfs_feed              ? $opt_gtfs_feed : '';
    printf STDERR "%20s--link-gtfs='%s'\n",                ' ', $link_gtfs                  ? 'ON'          :'OFF';
    printf STDERR "%20s--max-error='%s'\n",                ' ', $max_error                  ? $max_error                   : '';
    printf STDERR "%20s--multiple-ref-type-entries='%s'\n",' ', $multiple_ref_type_entries  ? $multiple_ref_type_entries   : '';
    printf STDERR "%20s--network-long-regex='%s'\n",       ' ', $network_long_regex         ? $network_long_regex          : '';
    printf STDERR "%20s--network-short-regex='%s'\n",      ' ', $network_short_regex        ? $network_short_regex         : '';
    printf STDERR "%20s--no-additional-navigation='%s'\n", ' ', $no_additional_navigation   ? 'ON'          :'OFF';
    printf STDERR "%20s--operator-regex='%s'\n",           ' ', $operator_regex             ? $operator_regex              : '';
    printf STDERR "%20s--positive-notes='%s'\n",           ' ', $positive_notes             ? 'ON'          :'OFF';
    printf STDERR "%20s--ptv1-compatibility='%s'\n",       ' ', $ptv1_compatibility         ? $ptv1_compatibility          : '';
    printf STDERR "%20s--relaxed-begin-end-for='%s'\n",    ' ', $relaxed_begin_end_for      ? $relaxed_begin_end_for       : '';
    printf STDERR "%20s--show-gtfs='%s'\n",                ' ', $show_gtfs                  ? 'ON'          :'OFF';
    printf STDERR "%20s--strict-network='%s'\n",           ' ', $strict_network             ? 'ON'          :'OFF';
    printf STDERR "%20s--strict-operator='%s'\n",          ' ', $strict_operator            ? 'ON'          :'OFF';
    printf STDERR "%20s--separator='%s'\n",                ' ', $csv_separator              ? $csv_separator               : '';
    printf STDERR "%20s--or-separator='%s'\n",             ' ', $or_separator               ? $or_separator                : '';
    printf STDERR "%20s--ref-separator='%s'\n",            ' ', $ref_separator              ? $ref_separator               : '';
    printf STDERR "%20s--routes-file='%s'\n",              ' ', decode('utf8', $routes_file )       if ( $routes_file                 );
    printf STDERR "%20s--osm-xml-file='%s'\n",             ' ', decode('utf8', $osm_xml_file )      if ( $osm_xml_file                );
    printf STDERR "%20s--path-to-work-dir='%s'\n",         ' ', decode('utf8', $path_to_work_dir )  if ( $path_to_work_dir            );
}


####################################################################################################################
#
# Some PTNA internal stuff
#
####################################################################################################################

my $xml_has_meta            = 0;        # does the XML file include META information?
my $xml_has_relations       = 0;        # does the XML file include any relations? If not, we will exit
my $xml_has_ways            = 0;        # does the XML file include any ways, then we can make a big analysis
my $xml_has_nodes           = 0;        # does the XML file include any nodes, then we can make a big analysis

my @RouteList                               = ();
my %have_seen_well_known_other_route_types  = ();
my %have_seen_well_known_network_types      = ();
my %have_seen_well_known_other_types        = ();

my %PT_relations_with_ref   = ();       # includes "positive" (the ones we are looking for) as well as "negative" (the other ones) route/route_master relations and "skip"ed relations (where 'network' or 'operator' does not fit)
my %PT_relations_without_ref= ();       # includes any route/route_master relations without 'ref' tag
my %platform_multipolygon_relations         = ();       # includes type=multipolygon, public_transport=platform  multipolygone relations
my %suspicious_relations    = ();       # strange relations with suspicious tags, a simple list of Relation-IDs, more details can befound with $RELATIONS{rel-id}
my %route_ways              = ();       # all ways  of the XML file that build the route : equals to %WAYS - %platform_ways
my %platform_ways           = ();       # all ways  of the XML file that are platforms (tag: public_transport=platform)
my %platform_nodes          = ();       # all nodes of the XML file that are platforms (tag: public_transport=platform)
my %stop_nodes              = ();       # all nodes of the XML file that are stops (tag: public_transport=stop_position)
my %used_networks           = ();       # 'network' values that did match
my %added_networks          = ();       # 'network' values where the 'network'of their route_master matched
my %unused_networks         = ();       # 'network' values that did not match
my %unused_operators        = ();       # 'operator' values that did not match but 'network' values did match
my %gtfs_relation_info_from = ();       # Relations reference to GTFS feed information using $gtfs_relation_info_from{feed-name}{feed_info_from}{release_date}{release_date_from}{relarionID} = 1;
my %gtfs_csv_info_from      = ();       # CSV data  reference to GTFS feed information using $gtfs_csv_info_from{feed-name}{release_date} = ( feed_info_from, release_info_from );

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

my $issues_string                   = '';   # to be used with ALL 'issues' and gettext/ngettext - a separate tool parses this code, extracts those statements and creates a list of all issues
my $notes_string                    = '';   # to be used with ALL 'notes'  and gettext/ngettext - a separate tool parses this code, extracts those statements and creates a list of all notes

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
                                'CSV-Comment'   => gettext('Comment'),
                                'CSV-From'      => gettext('From'),
                                'CSV-To'        => gettext('To'),
                                'CSV-Operator'  => gettext('Operator'),
                                'gtfs_feed'     => gettext('GTFS feed'),
                                'date'          => gettext('Date'),
                                'feed_from'     => gettext('GTFS feed from'),
                                'date_from'     => gettext('Date from'),
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

my %colour_table            = ( 'black'                 => '#000000',
                                'gray'                  => '#808080',
                                'grey'                  => '#808080',
                                'maroon'                => '#800000',
                                'olive'                 => '#808000',
                                'green'                 => '#008000',
                                'teal'                  => '#008080',
                                'navy'                  => '#000080',
                                'purple'                => '#800080',
                                'white'                 => '#FFFFFF',
                                'silver'                => '#c0c0c0',
                                'red'                   => '#FF0000',
                                'yellow'                => '#FFFF00',
                                'lime'                  => '#00FF00',
                                'aqua'                  => '#00FFFF',
                                'cyan'                  => '#00FFFF',
                                'blue'                  => '#0000FF',
                                'fuchsia'               => '#FF00FF',
                                'magenta'               => '#FF00FF',
                                'aliceblue'             => '#F0F8FF',
                                'antiquewhite'          => '#FAEBD7',
                                'aqua'                  => '#00FFFF',
                                'aquamarine'            => '#7FFFD4',
                                'azure'                 => '#F0FFFF',
                                'beige'                 => '#F5F5DC',
                                'bisque'                => '#FFE4C4',
                                'black'                 => '#000000',
                                'blanchedalmond'        => '#FFEBCD',
                                'blue'                  => '#0000FF',
                                'blueviolet'            => '#8A2BE2',
                                'brown'                 => '#A52A2A',
                                'burlywood'             => '#DEB887',
                                'cadetblue'             => '#5F9EA0',
                                'chartreuse'            => '#7FFF00',
                                'chocolate'             => '#D2691E',
                                'coral'                 => '#FF7F50',
                                'cornflowerblue'        => '#6495ED',
                                'cornsilk'              => '#FFF8DC',
                                'crimson'               => '#DC143C',
                                'cyan'                  => '#00FFFF',
                                'darkblue'              => '#00008B',
                                'darkcyan'              => '#008B8B',
                                'darkgoldenrod'         => '#B8860B',
                                'darkgray'              => '#A9A9A9',
                                'darkgrey'              => '#A9A9A9',
                                'darkgreen'             => '#006400',
                                'darkkhaki'             => '#BDB76B',
                                'darkmagenta'           => '#8B008B',
                                'darkolivegreen'        => '#556B2F',
                                'darkorange'            => '#FF8C00',
                                'darkorchid'            => '#9932CC',
                                'darkred'               => '#8B0000',
                                'darksalmon'            => '#E9967A',
                                'darkseagreen'          => '#8FBC8F',
                                'darkslateblue'         => '#483D8B',
                                'darkslategray'         => '#2F4F4F',
                                'darkslategrey'         => '#2F4F4F',
                                'darkturquoise'         => '#00CED1',
                                'darkviolet'            => '#9400D3',
                                'deeppink'              => '#FF1493',
                                'deepskyblue'           => '#00BFFF',
                                'dimgray'               => '#696969',
                                'dimgrey'               => '#696969',
                                'dodgerblue'            => '#1E90FF',
                                'firebrick'             => '#B22222',
                                'floralwhite'           => '#FFFAF0',
                                'forestgreen'           => '#228B22',
                                'fuchsia'               => '#FF00FF',
                                'gainsboro'             => '#DCDCDC',
                                'ghostWhite'            => '#F8F8FF',
                                'gold'                  => '#FFD700',
                                'goldenrod'             => '#DAA520',
                                'gray'                  => '#808080',
                                'grey'                  => '#808080',
                                'green'                 => '#008000',
                                'greenyellow'           => '#ADFF2F',
                                'honeydew'              => '#F0FFF0',
                                'hotpink'               => '#FF69B4',
                                'indianred'             => '#CD5C5C',
                                'indigo'                => '#4B0082',
                                'ivory'                 => '#FFFFF0',
                                'khaki'                 => '#F0E68C',
                                'lavender'              => '#E6E6FA',
                                'lavenderblush'         => '#FFF0F5',
                                'lawngreen'             => '#7CFC00',
                                'lemonchiffon'          => '#FFFACD',
                                'lightblue'             => '#ADD8E6',
                                'lightcoral'            => '#F08080',
                                'lightcyan'             => '#E0FFFF',
                                'lightgoldenrodyellow'  => '#FAFAD2',
                                'lightgray'             => '#D3D3D3',
                                'lightgrey'             => '#D3D3D3',
                                'lightgreen'            => '#90EE90',
                                'lightpink'             => '#FFB6C1',
                                'lightsalmon'           => '#FFA07A',
                                'lightseagreen'         => '#20B2AA',
                                'lightskyblue'          => '#87CEFA',
                                'lightslategray'        => '#778899',
                                'lightslategrey'        => '#778899',
                                'lightsteelblue'        => '#B0C4DE',
                                'lightyellow'           => '#FFFFE0',
                                'lime'                  => '#00FF00',
                                'limegreen'             => '#32CD32',
                                'linen'                 => '#FAF0E6',
                                'magenta'               => '#FF00FF',
                                'maroon'                => '#800000',
                                'mediumaquamarine'      => '#66CDAA',
                                'mediumblue'            => '#0000CD',
                                'mediumorchid'          => '#BA55D3',
                                'mediumpurple'          => '#9370D8',
                                'mediumseagreen'        => '#3CB371',
                                'mediumslateblue'       => '#7B68EE',
                                'mediumspringgreen'     => '#00FA9A',
                                'mediumturquoise'       => '#48D1CC',
                                'mediumvioletred'       => '#C71585',
                                'midnightblue'          => '#191970',
                                'mintcream'             => '#F5FFFA',
                                'mistyrose'             => '#FFE4E1',
                                'moccasin'              => '#FFE4B5',
                                'navajowhite'           => '#FFDEAD',
                                'navy'                  => '#000080',
                                'oldlace'               => '#FDF5E6',
                                'olive'                 => '#808000',
                                'olivedrab'             => '#6B8E23',
                                'orange'                => '#FFA500',
                                'orangered'             => '#FF4500',
                                'orchid'                => '#DA70D6',
                                'palegoldenrod'         => '#EEE8AA',
                                'palegreen'             => '#98FB98',
                                'paleturquoise'         => '#AFEEEE',
                                'palevioletred'         => '#D87093',
                                'papayawhip'            => '#FFEFD5',
                                'peachpuff'             => '#FFDAB9',
                                'peru'                  => '#CD853F',
                                'pink'                  => '#FFC0CB',
                                'plum'                  => '#DDA0DD',
                                'powderblue'            => '#B0E0E6',
                                'purple'                => '#800080',
                                'red'                   => '#FF0000',
                                'rosybrown'             => '#BC8F8F',
                                'royalblue'             => '#4169E1',
                                'saddlebrown'           => '#8B4513',
                                'salmon'                => '#FA8072',
                                'sandybrown'            => '#F4A460',
                                'seagreen'              => '#2E8B57',
                                'seashell'              => '#FFF5EE',
                                'sienna'                => '#A0522D',
                                'silver'                => '#C0C0C0',
                                'skyblue'               => '#87CEEB',
                                'slateblue'             => '#6A5ACD',
                                'slategray'             => '#708090',
                                'slategrey'             => '#708090',
                                'snow'                  => '#FFFAFA',
                                'springgreen'           => '#00FF7F',
                                'steelblue'             => '#4682B4',
                                'tan'                   => '#D2B48C',
                                'teal'                  => '#008080',
                                'thistle'               => '#D8BFD8',
                                'tomato'                => '#FF6347',
                                'turquoise'             => '#40E0D0',
                                'violet'                => '#EE82EE',
                                'wheat'                 => '#F5DEB3',
                                'white'                 => '#FFFFFF',
                                'whitesmoke'            => '#F5F5F5',
                                'yellow'                => '#FFFF00',
                                'yellowgreen'           => '#9ACD32'
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

        @RouteList = RoutesList::GetRoutesList();

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
        $xml_has_meta       = 1  if ( scalar(keys(%META))      );
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
# 1. the meta information of the data: when has this been extracted from the DB
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
my $number_of_platform_multipolygon_relations           = 0;
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

foreach $relation_id ( sort ( keys ( %RELATIONS ) ) ) {

    $number_of_relations++;

    $ref        = $RELATIONS{$relation_id}->{'tag'}->{'ref'};
    $type       = $RELATIONS{$relation_id}->{'tag'}->{'type'};

    if ( $type ) {
        #
        # first analyze route_master and route relations
        #
        if ( $type eq 'route_master' || $type eq 'route' ) {

            $route_type   = $RELATIONS{$relation_id}->{'tag'}->{$RELATIONS{$relation_id}->{'tag'}->{'type'}};

            $relation_ptr = undef;

            if ( $route_type ) {

                $number_of_route_relations++;

                $relation_ptr = $RELATIONS{$relation_id};

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
                    if ( $status =~ m/keep/ ) { $status = match_network(  $relation_ptr->{'tag'}->{'network'} ); }

                    if ( $status =~ m/keep/ ) {
                        # match_operator() returns either "keep" or "skip"
                        #
                        $status = match_operator( $relation_ptr->{'tag'}->{'operator'} );

                        if ( $status =~ m/keep/ ) {
                            if ( $RELATIONS{$relation_id}->{'tag'}->{'network'} ) {
                                $used_networks{$relation_ptr->{'tag'}->{'network'}}->{$relation_id} = 1;
                            }
                            else {
                                $used_networks{'__unset_network__'}->{$relation_id} = 1;
                            }
                        } else {
                            if ( $RELATIONS{$relation_id}->{'tag'}->{'operator'} ) {
                                $unused_operators{$relation_ptr->{'tag'}->{'operator'}}{$relation_id} = 1;
                            }
                            else {
                                $unused_operators{'__unset_operator__'}->{$relation_id} = 1;
                            }
                        }
                    } elsif ( $status ne 'well_known' ) {
                        if ( $RELATIONS{$relation_id}->{'tag'}->{'network'} ) {
                            $unused_networks{$relation_ptr->{'tag'}->{'network'}}{$relation_id} = 1;
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

                    if ( $debug ) {
                        printf STDERR "%-15s: ref=%s", $status, $ref;
                        printf STDERR "\ttype=%s", $type;
                        printf STDERR "\troute_type=%s", $route_type;
                        printf STDERR "\tnetwork=%s", $relation_ptr->{'tag'}->{'network'};
                        printf STDERR "\toperator=%s", ($relation_ptr->{'tag'}->{'operator'} || '');
                        printf STDERR "\tRelation: %d\n", $relation_id;
                    }

                    $section = undef;
                    if ( $status =~ m/(positive|negative|skip|other|suspicious|well_known)/ ) {
                        $section= $1;
                    }

                    if ( $section ) {
                        if ( $section eq 'positive' || $section eq 'negative' ) {
                            my $ue_ref = $ref;
                            $PT_relations_with_ref{$section}->{$ue_ref}->{$type}->{$route_type}->{$relation_id} = $relation_ptr;
                        } elsif ( $section eq 'other' || $section eq 'suspicious' ) {
                            $suspicious_relations{$relation_id} = 1;
                        }
                    } elsif ( $verbose ) {
                        printf STDERR "%s Section mismatch 'status' = '%s'\n", get_time(), $status;
                    }
                } else {
                    $status = match_route_type( $route_type );
                    printf STDERR "%-15s: ref=undef\ttype=%s\troute_type=%s\tRelation: %d\n", $status, $type, $route_type, $relation_id   if ( $debug );

                    if ( $status eq 'keep' || $status eq 'suspicious' ) {
                        # only supported route types or their typos must have 'ref' set

                        $PT_relations_without_ref{$route_type}->{$relation_id} = $relation_ptr;

                        # match_network() returns either "keep long" or "keep short" or "skip"
                        #
                        my $status = match_network( $relation_ptr->{'tag'}->{'network'} );
                        if ( $status =~ m/keep/ ) {
                            # match_operator() returns either "keep" or "skip"
                            #
                            $status = match_operator( $relation_ptr->{'tag'}->{'operator'} );

                            if ( $status =~ m/keep/ ) {
                                if ( $relation_ptr->{'tag'}->{'network'} ) {
                                    $used_networks{$relation_ptr->{'tag'}->{'network'}}->{$relation_id} = 1;
                                }
                                else {
                                    $used_networks{'__unset_network__'}->{$relation_id} = 1;
                                }
                            } else {
                                if ( $relation_ptr->{'tag'}->{'operator'} ) {
                                    $unused_operators{$relation_ptr->{'tag'}->{'operator'}}{$relation_id} = 1;
                                }
                                else {
                                    $unused_operators{'__unset_operator__'}->{$relation_id} = 1;
                                }
                            }
                        } else {
                            if ( $relation_ptr->{'tag'}->{'network'} ) {
                                $unused_networks{$relation_ptr->{'tag'}->{'network'}}->{$relation_id} = 1;
                            } else {
                                $unused_networks{'__unset_network__'}->{$relation_id} = 1;
                            }
                        }
                        if ( $status eq 'suspicious' ) {
                            $suspicious_relations{$relation_id} = 1;
                        }
                    } else {
                        if ( $status eq 'other' ) {
                            # at least all others (except well_known) shall also be reported as 'suspicious'
                            $suspicious_relations{$relation_id} = 1;
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
            }
        } elsif ( $type eq 'multipolygon' ) {
            #
            # analyze multipolygon relations
            #
            if ( $RELATIONS{$relation_id}->{'tag'}->{'public_transport'}               &&
                 $RELATIONS{$relation_id}->{'tag'}->{'public_transport'} eq 'platform'    ) {
                $platform_multipolygon_relations{$relation_id} = $RELATIONS{$relation_id};
            } else {
                #printf STDERR "%s Suspicious: wrong type=multipolygon (not public_transport=platform) for relation id %s\n", get_time(), $relation_id;
                $suspicious_relations{$relation_id} = 1;
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
            }
        }
    } else {
        #printf STDERR "%s Suspicious: unset 'type' for relation id %s\n", get_time(), $relation_id;
        $suspicious_relations{$relation_id} = 1;
    }
}

$number_of_positive_relations               = scalar( keys ( %{$PT_relations_with_ref{'positive'}} ) );
$number_of_negative_relations               = scalar( keys ( %{$PT_relations_with_ref{'negative'}} ) );
$number_of_suspicious_relations             = scalar( keys ( %suspicious_relations ) );
$number_of_platform_multipolygon_relations  = scalar( keys ( %platform_multipolygon_relations ) );
$number_of_relations_without_ref            = scalar( keys ( %PT_relations_without_ref ) );

if ( $verbose ) {
    printf STDERR "%s Relations converted: %d, route_relations: %d, platform_mp_relations: %d, positive: %d, negative: %d, w/o ref: %d, suspicious: %d\n",
                   get_time(),
                   $number_of_relations,
                   $number_of_route_relations,
                   $number_of_platform_multipolygon_relations,
                   $number_of_positive_relations,
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
            if ( $WAYS{$way_id}->{'first_node'} && $WAYS{$way_id}->{'last_node'} && $WAYS{$way_id}->{'first_node'}  == $WAYS{$way_id}->{'last_node'} ) {
                $WAYS{$way_id}->{'is_roundabout'} = 1;
            }
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

if ( scalar( @RouteList ) ) {

    $section = 'positive';

    my $table_headers_printed           = 0;
    my @list_of_matching_relation_ids   = ();
    my $number_of_matching_entries      = 0;
    my $CheckNetwork                    = '';

    printTableInitialization( 'name', 'type', 'relation', 'PTv', 'issues', 'notes' );

    foreach my $entryref ( @RouteList ) {

        #printf STDERR "Entry: type = %s\n", $entryref->{'type'};

        if ( $entryref->{'type'} eq 'route' ) {

            printf STDERR "    ref = %s, ref-or-list = '%s', ref-and-list = '%s', route = %s, comment = %s, from = %s, to = %s, operator = %s, gtfs-feed = %s, gtfs-route_id = %s, gtfs-release-date = %s\n", $entryref->{'ref'}, join( ', ', @{$entryref->{'ref-or-list'}} ), join( ', ', @{$entryref->{'ref-and-list'}} ), $entryref->{'route'}, $entryref->{'comment'}, $entryref->{'from'}, $entryref->{'to'}, $entryref->{'operator'}, $entryref->{'gtfs-feed'}, $entryref->{'gtfs-route-id'}, $entryref->{'gtfs-release-date'}  if ( $debug );

            if ( $table_headers_printed == 0 ) {
                printTableHeader();
                $table_headers_printed++;
            }

            @list_of_matching_relation_ids = SearchMatchingRelations(   'SearchListRef'             =>  $PT_relations_with_ref{$section},
                                                                        'EntryRef'                  =>  $entryref,
                                                                     );

            $number_of_matching_entries = scalar @list_of_matching_relation_ids;

            if ( $number_of_matching_entries ) {

                for ( my $i=0; $i < $number_of_matching_entries; $i++ ) {
                    $relation_id  = $list_of_matching_relation_ids[$i];
                    $relation_ptr = $RELATIONS{$relation_id};

                    printf STDERR "%s Found: Relation-ID %s, Type: %s, Ref: %s, RouteType: %s\n", get_time(), $relation_id, $RELATIONS{$relation_id}->{'tag'}->{'type'}, $RELATIONS{$relation_id}->{'tag'}->{'ref'}, $RELATIONS{$relation_id}->{'tag'}->{$RELATIONS{$relation_id}->{'tag'}->{'type'}}    if ( $debug );

                    if ( $i == 0 ) {
                        printTableSubHeader( 'ref-or-list'       => $entryref->{'ref-or-list'},              # is a pointer to an array: ('23') or also ('43', 'E43') for multiple 'ref' values
                                             'network'           => $relation_ptr->{'tag'}->{'network'},     # take 'network' value from first relation, undef outside this for-loop
                                             'operator'          => $relation_ptr->{'tag'}->{'operator'},    # take 'operator' value from first relation, undef outside this for-loop
                                             'pt_type'           => $entryref->{'route'},
                                             'colour'            => $relation_ptr->{'tag'}->{'colour'},      # take 'colour' value from first relation, undef outside this for-loop
                                             'CSV-Comment'       => $entryref->{'comment'},
                                             'CSV-From'          => $entryref->{'from'},
                                             'CSV-From-List'     => $entryref->{'from-list'},
                                             'CSV-To'            => $entryref->{'to'},
                                             'CSV-To-List'       => $entryref->{'to-list'},
                                             'CSV-Operator'      => $entryref->{'operator'},
                                             'GTFS-Feed'         => $entryref->{'gtfs-feed'},
                                             'GTFS-Route-Id'     => $entryref->{'gtfs-route-id'},
                                             'GTFS-Release-Date' => $entryref->{'gtfs-release-date'},
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
                                    'PTv'           =>    $relation_ptr->{'tag'}->{'public_transport:version'},
                                    'issues'        =>    join( '__separator__', @{$relation_ptr->{'__issues__'}} ),
                                    'notes'         =>    join( '__separator__', @{$relation_ptr->{'__notes__'}}  )
                                  );
                    $relation_ptr->{'__printed__'}++;
                    $number_of_positive_relations++;

                    $CheckNetwork = $relation_ptr->{'tag'}->{'network'} || '__unset_network__';
                    if ( exists($unused_networks{$CheckNetwork}) && exists($unused_networks{$CheckNetwork}->{$relation_id}) ) {
                        delete( $unused_networks{$CheckNetwork}->{$relation_id} );
                        $added_networks{$CheckNetwork}->{$relation_id} = 0;
                    }
                }
            } else {
                #
                # we do not have a line which fits to the requested 'ref' and 'route_type' combination
                #
                printTableSubHeader( 'ref-or-list'       => $entryref->{'ref-or-list'},
                                     'pt_type'           => $entryref->{'route'},
                                     'CSV-Comment'       => $entryref->{'comment'},
                                     'CSV-From'          => $entryref->{'from'},
                                     'CSV-From-List'     => $entryref->{'from-list'},
                                     'CSV-To'            => $entryref->{'to'},
                                     'CSV-To-List'       => $entryref->{'to-list'},
                                     'CSV-Operator'      => $entryref->{'operator'},
                                     'GTFS-Feed'         => $entryref->{'gtfs-feed'},
                                     'GTFS-Route-Id'     => $entryref->{'gtfs-route-id'},
                                     'GTFS-Release-Date' => $entryref->{'gtfs-release-date'},
                                   );

                $issues_string = gettext( "Missing route for ref='%s' and route='%s'" );

                if ( $entryref->{'ref-or-list'} ) {
                    printTableLine( 'issues' => sprintf($issues_string, join(gettext("' or ref='"),@{$entryref->{'ref-or-list'}}), $entryref->{'route'} ) );
                } else {
                    printTableLine( 'issues' => sprintf($issues_string, '???', $entryref->{'route'} ) );
                }
            }
        } elsif ( $entryref->{'type'} eq 'header' ) {
            printf STDERR "    header = %s\n", $entryref->{'header'}        if ( $debug );
            printTableFooter()                                              if ( $table_headers_printed );
            $table_headers_printed = 0;
            printHeader( $entryref->{'header'}, $entryref->{'level'} );
        } elsif ( $entryref->{'type'} eq 'text' ) {
            printf STDERR "    text = %s\n", $entryref->{'text'}            if ( $debug );
            printTableFooter()                                              if ( $table_headers_printed );
            $table_headers_printed = 0;
            printText( $entryref->{'text'} );
        } elsif ( $entryref->{'type'} eq 'reserved' ) {
            printf STDERR "    reserved = %s\n", $entryref->{'reserved'}    if ( $debug );
            printTableFooter()                                              if ( $table_headers_printed );
            $table_headers_printed = 0;
            printText( '' );
            printText( $entryref->{'reserved'} );
            printText( '' );
        } elsif ( $entryref->{'type'} eq 'error' ) {
            printf STDERR "    error = %s\n", $entryref->{'error'}          if ( $debug );
            if ( $table_headers_printed == 0 ) {
                printTableHeader();
                $table_headers_printed++;
            }
            printTableSubHeader( 'ref' => $entryref->{'ref'} );
            printTableLine( 'issues' => $entryref->{'error'} );
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

if ( scalar( @RouteList ) ) {

    $section = 'positive';

    my $CheckNetwork = '';
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

        # xgettext: This section will list all routes which could not be clearly assigned because the combination of "ref;type" appears more than once and information like 'operator', 'from' and 'to' is missing
        printHeader( gettext('Not clearly assigned routes'), 1, 'unassigned' );
        printHintUnassignedRelations();
        printTableHeader();

        foreach $relation_id ( @relation_ids ) {
            $relation_ptr = $RELATIONS{$relation_id};

            @{$relation_ptr->{'__issues__'}} = ();  # just in case that this route has already been analyzed before (--multiple-ref-type-enries=allow)
            @{$relation_ptr->{'__notes__'}}  = ();  # just in case that this route has already been analyzed before (--multiple-ref-type-enries=allow)

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
                            'PTv'           =>    $relation_ptr->{'tag'}->{'public_transport:version'},
                            'issues'        =>    join( '__separator__', @{$relation_ptr->{'__issues__'}} ),
                            'notes'         =>    join( '__separator__', @{$relation_ptr->{'__notes__'}} )
                          );
            $number_of_unassigned_relations++;

            $CheckNetwork = $relation_ptr->{'tag'}->{'network'} || '__unset_network__';
            if ( exists($unused_networks{$CheckNetwork}) && exists($unused_networks{$CheckNetwork}->{$relation_id}) ) {
                delete( $unused_networks{$CheckNetwork}->{$relation_id} );
                $added_networks{$CheckNetwork}->{$relation_id} = 0;
            }
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
    my $CheckNetwork     = '';

    printTableInitialization( 'ref', 'relation', 'type', 'route_type', 'name', 'network', 'operator', 'from', 'via', 'to', 'PTv', 'issues', 'notes' );

    if ( scalar( @RouteList ) ) {
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

                        @{$relation_ptr->{'__issues__'}} = ();  # just in case that this route has already been analyzed before (--multiple-ref-type-enries=allow)
                        @{$relation_ptr->{'__notes__'}}  = ();  # just in case that this route has already been analyzed before (--multiple-ref-type-enries=allow)

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
                                        'PTv'           =>    $relation_ptr->{'tag'}->{'public_transport:version'},
                                        'issues'        =>    join( '__separator__', @{$relation_ptr->{'__issues__'}} ),
                                        'notes'         =>    join( '__separator__', @{$relation_ptr->{'__notes__'}} )
                                      );
                        $number_of_negative_relations++;

                        $CheckNetwork = $relation_ptr->{'tag'}->{'network'} || '__unset_network__';
                        if ( exists($unused_networks{$CheckNetwork}) && exists($unused_networks{$CheckNetwork}->{$relation_id}) ) {
                            delete( $unused_networks{$CheckNetwork}->{$relation_id} );
                            $added_networks{$CheckNetwork}->{$relation_id} = 0;
                        }
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
                            'PTv'           =>    $relation_ptr->{'tag'}->{'public_transport:version'},
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

printHintUsedNetworks();

printHintAddedNetworks();

printHintUnusedNetworks();

printf STDERR "%s Printed network details\n", get_time()       if ( $verbose );


#############################################################################################
#
# now we print the list of all referenced GTFS feeds
#
#############################################################################################

if ( scalar(keys(%gtfs_relation_info_from)) || scalar(keys(%gtfs_csv_info_from)) ) {
    printf STDERR "%s 'GTFS' details\n", get_time()       if ( $verbose );

    printHeader( gettext("References to GTFS feeds and releases"), 1, 'gtfsreferences' );

    printGtfsReferences();
}

printf STDERR "%s Printed GTFS details\n", get_time()       if ( $verbose );


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
            my $network_with = ';' . $network . ';';        # we match only with sourrounding ';', i.e. 'DB InterCity' does not match network='DB InterCityExpress'
                                                            # i.e. "Sénar Bus" does not match "Seine Sénar Bus"
            if ( $network_short_regex ) {
                foreach my $short_value ( split('\|',$network_short_regex) ) {
                    if ( $network_with =~ m/[;,]\s*(\Q$short_value\E)\s*[;,]\s*/ ) {
                        return 'keep short';
                    }
                }
            }
            if ( $network_long_regex ) {
                foreach my $long_value ( split('\|',$network_long_regex) ) {
                    if ( $network_with =~ m/[;,]\s*(\Q$long_value\E)\s*[;,]\s*/ ) {
                        return 'keep long';
                    }
                }
            }
            printf STDERR "%s Skipping network: %s\n", get_time(), $network        if ( $debug );
            return 'skip';
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
#
# return a list of matching route and route-master relations
#
#############################################################################################


sub SearchMatchingRelations {
    my %hash                        = ( @_ );

    my $SearchListRef               = $hash{'SearchListRef'};
    my $EntryRef                    = $hash{'EntryRef'};

    my $ExpRef                      = $EntryRef->{'ref'}                              || '';
    my $ExpRefOrList                = $EntryRef->{'ref-or-list'};
    my $ExpRouteType                = $EntryRef->{'route'}                            || '';
    my $RelRef                      = undef;
    my $RelRouteType                = undef;
    my $RelOperator                 = undef;
    my $RelFrom                     = undef;
    my $RelTo                       = undef;
    my $match                       = undef;

    my @return_list                 = ();

    my %selected_route_masters      = ();
    my %selected_routes             = ();

    my @ExpRefOrArray               = ();
    my %ExpRefHash                  = ();

    if ( $ExpRefOrList ) {
        @ExpRefOrArray = @{$ExpRefOrList};
    } elsif ( $ExpRef ) {
        push( @ExpRefOrArray, $ExpRef );
    }

    map { $ExpRefHash{$_} = 1; } @ExpRefOrArray;

    if ( $SearchListRef ) {

        if ( scalar @ExpRefOrArray && $ExpRouteType ) {

            foreach my $ExpRefPart ( @ExpRefOrArray ) {

                my $relations_for_this_route_type = scalar(keys(%{$SearchListRef->{$ExpRefPart}->{'route_master'}->{$ExpRouteType}})) +
                                                    scalar(keys(%{$SearchListRef->{$ExpRefPart}->{'route'}->{$ExpRouteType}}));
                if ( $relations_for_this_route_type ) {

                    foreach my $type ( 'route', 'route_master' ) {
                        #
                        # check 'route' first
                        # so that in case of a need to check 'from' and 'to', 'route_master' can rely on 'route' information.
                        # i.e. if 'route' is selected, then it's 'route_master' also?
                        #
                        if ( $SearchListRef->{$ExpRefPart}->{$type} && $SearchListRef->{$ExpRefPart}->{$type}->{$ExpRouteType} ) {

                            foreach my $rel_id ( keys( %{$SearchListRef->{$ExpRefPart}->{$type}->{$ExpRouteType}} ) ) {

                                $RelRef         = $RELATIONS{$rel_id}->{'tag'}->{'ref'}      || '';
                                $RelRouteType   = $RELATIONS{$rel_id}->{'tag'}->{$type}      || '';
                                $RelOperator    = $RELATIONS{$rel_id}->{'tag'}->{'operator'} || '';
                                $RelFrom        = $RELATIONS{$rel_id}->{'tag'}->{'from'}     || '';
                                $RelTo          = $RELATIONS{$rel_id}->{'tag'}->{'to'}       || '';

                                printf STDERR "%s Checking %s relation %s, 'ref' %s and  'operator' %s \n", get_time(), $type, $rel_id, $ExpRefPart, $RelOperator    if ( $debug );

                                $match  = RoutesList::RelationMatchesExpected(  'rel-id'                      => $rel_id,
                                                                                'rel-ref'                     => $RelRef,
                                                                                'rel-route-type'              => $RelRouteType,
                                                                                'rel-operator'                => $RelOperator,
                                                                                'rel-from'                    => $RelFrom,
                                                                                'rel-to'                      => $RelTo,
                                                                                'EntryRef'                    => $EntryRef,
                                                                                'multiple_ref_type_entries'   => $multiple_ref_type_entries,
                                                                             );
                                printf STDERR "%s Checking == %s\n", get_time(), $match     if ( $debug );

                                if ( !$match ) {
                                    if ( $type eq 'route_master' ) {

                                        # route_masters usually don't have 'from' or 'to' set: let's try something different in case we don't have a direct match

                                        printf STDERR "%s Route-Master w/o values: %s\n", get_time(), $rel_id   if ( $debug );

                                        foreach my $member_rel_ref ( @{$RELATIONS{$rel_id}->{'route_master_relation'}} ) {
                                            printf STDERR "%s Route-Master w/o values: %s - check Member %s\n", get_time(), $rel_id, $member_rel_ref->{'ref'}   if ( $debug );
                                            if ( $selected_routes{$member_rel_ref->{'ref'}} ) {
                                                # member route has been selected, from and/or to match, so let's assume, the route_master matches as well
                                                $match = $member_rel_ref->{'ref'};
                                                last;
                                            }
                                        }
                                    }
                                }
                                if ( $match ) {
                                    if ( $type eq 'route_master' ) {
                                        $selected_route_masters{$rel_id} = 1;
                                    } else {
                                        $selected_routes{$rel_id} = 1;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    } else {
        printf STDERR "%s SearchMatchingRelations(): no Search List specified\n", get_time();
    }

    foreach my $rel_id ( keys( %selected_routes ) ) {

        # route_masters of selected routes also match, but check some basic settings first

        foreach my $route_master_rel_id ( keys ( %{$RELATIONS{$rel_id}->{'member_of_route_master'}} ) ) {
            printf STDERR "%s Route-Master Relations of selected Routes also match: %s - Master %s\n", get_time(), $rel_id, $route_master_rel_id   if ( $debug );
            if ( !exists($selected_route_masters{$route_master_rel_id})                         &&
                 $RELATIONS{$route_master_rel_id}                                               &&
                 $RELATIONS{$route_master_rel_id}->{'tag'}                                      &&
                 $RELATIONS{$route_master_rel_id}->{'tag'}->{'type'}                            &&
                 $RELATIONS{$route_master_rel_id}->{'tag'}->{'type'}  eq 'route_master'         &&
                 $RELATIONS{$route_master_rel_id}->{'tag'}->{'route_master'}                    &&
                 $RELATIONS{$route_master_rel_id}->{'tag'}->{'route_master'} eq $ExpRouteType   &&
                 $RELATIONS{$route_master_rel_id}->{'tag'}->{'ref'}                             &&
                 $ExpRefHash{$RELATIONS{$route_master_rel_id}->{'tag'}->{'ref'}}                    ) {
                printf STDERR "Add route_master %s of route %s\n", $route_master_rel_id, $rel_id   if ( $debug );
                $selected_route_masters{$route_master_rel_id} = 1;
            }
        }
    }
    foreach my $rel_id ( keys( %selected_route_masters ) ) {

        # members of selected route_masters also match, but check some basic settings first

        foreach my $member_rel_ref ( @{$RELATIONS{$rel_id}->{'route_master_relation'}} ) {
            printf STDERR "%s Relations of selected Route-Master also match: %s - Member %s\n", get_time(), $rel_id, $member_rel_ref->{'ref'}   if ( $debug );
            if ( !exists($selected_routes{$member_rel_ref->{'ref'}})                       &&
                 $RELATIONS{$member_rel_ref->{'ref'}}                                      &&
                 $RELATIONS{$member_rel_ref->{'ref'}}->{'tag'}                             &&
                 $RELATIONS{$member_rel_ref->{'ref'}}->{'tag'}->{'type'}                   &&
                 $RELATIONS{$member_rel_ref->{'ref'}}->{'tag'}->{'type'}  eq 'route'       &&
                 $RELATIONS{$member_rel_ref->{'ref'}}->{'tag'}->{'route'}                  &&
                 $RELATIONS{$member_rel_ref->{'ref'}}->{'tag'}->{'route'} eq $ExpRouteType &&
                 $RELATIONS{$member_rel_ref->{'ref'}}->{'tag'}->{'ref'}                    &&
                 $ExpRefHash{$RELATIONS{$member_rel_ref->{'ref'}}->{'tag'}->{'ref'}}          ) {
                printf STDERR "Add member route %s of route_master %s\n", $member_rel_ref->{'ref'}, $rel_id   if ( $debug );
                $selected_routes{$member_rel_ref->{'ref'}} = 1;
            }
        }
    }

    map { push( @return_list, $_ ); } sort( { $RELATIONS{$a}->{'__sort_name__'} cmp $RELATIONS{$b}->{'__sort_name__'} } keys( %selected_route_masters ) );
    map { push( @return_list, $_ ); } sort( { $RELATIONS{$a}->{'__sort_name__'} cmp $RELATIONS{$b}->{'__sort_name__'} } keys( %selected_routes        ) );

    if ( $debug ) {
        map { printf STDERR "SearchMatchingRelations: Rel-ID = %s, type = %s, ref = %s, name = %s\n",
                                                               $_,
                                                                          $RELATIONS{$_}->{'tag'}->{'type'},
                                                                                    $RELATIONS{$_}->{'tag'}->{'ref'},
                                                                                                $RELATIONS{$_}->{'tag'}->{'name'};
            } sort( { $RELATIONS{$a}->{'__sort_name__'} cmp $RELATIONS{$b}->{'__sort_name__'} } keys( %selected_route_masters ) );
        map { printf STDERR "SearchMatchingRelations: Rel-ID = %s, type = %s, ref = %s, name = %s\n",
                                                               $_,
                                                                          $RELATIONS{$_}->{'tag'}->{'type'},
                                                                                    $RELATIONS{$_}->{'tag'}->{'ref'},
                                                                                                $RELATIONS{$_}->{'tag'}->{'name'};
            } sort( { $RELATIONS{$a}->{'__sort_name__'} cmp $RELATIONS{$b}->{'__sort_name__'} } keys( %selected_routes ) );
    }

    return ( @return_list );
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
    my $route_master_network    = undef;

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
                $issues_string = gettext( "There is more than one Route-Master" );
                push( @{$relation_ptr->{'__issues__'}}, $issues_string );
            }

            if ( $number_of_my_routes > $number_of_routes ) {
                $issues_string = ngettext( "Route-Master has more Routes than actually match (%d versus %d) in the given data set", "Route-Masters have more Routes than actually match (%d versus %d) in the given data set", $number_of_route_masters );
                push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, $number_of_my_routes, $number_of_routes) );
            } elsif ( $number_of_my_routes < $number_of_routes ) {
                $issues_string = ngettext( "Route-Master has less Routes than actually match (%d versus %d) in the given data set", "Route-Masters have less Routes than actually match (%d versus %d) in the given data set", $number_of_route_masters );
                push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, $number_of_my_routes, $number_of_routes) );
            }
        } else {
            # how many routes are members of this route_master?
            $number_of_my_routes        = scalar( @{$relation_ptr->{'route_master_relation'}} );

            if ( $number_of_my_routes > $number_of_routes ) {
                $issues_string = ngettext( "Route-Master has more Routes than actually match (%d versus %d) in the given data set", "Route-Masters have more Routes than actually match (%d versus %d) in the given data set", $number_of_route_masters );
                push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, $number_of_my_routes, $number_of_routes) );
            } elsif ( $number_of_my_routes < $number_of_routes ) {
                $issues_string = ngettext( "Route-Master has less Routes than actually match (%d versus %d) in the given data set", "Route-Masters have less Routes than actually match (%d versus %d) in the given data set", $number_of_route_masters );
                push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, $number_of_my_routes, $number_of_routes) );
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
                    # relation is included in XML input file check for settings
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

                                                $route_master_network = ';' . $relation_ptr->{'tag'}->{'network'} . ';';

                                                if ( $relation_ptr->{'tag'}->{'network'} eq $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'}  ||
                                                     $route_master_network =~ m/;\Q$RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'}\E;/          ) {

                                                    if ( $route_master_network =~ m/;\Q$RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'}\E;/  ) {
                                                        $notes_string = gettext( "Route has 'network' = '%s' value which is part of 'network' = '%s' of Route-Master: %s" );
                                                        push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'}), html_escape($relation_ptr->{'tag'}->{'network'}), printRelationTemplate($member_ref->{'ref'})) );
                                                    }

                                                    #printf STDERR "%s Route of Route-Master not found although 'ref' is valid and 'network' are equal. Route-Master: %s, Route: %s, 'ref': %s, 'network': %s\n", get_time(), $relation_id, $member_ref->{'ref'}, $members_ref, html_escape($relation_ptr->{'tag'}->{'network'});
                                                    if ( $relation_ptr->{'tag'}->{'operator'} && $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'operator'} ) {
                                                        if ( $relation_ptr->{'tag'}->{'operator'} eq $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'operator'} ) {
                                                            #printf STDERR "%s Route of Route-Master not found although 'ref' is valid and 'operator' are equal. Route-Master: %s, Route: %s, 'ref': %s, 'operator': %s\n", get_time(), $relation_id, $member_ref->{'ref'}, $members_ref, html_escape($relation_ptr->{'tag'}->{'operator'});
                                                            # 'ref' tag is valid (in the list) 'operator' is OK, any other reason
                                                            $issues_string = gettext( "Route might be listed with 'ref' = '%s' in a different section or in section 'Not clearly assigned routes' of this analysis: %s" );
                                                            push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, $members_ref, printRelationTemplate($member_ref->{'ref'}) ) );
                                                        } else {
                                                            # 'ref' tag is valid (in the list) but 'operator' is set and differs
                                                            $issues_string = gettext( "Route has different 'operator' = '%s' than Route-Master 'operator' = '%s': %s" );
                                                            push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'operator'}), html_escape($relation_ptr->{'tag'}->{'operator'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                                        }
                                                    } elsif ( $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'operator'} ) {
                                                        # 'ref' tag is valid (in the list) but 'operator' is strange
                                                        $issues_string = gettext( "Route has 'operator' = '%s' value which is considered as not relevant: %s" );
                                                        push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'operator'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                                    }
                                                } else {
                                                    # 'ref' tag is valid (in the list) but 'network' is set and differs
                                                    $issues_string = gettext( "Route has different 'network' = '%s' than Route-Master 'network' = '%s': %s" );
                                                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'}), html_escape($relation_ptr->{'tag'}->{'network'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                                }
                                            } elsif ( $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'} ) {
                                                # 'ref' tag is valid (in the list) but 'network' is strange
                                                $notes_string = gettext( "Route has 'network' = '%s' value which is considered as not relevant: %s" );
                                                push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'network'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                            }
                                            if ( $members_ref ne $masters_ref ) {
                                                # 'members_ref' is valid (in the list) but differs from 'ref' of route-master, so we have at least two refs in the list (a real list)
                                                #$notes_string = gettext( "Route has different 'ref' = '%s' than Route-Master 'ref' = '%s' - this should be avoided: %s" );
                                                #push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, $members_ref, $masters_ref, printRelationTemplate($member_ref->{'ref'}) ) );
                                                ;
                                            }
                                        } else {
                                            # 'ref' tag is set but is not valid, not in list
                                            $issues_string = gettext( "Route has not matching 'ref' = '%s': %s" );
                                            push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, $members_ref, printRelationTemplate($member_ref->{'ref'}) ) );
                                        }
                                    } else {
                                        # 'ref' tag is not set
                                        $issues_string = gettext( "Route exists in the given data set but 'ref' tag is not set: %s" );
                                        push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, printRelationTemplate($member_ref->{'ref'}) ) );
                                    }
                                } else {
                                    # 'ref' tag is valid (in the list) but 'route' is set and differs from 'route_master'
                                    $issues_string = gettext( "Route has different 'route' = '%s' than Route-Master 'route_master' = '%s': %s" );
                                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'route'}), html_escape($relation_ptr->{'tag'}->{'route_master'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                }
                            } else {
                                if ( $RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'route'} ) {
                                    # 'route' is strange
                                    $issues_string = gettext( "Route has 'route' = '%s' value which is considered as not relevant: %s" );
                                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'route'}), printRelationTemplate($member_ref->{'ref'}) ) );
                                } else {
                                    # 'route' is not set
                                    $issues_string = gettext( "'route' tag is not set: %s" );
                                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, printRelationTemplate($member_ref->{'ref'}) ) );
                                }
                            }
                        } else {
                            # 'type' is strange
                            $issues_string = gettext( "'type' = '%s' is not 'route': %s" );
                            push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, html_escape($RELATIONS{$member_ref->{'ref'}}->{'tag'}->{'type'}), printRelationTemplate($member_ref->{'ref'}) ) );
                        }
                    } else {
                        # 'type' is not set
                        $issues_string = gettext( "'type' tag is not set: %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, printRelationTemplate($member_ref->{'ref'}) ) );
                    }
                } else {
                    #
                    # relation is not included in XML input file
                    #
                    $issues_string = gettext( "Route does not exist in the given data set: %s" );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, printRelationTemplate($member_ref->{'ref'}) ) );
                }
            }
        }
        # check whether all found relations are member of this/these route master(s), tell us which one is not
        foreach my $rel_id ( sort( keys( %{$env_ref->{'route'}->{$route_type}} ) ) ) {
            if ( !defined($my_routes{$rel_id}) ) {
                $issues_string = gettext( "Route is not member of Route-Master: %s" );
                push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, printRelationTemplate($rel_id) ) );
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

    my $relation_ptr                            = undef;
    my $number_of_direct_route_masters          = 0;
    my $number_of_route_masters                 = 0;
    my $number_of_routes                        = 0;
    my %direct_and_matching_route_masters       = ();
    my %allowed_refs                            = ();
    my $masters_ref                             = undef;
    my $routes_ref                              = undef;
    my $route_master_network                    = undef;

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
            $issues_string = gettext( "There is more than one Route-Master" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }
        if ( $number_of_direct_route_masters > $number_of_route_masters ) {
            foreach my $direct_route_master_rel_id ( keys( %{$RELATIONS{$relation_id}->{'member_of_route_master'}}  ) ) {
                if ( !defined($env_ref->{'route_master'}->{$route_type}->{$direct_route_master_rel_id}) ) {
                    if ( $RELATIONS{$direct_route_master_rel_id} && $RELATIONS{$direct_route_master_rel_id}->{'tag'} && $RELATIONS{$direct_route_master_rel_id}->{'tag'}->{'ref'} ) {
                        $masters_ref = $RELATIONS{$direct_route_master_rel_id}->{'tag'}->{'ref'};
                        $issues_string = gettext( "Route-Master might be listed with 'ref' = '%s' in a different section or in section 'Not clearly assigned routes' of this analysis: %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, $masters_ref, printRelationTemplate($direct_route_master_rel_id) ) );
                    } else {
                        $issues_string = gettext( "Route-Master might be listed with unknown 'ref' in section 'Public Transport Lines without 'ref'' of this analysis: %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, $masters_ref, printRelationTemplate($direct_route_master_rel_id) ) );
                    }
                }
            }
        }

        #
        # 2. check direct environment of this route: route_master(s) where this route is member of (independent of PTv2 or not)
        #

        $number_of_routes = scalar( keys( %{$env_ref->{'route'}->{$route_type}} ) );

        if ( $number_of_direct_route_masters > 1 ) {
            $issues_string = gettext( "This Route is direct member of more than one Route-Master: %s" );
            push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, join(', ', map { printRelationTemplate($_); } sort( keys( %{$RELATIONS{$relation_id}->{'member_of_route_master'}} ) ) ) ) );
        } else {
            if ( $number_of_routes > 1 ) {
                if ( $number_of_route_masters == 0 ) {
                    $issues_string = gettext( "Multiple Routes but no Route-Master" );
                    push( @{$relation_ptr->{'__issues__'}}, $issues_string );
                } elsif ( $number_of_direct_route_masters == 0 ) {
                   $issues_string = gettext( "Multiple Routes but this Route is not a member of any Route-Master" );
                    push( @{$relation_ptr->{'__issues__'}}, $issues_string );
                }
            } else {
                # only one route but ... check if there is a route_master
                if ( $number_of_route_masters > 0 && $number_of_direct_route_masters == 0 ) {
                    # there is at least one route_master, but this route is not a member of any
                    $issues_string = gettext( "This Route is not a member of any Route-Master" );
                    push( @{$relation_ptr->{'__issues__'}}, $issues_string );
                }
            }
        }

        #
        # 3. check major tags of this route and the route_masters: they should match
        #

        foreach my $route_master_rel_id ( sort( keys( %direct_and_matching_route_masters ) ) ) {
            if ( $relation_ptr->{'tag'}->{'route'}   && $RELATIONS{$route_master_rel_id}->{'tag'}->{'route_master'} &&
                 $relation_ptr->{'tag'}->{'route'}   ne $RELATIONS{$route_master_rel_id}->{'tag'}->{'route_master'}     ) {
                $issues_string = gettext( "'route' = '%s' of Route does not fit to 'route_master' = '%s' of Route-Master: %s" );
                push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, $relation_ptr->{'tag'}->{'route'}, $RELATIONS{$route_master_rel_id}->{'tag'}->{'route_master'}, printRelationTemplate($route_master_rel_id)) );
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
                        #$notes_string = gettext( "Route has different 'ref' = '%s' than Route-Master 'ref' = '%s' - this should be avoided: %s" );
                        #push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, $routes_ref, $masters_ref, printRelationTemplate($route_master_rel_id) ) );
                        ;
                    }
                } else {
                    $issues_string = gettext( "Route-Master has not matching 'ref' = '%s': %s" );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, $masters_ref, printRelationTemplate($route_master_rel_id)) );
                }
            } else {
                $issues_string = gettext( "Route-Master exists in the given data set but 'ref' tag is not set: %s" );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, printRelationTemplate($route_master_rel_id)) );
            }
            if ( $relation_ptr->{'tag'}->{'network'} && $RELATIONS{$route_master_rel_id}->{'tag'}->{'network'} &&
                 $relation_ptr->{'tag'}->{'network'} ne $RELATIONS{$route_master_rel_id}->{'tag'}->{'network'}     ) {

                $route_master_network = ';' . $RELATIONS{$route_master_rel_id}->{'tag'}->{'network'} . ';';

                if ( $route_master_network =~ m/;\Q$relation_ptr->{'tag'}->{'network'}\E;/  ) {
                    $notes_string = gettext( "'network' = '%s' of Route is a part of 'network' = '%s' of Route-Master: %s" );
                    push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, html_escape($relation_ptr->{'tag'}->{'network'}), html_escape($RELATIONS{$route_master_rel_id}->{'tag'}->{'network'}), printRelationTemplate($route_master_rel_id)) );
                } else {
                    $issues_string = gettext( "'network' = '%s' of Route does not fit to 'network' = '%s' of Route-Master: %s" );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, html_escape($relation_ptr->{'tag'}->{'network'}), html_escape($RELATIONS{$route_master_rel_id}->{'tag'}->{'network'}), printRelationTemplate($route_master_rel_id)) );
                }
            }
            if ( $relation_ptr->{'tag'}->{'operator'} && $RELATIONS{$route_master_rel_id}->{'tag'}->{'operator'} &&
                 $relation_ptr->{'tag'}->{'operator'} ne $RELATIONS{$route_master_rel_id}->{'tag'}->{'operator'}     ) {
                my $help_route_master_opeartor = ';' . $RELATIONS{$route_master_rel_id}->{'tag'}->{'operator'} . ';';
                my $help_route_operator        = ';' . $relation_ptr->{'tag'}->{'operator'} . ';';
                unless ( $help_route_master_opeartor =~ m/\Q$help_route_operator\E/ ) {
                    $issues_string = gettext( "'operator' = '%s' of Route does not fit to 'operator' = '%s' of Route-Master: %s" );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, html_escape($relation_ptr->{'tag'}->{'operator'}), html_escape($RELATIONS{$route_master_rel_id}->{'tag'}->{'operator'}), printRelationTemplate($route_master_rel_id)) );
                }
            }
            if ( $relation_ptr->{'tag'}->{'colour'} ) {
                if ( $RELATIONS{$route_master_rel_id}->{'tag'}->{'colour'} ) {
                    if ( uc($relation_ptr->{'tag'}->{'colour'}) ne uc($RELATIONS{$route_master_rel_id}->{'tag'}->{'colour'}) ) {
                        $issues_string = gettext( "'%s' = '%s' of Route does not fit to '%s' = '%s' of Route-Master: %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, 'colour', $relation_ptr->{'tag'}->{'colour'}, 'colour', $RELATIONS{$route_master_rel_id}->{'tag'}->{'colour'}, printRelationTemplate($route_master_rel_id)) );
                    }
                } else {
                    $issues_string = gettext( "'%s' = '%s' of Route is set but '%s' of Route-Master is not set: %s" );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, , 'colour', $relation_ptr->{'tag'}->{'colour'}, 'colour', printRelationTemplate($route_master_rel_id)) );
                }
            } elsif ( $RELATIONS{$route_master_rel_id}->{'tag'}->{'colour'} ) {
                $issues_string = gettext( "'%s' of Route is not set but '%s' = '%s' of Route-Master is set: %s" );
                push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, 'colour', 'colour', $RELATIONS{$route_master_rel_id}->{'tag'}->{'colour'}, printRelationTemplate($route_master_rel_id)) );
            }

            #
            # --check-gtfs  check gtfs:feed, gtfs:release_date and gtfs:route_id of this route against those of route_master - must match: each of the route's values must be part of route_master's value
            #
            if ( $check_gtfs ) {
                my $help_rtag = '';
                my $help_mtag = '';
                my $mcount    = 0;
                my $tcount    = 0;
                foreach my $gtfs_tag ( 'gtfs:feed', 'gtfs:release_date', 'gtfs:route_id' ) {
                    if ( $relation_ptr->{'tag'}->{$gtfs_tag} ) {
                        if ( $RELATIONS{$route_master_rel_id}->{'tag'}->{$gtfs_tag} ) {
                            $help_rtag = $relation_ptr->{'tag'}->{$gtfs_tag};
                            $help_rtag =~ s/\s*;\s*/;/g;
                            $help_mtag = ';' . $RELATIONS{$route_master_rel_id}->{'tag'}->{$gtfs_tag} . ';';
                            $help_mtag =~ s/\s*;\s*/;/g;
                            $tcount = 0;
                            $mcount = 0;
                            foreach my $rval ( split( /;/, $help_rtag ) ){
                                $tcount++;
                                $mcount++  if ( $help_mtag =~ m/;\Q$rval\E;/ );
                            }
                            if ( $mcount != $tcount ) {
                                $issues_string = gettext( "'%s' = '%s' of Route does not fit to '%s' = '%s' of Route-Master: %s" );
                                push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, $gtfs_tag, $relation_ptr->{'tag'}->{$gtfs_tag}, $gtfs_tag, $RELATIONS{$route_master_rel_id}->{'tag'}->{$gtfs_tag}, printRelationTemplate($route_master_rel_id)) );
                            }
                        } else {
                            $issues_string = gettext( "'%s' = '%s' of Route is set but '%s' of Route-Master is not set: %s" );
                            push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, $gtfs_tag, $relation_ptr->{'tag'}->{$gtfs_tag}, $gtfs_tag, printRelationTemplate($route_master_rel_id)) );
                        }
                    } elsif ( $RELATIONS{$route_master_rel_id}->{'tag'}->{$gtfs_tag} ) {
                        $issues_string = gettext( "'%s' of Route is not set but '%s' = '%s' of Route-Master is set: %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, $gtfs_tag, $gtfs_tag, $RELATIONS{$route_master_rel_id}->{'tag'}->{$gtfs_tag}, printRelationTemplate($route_master_rel_id)) );
                    }
                }
            }
        }

        if ( $number_of_routes > 1 ) {

            # 4. check 'name' tag of this route against the 'name' tag of the other routes, there should be no match, 'name' should be unique

            if ( $check_name                                                &&
                 $relation_ptr->{'tag'}->{'name'}                           &&
                 $relation_ptr->{'tag'}->{'public_transport:version'}       &&
                 $relation_ptr->{'tag'}->{'public_transport:version'} eq '2'   ) {

                my %name_matches = ();

                foreach my $peer_route_relation_id ( keys ( %{$env_ref->{'route'}->{$route_type}} ) ) {

                    next    if ( $relation_id eq $peer_route_relation_id );

                    if ( $RELATIONS{$peer_route_relation_id}->{'tag'}->{'name'}                             &&
                         $RELATIONS{$peer_route_relation_id}->{'tag'}->{'public_transport:version'}         &&
                         $RELATIONS{$peer_route_relation_id}->{'tag'}->{'public_transport:version'} eq '2'  &&
                         $relation_ptr->{'tag'}->{'name'} eq $RELATIONS{$peer_route_relation_id}->{'tag'}->{'name'}     ) {
                        $name_matches{$peer_route_relation_id} = 1;
                    }
                }

                if ( scalar( keys ( %name_matches ) ) ) {
                    my @help_array    = sort( keys ( %name_matches ) );
                    my $num_of_errors = scalar(@help_array);
                    $notes_string = gettext( "PTv2 route: 'name' of Route is identical to 'name' of other Route(s), consider setting an appropriate 'via' value and include that into 'name'" );
                    if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                        push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("%s: %s and %d more ..."), $notes_string, join(', ', map { printRelationTemplate($_); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                    } else {
                        push( @{$relation_ptr->{'__notes__'}}, sprintf("%s: %s", $notes_string, join(', ', map { printRelationTemplate($_); } @help_array )) );
                    }
                }
            }


            # 5. check for 'public_transport:version' being set to '2' if there is more than one route

            if ( !$relation_ptr->{'tag'}->{'public_transport:version'} || $relation_ptr->{'tag'}->{'public_transport:version'} ne '2' ) {
                $issues_string = gettext( "Multiple Routes but 'public_transport:version' is not set to '2'" );
                push( @{$relation_ptr->{'__issues__'}}, $issues_string );
            }

            #
            # 6.  --check-gtfs  check that gtfs:trip_id, gtfs:trip_id:sample and gtfs:trip_id:like are unique
            #

            if ( $check_gtfs ) {
                my %gtfs_ident = ();
                my %gtfs_match = ();
                my $help_val   = '';
                my $help_pval  = '';

                foreach my $gtfs_tag ( 'gtfs:trip_id', 'gtfs:trip_id:sample', 'gtfs:trip_id:like', 'gtfs:shape_id:sample' ) {
                    %gtfs_ident = ();
                    %gtfs_match = ();

                    foreach my $peer_route_relation_id ( keys ( %{$env_ref->{'route'}->{$route_type}} ) ) {

                        next    if ( $relation_id eq $peer_route_relation_id );

                        if ( $relation_ptr->{'tag'}->{$gtfs_tag} && $RELATIONS{$peer_route_relation_id}->{'tag'}->{$gtfs_tag} ) {
                            if ( $relation_ptr->{'tag'}->{$gtfs_tag} eq $RELATIONS{$peer_route_relation_id}->{'tag'}->{$gtfs_tag} ) {
                                $gtfs_ident{$peer_route_relation_id} = 1;
                            } else {
                                $help_val  = $relation_ptr->{'tag'}->{$gtfs_tag};
                                $help_pval = ';' . $RELATIONS{$peer_route_relation_id}->{'tag'}->{$gtfs_tag} . ';';
                                $help_val  =~ s/\s*;\s*/;/g;
                                $help_pval =~ s/\s*;\s*/;/g;
                                foreach my $val ( split( /;/,$help_val) ) {
                                    if ( $help_pval =~ m/;\Q$val\E;/ ) {
                                        push( @{$gtfs_match{$RELATIONS{$peer_route_relation_id}->{'tag'}->{$gtfs_tag}}}, $peer_route_relation_id );
                                    }
                                }
                            }
                        }
                    }

                    if ( scalar( keys ( %gtfs_ident ) ) ) {
                        my @help_array    = sort( keys ( %gtfs_ident ) );
                        my $num_of_errors = scalar(@help_array);
                        $issues_string  = gettext( "'%s' = '%s' of Route is identical to '%s' of other Route(s)" );
                        my $help_string = sprintf( $issues_string, $gtfs_tag, $relation_ptr->{'tag'}->{$gtfs_tag}, $gtfs_tag );
                        if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                            push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $help_string, join(', ', map { printRelationTemplate($_); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                        } else {
                            push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $help_string, join(', ', map { printRelationTemplate($_); } @help_array )) );
                        }
                    }

                    if ( scalar( keys ( %gtfs_match ) ) ) {
                        foreach my $val ( sort( keys ( %gtfs_match ) ) ) {
                            my @help_array    = sort( @{$gtfs_match{$val}} );
                            my $num_of_errors = scalar(@help_array);
                            $issues_string  = gettext( "'%s' = '%s' of Route has a match with '%s' = '%s' of other Route(s)" );
                            my $help_string = sprintf( $issues_string, $gtfs_tag, $relation_ptr->{'tag'}->{$gtfs_tag}, $gtfs_tag, $val );
                            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $help_string, join(', ', map { printRelationTemplate($_); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                            } else {
                                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $help_string, join(', ', map { printRelationTemplate($_); } @help_array )) );
                            }
                        }
                    }
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
    my @check_osm_separator_tags        = ( 'network', 'ref', 'gtfs' );
    my $check_osm_separator_tag         = undef;
    my $reporttype                      = undef;

    if ( $relation_ptr ) {

        $ref                            = $relation_ptr->{'tag'}->{'ref'};
        $type                           = $relation_ptr->{'tag'}->{'type'};
        $route_type                     = $relation_ptr->{'tag'}->{$type};

        # we need these several times

        my @relation_tags = sort( keys( %{$relation_ptr->{'tag'}} ) );

        #
        # now, check existing and defined tags and report them to front of list (ISSUES, NOTES)
        #

        foreach $specialtag ( @specialtags ) {
            foreach my $tag ( @relation_tags ) {
                if ( $tag =~ m/^\Q$specialtag\E/i ) {
                    if ( $relation_ptr->{'tag'}->{$tag} ) {
                        $reporttype = ( $specialtag2reporttype{$specialtag} ) ? $specialtag2reporttype{$specialtag} : '__notes__';
                        if ( $tag =~ m/^note$/i && $relation_ptr->{'tag'}->{$tag} =~ m|^https{0,1}://wiki.openstreetmap.org\S+\s*[;,_+#\.\-]*\s*(.*)| ) {
                            unshift( @{$relation_ptr->{$reporttype}}, sprintf("'%s' ~ '%s'", $tag, html_escape($1)) )  if ( $1 );
                        } elsif ( $tag =~ m/^note$/i && $relation_ptr->{'tag'}->{$tag} =~ m|^https{0,1}://ptna.openstreetmap.de\S+\s*[;,_+#\.\-]*\s*(.*)| ) {
                            unshift( @{$relation_ptr->{$reporttype}}, sprintf("'%s' ~ '%s'", $tag, html_escape($1)) )  if ( $1 );
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

        unless ( $ref ) {
            $issues_string = gettext( "'ref' is not set" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }
        unless ( $relation_ptr->{'tag'}->{'name'} ) {
            $issues_string = gettext( "'name' is not set" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }

        $network = $relation_ptr->{'tag'}->{'network'};

        if ( $network ) {
            my $match           = '';
            my $we_have_a_match = 0;

            my $network_with = ';' . $network . ';';        # we match only with sourrounding ';', i.e. 'DB InterCity' does not match network='DB InterCityExpress'

            if ( $network_short_regex ) {
                foreach my $short_value ( split('\|',$network_short_regex) ) {
                    if ( $network_with =~ m/[;,]\s*(\Q$short_value\E)\s*[;,]\s*/ ) {
                        $match = $1;
                        if ( $positive_notes ) {
                            if ( $network eq $match ) {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf( "'network' = '%s'", html_escape($match)) );
                            } else {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf( "'network' ~ '%s'", html_escape($match) ) );
                            }
                        }
                        $we_have_a_match++;
                    }
                }
            }
            if ( $network_long_regex ) {
                foreach my $long_value ( split('\|',$network_long_regex) ) {
                    if ( $network_with =~ m/[;,]\s*(\Q$long_value\E)\s*[;,]\s*/ ) {
                        $match = $1;
                        if ( $positive_notes ) {
                            if ( $network eq $match ) {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf("'network' = '%s'",html_escape($match)) );
                            } else {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf("'network' ~ '%s'",html_escape($match)) );
                            }
                        }
                        $we_have_a_match++;
                    }
                }
            }
            if ( $we_have_a_match == 0 && ($network_long_regex || $network_short_regex) ) {
                $notes_string = gettext( "Route has 'network' = '%s' value which is considered as not relevant: %s" );
                push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, html_escape($network), printRelationTemplate($relation_id) ) );
                if ( $positive_notes ) {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf( "'network' = '%s'", html_escape($network)) );
                }
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
                        $notes_string = gettext( "'network' = '%s' should be short form" );
                        push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, html_escape($match_long) ) );
                    }
                } elsif ( $match_short ) {
                    if ( $match_short eq $expect_long_for ) {
                        $notes_string = gettext( "'network' = '%s' should be long form" );
                        push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, html_escape($match_short) ) );
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
                        $notes_string = gettext( "'network' = '%s' should be long form" );
                        push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, html_escape($match_short) ) );
                    }
                } elsif ( $match_long ) {
                    if ( $match_long eq $expect_short_for ) {
                        $notes_string = gettext( "'network' = '%s' should be short form" );
                        push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, html_escape($match_long) ) );
                    }
                }
            }
        } else {
            $issues_string = gettext( "'network' is not set" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }

        if ( $relation_ptr->{'tag'}->{'colour'} ) {
            my $colour = GetColourFromString( $relation_ptr->{'tag'}->{'colour'} );
            unless ( $colour ) {
                if ( $relation_ptr->{'tag'}->{'colour'} =~ m/^[0-9A-Fa-f]{3,6}$/ ) {
                    $issues_string = gettext( "'colour' has unknown value '%s'. Add '#' as first character." );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, html_escape($relation_ptr->{'tag'}->{'colour'}) ) );
                } else {
                    $issues_string = gettext( "'colour' has unknown value '%s'. Choose one of the 140 well defined HTML/CSS colour names or the HTML Hex colour codes '#...' or '#......'." );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf( $issues_string, html_escape($relation_ptr->{'tag'}->{'colour'}) ) );
                }
            }
        }

        if ( $positive_notes ) {

            if ( !$network_long_regex && !$network_short_regex ) {
                # we do not filter for any 'network' values, so let's print also the value of 'network'
                if ( $relation_ptr->{'tag'}->{'network'} ) {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf("'network' = '%s'", html_escape($relation_ptr->{'tag'}->{'network'})) )
                }
            }

            foreach my $special ( 'network:', 'route:', 'ref:', 'ref_', 'operator', 'timetable' ) {
                foreach my $tag ( @relation_tags ) {
                    if ( $tag =~ m/^\Q$special\E/i ) {
                        if ( $relation_ptr->{'tag'}->{$tag} ) {
                            if ( $tag =~ m/^network:long$/i && $network_long_regex ){
                                if ( $relation_ptr->{'tag'}->{$tag} =~ m/^$network_long_regex$/ ) {
                                    $notes_string = gettext( "'network:long' is long form" );
                                    push( @{$relation_ptr->{'__notes__'}}, $notes_string );
                                } elsif ( $relation_ptr->{'tag'}->{$tag} =~ m/$network_long_regex/ ) {
                                    $notes_string = gettext( "'network:long' matches long form" );
                                    push( @{$relation_ptr->{'__notes__'}}, $notes_string );
                                } else {
                                    push( @{$relation_ptr->{'__notes__'}}, sprintf("'network:long' = '%s'", html_escape($relation_ptr->{'tag'}->{$tag})) )
                                }
                            } else {
                                push( @{$relation_ptr->{'__notes__'}}, sprintf("'%s' = '%s'", html_escape($tag), html_escape($relation_ptr->{'tag'}->{$tag})) )
                            }
                        }
                    }
                }
            }
        }

        if ( $check_osm_separator ) {
            foreach $check_osm_separator_tag ( @check_osm_separator_tags ) {
                foreach my $tag ( @relation_tags ) {
                    if ( $tag ne 'ref_trips' && $tag ne 'ref_name' && $tag =~ m/^\Q$check_osm_separator_tag\E/ ) {
                        if ( $relation_ptr->{'tag'}->{$tag} ) {
#                            if ( $relation_ptr->{'tag'}->{$tag} =~ m/\s;|;\s/ ) {
#                                $notes_string = gettext( "'%s' = '%s' includes the separator value ';' (semi-colon) with sourrounding blank" );
#                                push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, html_escape($tag), html_escape($relation_ptr->{'tag'}->{$tag})) );
#                            }
                            if ( $relation_ptr->{'tag'}->{$tag} =~ m/,/ ) {
                                $notes_string = gettext( "'%s' = '%s': ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank" );
                                push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, html_escape($tag), html_escape($relation_ptr->{'tag'}->{$tag})) );
                            }
                        }
                    }
                }
            }
        }

        if ( $show_gtfs ) {
            foreach my $special ( 'gtfs:', 'gtfs_' ) {
                foreach my $tag ( @relation_tags ) {
                    if ( $tag =~ m/^\Q$special\E/i ) {
                        if ( $relation_ptr->{'tag'}->{$tag} ) {
                            push( @{$relation_ptr->{'__notes__'}}, sprintf("'%s' = '%s'", html_escape($tag), html_escape($relation_ptr->{'tag'}->{$tag})) )
                        }
                    }
                }
            }
        }

        #if ( $check_gtfs ) {
        #    if ( $relation_ptr->{'tag'}->{'gtfs:shape_id'}                 &&
        #         !defined($relation_ptr->{'tag'}->{'gtfs:trip_id'})        &&
        #         !defined($relation_ptr->{'tag'}->{'gtfs:trip_id:sample'})    ) {
        #        $notes_string = gettext( "'gtfs:shape_id' = '%s' is set but neither 'gtfs:trip_id' nor 'gtfs:trip_id:sample' is set: consider setting one of them as they provide additional information about stops (their names, sequence and locations)." );
        #        push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, $relation_ptr->{'tag'}->{'gtfs:shape_id'} ) );
        #    }
        #}

        if ( $relation_ptr->{'tag'}->{'line'} ) {
            $notes_string = gettext( "The tag 'line' (='%s') is reserved for 'power' = 'line' related tagging. For public transport 'route_master' and 'route' are used." );
            push( @{$relation_ptr->{'__notes__'}}, sprintf( $notes_string, $relation_ptr->{'tag'}->{'line'} ) );
        }

        #
        # check route_master/route specific things
        #

        if ( $type eq 'route_master' ) {
            $return_code = analyze_route_master_relation( $relation_ptr, $relation_id );
        } elsif ( $type eq 'route') {
            $return_code = analyze_route_relation( $relation_ptr, $relation_id );
        }
    }

    #
    # Link to GTFS data shall be shown
    #
    if ( $link_gtfs ) {
        $relation_ptr->{'GTFS-HTML-TAG'} = getGtfsInfo( $relation_ptr );
    }

    return $return_code;
}


#############################################################################################

sub analyze_route_master_relation {
    my $relation_ptr    = shift;
    my $relation_id     = shift;
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

    unless ( $route_master_relation_index ) {
        $issues_string = gettext( "Route-Master without Route(s)" );
        push( @{$relation_ptr->{'__issues__'}}, $issues_string );
    }
    #if ( $route_master_relation_index == 1 ) {
    #    $notes_string = gettext( "Route-Master with only 1 Route" );
    #    push( @{$relation_ptr->{'__notes__'}}, $notes_string );
    #}
    if ( $route_master_relation_index != $relation_index ) {
        $issues_string = gettext( "Route-Master with Relation(s) unequal to 'route'" );
        push( @{$relation_ptr->{'__issues__'}}, $issues_string );
    }
    if ( $way_index ) {
        $issues_string = gettext( "Route-Master with Way(s)" );
        push( @{$relation_ptr->{'__issues__'}}, $issues_string );
    }
    if ( $node_index ) {
        $issues_string = gettext( "Route-Master with Node(s)" );
        push( @{$relation_ptr->{'__issues__'}}, $issues_string );
    }
    if ( $relation_ptr->{'tag'}->{'public_transport:version'} ) {
        if ( $relation_ptr->{'tag'}->{'public_transport:version'} !~ m/^2$/ ) {
            $issues_string = gettext( "'public_transport:version' is not set to '2'" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string )        if ( $check_version );
        } else {
            ; #push( @{$relation_ptr->{'__notes__'}}, sprintf("'public_transport:version' = '%s'",html_escape($relation_ptr->{'tag'}->{'public_transport:version'})) )    if ( $positive_notes );
        }
    } # else {
    #    $notes_string = gettext( "'public_transport:version' is not set" );
    #    push( @{$relation_ptr->{'__notes__'}}, $notes_string )        if ( $check_version );
    #}

    return $return_code;
}


#############################################################################################

sub analyze_route_relation {
    my $relation_ptr    = shift;
    my $relation_id     = shift;
    my $return_code     = 0;

    my $ref                            = $relation_ptr->{'tag'}->{'ref'};
    my $type                           = $relation_ptr->{'tag'}->{'type'};
    my $route_type                     = $relation_ptr->{'tag'}->{$type};
    my $route_relation_index           = $relation_ptr->{'route_relation'} ? scalar( @{$relation_ptr->{'route_relation'}} ) : 0;
    my $route_highway_index            = $relation_ptr->{'route_highway'}  ? scalar( @{$relation_ptr->{'route_highway'}} )  : 0;
    my $node_index                     = $relation_ptr->{'node'}           ? scalar( @{$relation_ptr->{'node'}} )           : 0;

    $relation_ptr->{'missing_way_data'}   = 0;
    $relation_ptr->{'missing_node_data'}  = 0;

    $return_code += CheckCompletenessOfData( $relation_ptr );

    if ( $relation_ptr->{'tag'}->{'public_transport:version'} && $relation_ptr->{'tag'}->{'public_transport:version'} eq '2' ) {
        if ( $relation_ptr->{'missing_way_data'} == 0 && $relation_ptr->{'missing_node_data'} == 0 ) {
            $return_code = analyze_ptv2_route_relation( $relation_ptr );
        } else {
            $issues_string = gettext( "Skipping further analysis ..." );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }
    } else {
        unless ( $route_highway_index ) {
            $issues_string = gettext( "Route without Way(s)" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }
        if( $route_highway_index == 1 && $route_type ne 'monorail' && $route_type ne 'ferry' && $route_type ne 'aerialway' && $route_type ne 'funicular' ) {
            $issues_string = gettext( "Route with only 1 Way" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }
        unless ( $node_index ) {
            $issues_string = gettext( "Route without Node(s)" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }
        if ( $node_index == 1 ) {
            $issues_string = gettext( "Route with only 1 Node" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }
        if ( $route_relation_index ) {
            $issues_string = gettext( "Route with Relation(s)" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }
        if ( $relation_ptr->{'tag'}->{'public_transport:version'} ) {
            if ( $relation_ptr->{'tag'}->{'public_transport:version'} ne '1' ) {
                $issues_string = gettext( "'public_transport:version' is neither '1' nor '2'" );
                push( @{$relation_ptr->{'__issues__'}}, $issues_string );
            } else {
                #push( @{$relation_ptr->{'__notes__'}}, sprintf("'public_transport:version' = '%s'",html_escape($relation_ptr->{'tag'}->{'public_transport:version'})) )    if ( $positive_notes );
            }
        } #else {
        #    $notes_string = gettext( "'public_transport:version' is not set" );
        #    push( @{$relation_ptr->{'__notes__'}}, $notes_string )        if ( $check_version );
        #}
    }

    #
    # for WAYS used by vehicles             vehicles must have access permission
    # for NODES of WAYS used by vehicles    vehicles must have access permission on barrier NODES
    #
    if ( $check_access ) {
        $return_code += CheckAccessOnWaysAndNodes( $relation_ptr );
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

    #
    # relation shall be shown on PTNA's special map
    #
    $relation_ptr->{'show_relation'} = 1;

    return $return_code;
}


#############################################################################################

sub analyze_ptv2_route_relation {
    my $relation_ptr    = shift;
    my $relation_id     = shift;
    my $return_code     = 0;

    my $type                                = $relation_ptr->{'tag'}->{'type'};
    my $route_type                          = $relation_ptr->{'tag'}->{$type};
    my $role_mismatch_found                 = 0;
    my %role_mismatch                       = ();
    my @sorted_way_nodes                    = ();
    my @help_array                          = ();
    my $help_string                         = '';
    my $num_of_errors                       = 0;
    my $access_restriction                  = undef;

    my $number_of_route_relation            = $relation_ptr->{'route_relation'} ? scalar( @{$relation_ptr->{'route_relation'}} ) : 0;

    my @relation_route_highways             = FindRouteHighWays( $relation_ptr );
    my $number_of_route_highways            = scalar( @relation_route_highways );

    my @relation_route_stop_positions       = FindRouteStopPositions( $relation_ptr );  # stop positions are nodes only
    my $number_of_route_stop_positions      = scalar( @relation_route_stop_positions );

    my @relation_route_platform_nodes       = FindRoutePlatformNodes( $relation_ptr );
    my @relation_route_platform_ways        = FindRoutePlatformWays( $relation_ptr );
    my @relation_route_platform_relations   = FindRoutePlatformRelations( $relation_ptr );
    my $number_of_route_platform_nodes      = scalar( @relation_route_platform_nodes );
    my $number_of_route_platform_ways       = scalar( @relation_route_platform_ways );
    my $number_of_route_platform_relations  = scalar( @relation_route_platform_relations );
    my $number_of_route_platforms           = $number_of_route_platform_nodes + $number_of_route_platform_ways + $number_of_route_platform_relations;

    unless ( $number_of_route_highways ) {
        $issues_string = gettext( "Route without Way(s)" );
        push( @{$relation_ptr->{'__issues__'}}, $issues_string );
    }
    if ( $number_of_route_highways == 1 && $route_type ne 'monorail' && $route_type ne 'ferry' && $route_type ne 'aerialway' && $route_type ne 'funicular' ) {
        $issues_string = gettext( "Route with only 1 Way" );
        push( @{$relation_ptr->{'__issues__'}}, $issues_string );
    }
    if ( $number_of_route_stop_positions == 0 && $number_of_route_platforms == 0 ) {
        $issues_string = gettext( "PTv2 route: there are no 'public_transport' = 'stop_position' and no 'public_transport' = 'platform'" );
        push( @{$relation_ptr->{'__issues__'}}, $issues_string );
    } else {
        unless ( $number_of_route_stop_positions ) {
            $notes_string = gettext( "PTv2 route: there is no 'public_transport' = 'stop_position'" );
            push( @{$relation_ptr->{'__notes__'}}, $notes_string );
        }
        if ( $number_of_route_stop_positions == 1 ) {
            $issues_string = gettext( "PTv2 route: there is only one 'public_transport' = 'stop_position'" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }
        unless ( $number_of_route_platforms ) {
            $notes_string = gettext( "PTv2 route: there is no 'public_transport' = 'platform'" );
            push( @{$relation_ptr->{'__notes__'}},$notes_string );
        }
        if ( $number_of_route_platforms == 1 ) {
            $issues_string = gettext( "PTv2 route: there is only one 'public_transport' = 'platform'" );
            push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        }
    }
    if ( $number_of_route_relation ) {
        $issues_string = gettext( "Route with Relation(s)" );
        push( @{$relation_ptr->{'__issues__'}}, $issues_string );
    }

    $relation_ptr->{'non_platform_ways'}       = \@relation_route_highways;
    $relation_ptr->{'number_of_segments'}      = 0;
    $relation_ptr->{'gap_at_way'}              = ();
    $relation_ptr->{'sorted_in_reverse_order'} = '';

    if ( $check_name ) {
        $return_code += CheckNameRefFromViaToPTV2( $relation_ptr );
    }

    if ( $relation_route_highways[0] && $relation_route_highways[1] ) {
        #
        # special check for route being sorted in reverse order and starting with a oneway (except closed way)
        # another check for first way being a oneway way being used in wrong direction
        #
        my $first_way_id    = $relation_route_highways[0];
        my $second_way_id   = $relation_route_highways[1];
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
                if ( $platform_multipolygon_relations{$item->{'ref'}} ) {
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
        $issues_string = gettext( "PTv2 route: first way is a oneway road and ends in a 'stop_position' of this route and there is no exit. Is the route sorted in reverse order?" );
        push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        $return_code++
    }
    if ( $relation_ptr->{'number_of_segments'} > 1 ) {
        my @help_array     = @{$relation_ptr->{'gap_at_way'}};
        my $num_of_errors  = scalar(@help_array);
        $issues_string     = ngettext( "PTv2 route: has a gap, consists of %d segments. Gap appears at way", "PTv2 route: has gaps, consists of %d segments. Gaps appear at ways", $relation_ptr->{'number_of_segments'}-1 );
        my $error_string   = sprintf( $issues_string, $relation_ptr->{'number_of_segments'});
        if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
            push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $error_string, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
        } else {
            push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $error_string, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
        }
        $return_code += $relation_ptr->{'number_of_segments'} - 1;
    }
    if ( $relation_ptr->{'wrong_sequence'} ) {
        $issues_string = gettext( "PTv2 route: incorrect order of 'stop_position', 'platform' and 'way' (stop/platform after way)" );
        push( @{$relation_ptr->{'__issues__'}}, $issues_string );
        $return_code++;
    }
    if ( $check_roundabouts ) {
        my @help_array    = sort( keys( %{$relation_ptr->{'roundabout_segments_at'}} ) );
        my $num_of_errors = scalar( @help_array );
        if ( $num_of_errors ) {
            $notes_string = ngettext( "PTv2 route: includes %d entire roundabout but uses only segments", "PTv2 route: includes %d entire roundabouts but uses only segments", $num_of_errors );
            my $error_string   = sprintf( $notes_string, $num_of_errors );
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("%s: %s and %d more ..."), $error_string, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            } else {
                push( @{$relation_ptr->{'__notes__'}}, sprintf("%s: %s", $error_string, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
            }
            $return_code++;
        }
    }
    if ( $relation_ptr->{'wrong_direction_oneways'} ) {
        my @help_array     = sort(keys(%{$relation_ptr->{'wrong_direction_oneways'}}));
        my $num_of_errors  = scalar(@help_array);
           $issues_string  = ngettext( "PTv2 route: using oneway way in wrong direction", "PTv2 route: using oneway ways in wrong direction", $num_of_errors );
        if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
            push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $issues_string, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
        } else {
            push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $issues_string, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
        }
        $return_code++;
    }
    if ( $relation_ptr->{'number_of_segments'} == 1 && $check_motorway_link && $relation_ptr->{'expect_motorway_after'} ) {
        my @help_array    = sort(keys(%{$relation_ptr->{'expect_motorway_after'}}));
        my $num_of_errors = scalar(@help_array);
           $issues_string = ngettext( "PTv2 route: using motorway_link way without entering a motorway way", "PTv2 route: using motorway_link ways without entering a motorway way", $num_of_errors );
        if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
            push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $issues_string, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
        } else {
            push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $issues_string, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
        }
        $return_code++;
    }
    if ( $relation_ptr->{'number_of_segments'} == 1 && $relation_ptr->{'roundabout_follows_itself'} ) {
        my @help_array    = sort(keys(%{$relation_ptr->{'roundabout_follows_itself'}}));
        my $num_of_errors = scalar(@help_array);
           $issues_string = ngettext( "PTv2 route: roundabout appears twice, following itself", "PTv2 route: roundabouts appear twice, following themselves", $num_of_errors );
        if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
            push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $issues_string, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
        } else {
            push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $issues_string, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
        }
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
                                if ( scalar(@relation_route_highways) == 1 ) {
                                    my $entry_node_id = isOneway( $relation_route_highways[0], undef );
                                    if ( $entry_node_id != 0 ) {
                                        # it is a oneway
                                        if ( $node_ref->{'role'} eq 'stop_exit_only' && isFirstNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                            $issues_string = gettext( "PTv2 route: first node of oneway way has 'role' = 'stop_exit_only'" );
                                            $role_mismatch{$issues_string}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                        if ( $node_ref->{'role'} eq 'stop_entry_only' && isLastNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                            $issues_string = gettext( "PTv2 route: last node of oneway way has 'role' = 'stop_entry_only'" );
                                            $role_mismatch{$issues_string}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                    }
                                } elsif ( scalar(@relation_route_highways) > 1 ) {
                                    #
                                    # for routes with more than 1 way
                                    #
                                    # do not consider roundtrip routes where first and last node is the same node but passengers have to leave the bus/tram/...
                                    #
                                    if ( $node_ref->{'role'} eq 'stop_exit_only' ) {
                                        if ( isFirstNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) && !isLastNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                            $issues_string = gettext( "PTv2 route: first node of way has 'role' = 'stop_exit_only'. Is the route sorted in reverse order?" );
                                            $role_mismatch{$issues_string}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                    }
                                    if ( $node_ref->{'role'} eq 'stop_entry_only' ) {
                                        if ( isLastNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) && ! isFirstNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                            $issues_string = gettext( "PTv2 route: last node of way has 'role' = 'stop_entry_only'. Is the route sorted in reverse order?" );
                                            $role_mismatch{$issues_string}->{$node_ref->{'ref'}} = 1;
                                            $role_mismatch_found++;
                                        }
                                    }
                                }
                            } else {
                                if ( $number_of_route_highways ) {
                                    $issues_string = gettext( "PTv2 route: 'public_transport' = 'stop_position' is not part of way" );
                                    $role_mismatch{$issues_string}->{$node_ref->{'ref'}} = 1;
                                    $role_mismatch_found++;
                                }
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
                                        $issues_string = gettext( "PTv2 route: missing '%s' = 'yes' on 'public_transport' = '%s'" );
                                        $help_string   = sprintf( $issues_string, $relation_ptr->{'tag'}->{'route'}, 'stop_position' );
                                        $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                                        $role_mismatch_found++;
                                    }
                                }
                            }
                        }
                        elsif ( $NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'} ) {
                            $issues_string = gettext( "PTv2 route: mismatch between 'role' = '%s' and 'public_transport' = '%s'" );
                            $help_string   = sprintf( $issues_string, $node_ref->{'role'}, $NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'} );
                            $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        } elsif ( $ptv1_compatibility ne "no"  ) {
                            my $compatible_tag = PTv2CompatibleNodeStopTag( $node_ref->{'ref'}, $relation_ptr->{'tag'}->{'route'} );
                            if ( $compatible_tag ) {
                                if ( $ptv1_compatibility eq "show" ) {
                                    $issues_string = gettext( "PTv2 route: 'role' = '%s' and %s: consider setting 'public_transport' = 'stop_position'" );
                                    $help_string   = sprintf( $issues_string, $node_ref->{'role'}, $compatible_tag );
                                    $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                                    $role_mismatch_found++;
                                }
                            } else {
                                $issues_string = gettext( "PTv2 route: 'role' = '%s' but 'public_transport' is not set" );
                                $help_string   = sprintf( $issues_string, $node_ref->{'role'} );
                                $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                                $role_mismatch_found++;
                            }
                        } else {
                            $issues_string = gettext( "PTv2 route: 'role' = '%s' but 'public_transport' is not set" );
                            $help_string   = sprintf( $issues_string, $node_ref->{'role'} );
                            $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        }
                    } else {           # matches any platform of the three choices
                        if ( $platform_nodes{$node_ref->{'ref'}} ) {
                            if ( isNodeInNodeArray($node_ref->{'ref'},@sorted_way_nodes) ) {
                                $issues_string = gettext( "PTv2 route: 'public_transport' = 'platform' is part of way" );
                                $role_mismatch{$issues_string}->{$node_ref->{'ref'}} = 1;
                                $role_mismatch_found++;
                            } else {
                                ; # fine, what else can we check here?
                            }
                            #
                            # bus=yes, tram=yes or share_taxi=yes is not required on public_transport=platform
                            #
                            if ( $check_platform ) {
                                if (  $relation_ptr->{'tag'}->{'route'} eq 'bus'                     ||
                                     ($relation_ptr->{'tag'}->{'route'} eq 'coach' && $allow_coach)  ||
                                      $relation_ptr->{'tag'}->{'route'} eq 'tram'                    ||
                                      $relation_ptr->{'tag'}->{'route'} eq 'share_taxi'                 ) {
                                    if ( $NODES{$node_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}}          &&
                                         $NODES{$node_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}} eq "yes"    ) {
                                        ; # fine
                                    }
                                    else {
                                        $issues_string = gettext( "PTv2 route: missing '%s' = 'yes' on 'public_transport' = '%s'" );
                                        $help_string   = sprintf( $issues_string, $relation_ptr->{'tag'}->{'route'}, 'platform' );
                                        $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                                        $role_mismatch_found++;
                                    }
                                }
                            }
                        } elsif ( $NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'} ) {
                            $issues_string = gettext( "PTv2 route: mismatch between 'role' = '%s' and 'public_transport' = '%s'" );
                            $help_string   = sprintf( $issues_string, $node_ref->{'role'}, $NODES{$node_ref->{'ref'}}->{'tag'}->{'public_transport'} );
                            $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        } elsif ( $ptv1_compatibility ne "no"  ) {
                            my $compatible_tag = PTv2CompatibleNodePlatformTag( $node_ref->{'ref'}, $relation_ptr->{'tag'}->{'route'} );
                            if ( $compatible_tag ) {
                                if ( $ptv1_compatibility eq "show" ) {
                                    $issues_string = gettext( "PTv2 route: 'role' = '%s' and %s: consider setting 'public_transport' = 'platform'" );
                                    $help_string   = sprintf( $issues_string, $node_ref->{'role'}, $compatible_tag );
                                    $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                                    $role_mismatch_found++;
                                }
                            } else {
                                $issues_string = gettext( "PTv2 route: 'role' = '%s' but 'public_transport' is not set" );
                                $help_string   = sprintf( $issues_string, $node_ref->{'role'} );
                                $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                                $role_mismatch_found++;
                            }
                        } else {
                            $issues_string = gettext( "PTv2 route: 'role' = '%s' but 'public_transport' is not set" );
                            $help_string   = sprintf( $issues_string, $node_ref->{'role'} );
                            $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                            $role_mismatch_found++;
                        }
                    }
                }
            } else {
                $issues_string = gettext( "PTv2 route: wrong 'role' = '%s'" );
                $help_string   = sprintf( $issues_string, ctrl_escape($node_ref->{'role'}) );
                $role_mismatch{$help_string}->{$node_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        } else {
            $issues_string = gettext( "PTv2 route: empty 'role'" );
            $role_mismatch{$issues_string}->{$node_ref->{'ref'}} = 1;
            $role_mismatch_found++;
        }
    }
    if ( $role_mismatch_found ) {
        foreach my $role ( sort ( keys ( %role_mismatch ) ) ) {
            @help_array     = sort(keys(%{$role_mismatch{$role}}));
            $num_of_errors  = scalar(@help_array);
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $role, join(', ', map { printNodeTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $role, join(', ', map { printNodeTemplate($_,'name;ref'); } @help_array )) );
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
                if ( scalar(@relation_route_highways) > 1 || isOneway($relation_route_highways[0],undef) ) {
                    #
                    # if we have more than one way or the single way is a oneway, and because we know: the ways are sorted and w/o gaps
                    #
                    $issues_string = gettext( "PTv2 route: first node of way is not the first stop position of this route: %s versus %s" );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printNodeTemplate($sorted_way_nodes[0],'name;ref'), printNodeTemplate($relation_route_stop_positions[0],'name;ref') ) );
                    $return_code++;
                }
            }
        } else {
            printf STDERR "No! Checking whether we can be relaxed: Route-Name: %s\n", $relation_ptr->{'tag'}->{'name'}      if ( $debug );
            my $relaxed_for =  $relaxed_begin_end_for || '';
            $relaxed_for    =~ s/;/,/g;
            $relaxed_for    =  ',' . $relaxed_for . ',';
            if ( $relaxed_for =~ m/,\Q$relation_ptr->{'tag'}->{'route'}\E,/ ) {
                my $first_way_ID     = $relation_route_highways[0];
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
                    printf STDERR "1: Number of ways: %s, found_nodeid = %s, last node of first way = %s\n", scalar(@relation_route_highways), $found_nodeid, $first_way_nodes[$#first_way_nodes]  if ( $debug );
                    if ( scalar(@relation_route_highways) > 1 && $found_nodeid == $first_way_nodes[$#first_way_nodes] ) {
                        $issues_string = gettext( "PTv2 route: consider removing the first way of the route from the relation, it is a way before the first stop position: %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printWayTemplate($first_way_ID,'name;ref') ) );
                        $return_code++;
                    } else {
                        $issues_string = gettext( "PTv2 route: first stop position on first way is not the first stop position of this route: %s versus %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printNodeTemplate($found_nodeid,'name;ref'), printNodeTemplate($relation_route_stop_positions[0],'name;ref') ) );
                        $return_code++;
                    }
                }
                elsif ( $found_it == 2 ) {
                    printf STDERR "2: Number of ways: %s, found_nodeid = %s, last node of first way = %s\n", scalar(@relation_route_highways), $found_nodeid, $first_way_nodes[$#first_way_nodes]  if ( $debug );
                    if ( scalar(@relation_route_highways) > 1 && $found_nodeid == $first_way_nodes[$#first_way_nodes] ) {
                        $issues_string = gettext( "PTv2 route: consider removing the first way of the route from the relation, it is a way before the first stop position: %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printWayTemplate($first_way_ID,'name;ref') ) );
                        $return_code++;
                    }
                } else {
                    if ( $number_of_route_stop_positions > 0 ) {
                        $issues_string = gettext( "PTv2 route: there is no stop position of this route on the first way: %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printWayTemplate($first_way_ID,'name;ref') ) );
                        $return_code++;
                    }
                }
            } else {
                if ( $number_of_route_stop_positions > 0 ) {
                    $issues_string = gettext( "PTv2 route: first node of way is not a stop position of this route: %s" );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printNodeTemplate($sorted_way_nodes[0],'name;ref') ) );
                    $return_code++;
                }
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
                if ( scalar(@relation_route_highways) > 1 || isOneway($relation_route_highways[0],undef) ) {
                    #
                    # if we have more than one way or the single way is a oneway, and because we know: the ways are sorted and w/o gaps
                    #
                    $issues_string = gettext( "PTv2 route: last node of way is not the last stop position of this route: %s versus %s" );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printNodeTemplate($sorted_way_nodes[$#sorted_way_nodes],'name;ref'), printNodeTemplate($relation_route_stop_positions[$#relation_route_stop_positions],'name;ref') ) );
                    $return_code++;
                }
            }
        } else {
            printf STDERR "No! Checking whether we can be relaxed: Route-Name: %s\n", $relation_ptr->{'tag'}->{'name'}      if ( $debug );
            my $relaxed_for =  $relaxed_begin_end_for || '';
            $relaxed_for    =~ s/;/,/g;
            $relaxed_for    =  ',' . $relaxed_for . ',';
            if ( $relaxed_for =~ m/,\Q$relation_ptr->{'tag'}->{'route'}\E,/ ) {
                my $last_way_ID     = $relation_route_highways[$#relation_route_highways];
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
                    printf STDERR "1: Number of ways: %s, found_nodeid = %s, first node of last way = %s\n", scalar(@relation_route_highways), $found_nodeid, $last_way_nodes[0]  if ( $debug );
                    if ( scalar(@relation_route_highways) > 1 && $found_nodeid == $last_way_nodes[$#last_way_nodes] ) {
                        $issues_string = gettext( "PTv2 route: consider removing the last way of the route from the relation, it is a way after the last stop position: %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printWayTemplate($last_way_ID,'name;ref') ) );
                        $return_code++;
                    } else {
                        $issues_string = gettext( "PTv2 route: last stop position on last way is not the last stop position of this route: %s versus %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printNodeTemplate($found_nodeid,'name;ref'), printNodeTemplate($relation_route_stop_positions[$#relation_route_stop_positions],'name;ref') ) );
                        $return_code++;
                    }
                }
                elsif ( $found_it == 2 ) {
                    printf STDERR "2: Number of ways: %s, found_nodeid = %s, first node of last way = %s\n", scalar(@relation_route_highways), $found_nodeid, $last_way_nodes[0]  if ( $debug );
                    if ( scalar(@relation_route_highways) > 1 && $found_nodeid == $last_way_nodes[$#last_way_nodes] ) {
                        $issues_string = gettext( "PTv2 route: consider removing the last way of the route from the relation, it is a way after the last stop position: %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printWayTemplate($last_way_ID,'name;ref') ) );
                        $return_code++;
                    }
                } else {
                    if ( $number_of_route_stop_positions > 0 ) {
                        $issues_string = gettext( "PTv2 route: there is no stop position of this route on the last way: %s" );
                        push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printWayTemplate($last_way_ID,'name;ref') ) );
                        $return_code++;
                    }
                }
            } else {
                if ( $number_of_route_stop_positions > 0 ) {
                    $issues_string = gettext( "PTv2 route: last node of way is not a stop position of this route: %s" );
                    push( @{$relation_ptr->{'__issues__'}}, sprintf($issues_string, printNodeTemplate($sorted_way_nodes[$#sorted_way_nodes],'name;ref') ) );
                    $return_code++;
                }
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
                        if ( $check_platform ) {
                            if (  $relation_ptr->{'tag'}->{'route'} eq 'bus'                    ||
                                 ($relation_ptr->{'tag'}->{'route'} eq 'coach' && $allow_coach) ||
                                  $relation_ptr->{'tag'}->{'route'} eq 'tram'                   ||
                                  $relation_ptr->{'tag'}->{'route'} eq 'share_taxi'                ) {
                                if ( $WAYS{$highway_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}}          &&
                                     $WAYS{$highway_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}} eq "yes"    ) {
                                    ; # fine
                                }
                                else {
                                    $issues_string = gettext( "PTv2 route: missing '%s' = 'yes' on 'public_transport' = '%s'" );
                                    $help_string   = sprintf( $issues_string, $relation_ptr->{'tag'}->{'route'}, 'platform' );
                                    $role_mismatch{$help_string}->{$highway_ref->{'ref'}} = 1;
                                    $role_mismatch_found++;
                                }
                            }
                        }
                    } elsif ( $WAYS{$highway_ref->{'ref'}}->{'tag'}->{'public_transport'} ) {
                        $issues_string = gettext( "PTv2 route: mismatch between 'role' = '%s' and 'public_transport' = '%s'" );
                        $help_string   = sprintf( $issues_string, $highway_ref->{'role'}, $WAYS{$highway_ref->{'ref'}}->{'tag'}->{'public_transport'} );
                        $role_mismatch{$help_string}->{$highway_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    } else {
                        $issues_string = gettext( "PTv2 route: 'role' = '%s' but 'public_transport' is not set" );
                        $help_string   = sprintf( $issues_string, $highway_ref->{'role'} );
                        $role_mismatch{$help_string}->{$highway_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    }
                }
            } else {
                $issues_string = gettext( "PTv2 route: wrong 'role' = '%s'" );
                $help_string   = sprintf( $issues_string, ctrl_escape($highway_ref->{'role'}) );
                $role_mismatch{$help_string}->{$highway_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        } else {
            if ( $platform_ways{$highway_ref->{'ref'}} ) {
                $issues_string = gettext( "PTv2 route: empty 'role'" );
                $role_mismatch{$issues_string}->{$highway_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        }
    }
    if ( $role_mismatch_found ) {
        foreach my $role ( sort ( keys ( %role_mismatch ) ) ) {
            @help_array     = sort(keys(%{$role_mismatch{$role}}));
            $num_of_errors  = scalar(@help_array);
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $role, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            }
            else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $role, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
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

                if ( $number_of_platform_multipolygon_relations ) {
                    if ( $platform_multipolygon_relations{$rel_ref->{'ref'}} ) {
                        #
                        # bus=yes, tram=yes or share_taxi=yes is not required on public_transport=platform
                        #
                        if ( $check_platform ) {
                            if (  $relation_ptr->{'tag'}->{'route'} eq 'bus'                    ||
                                 ($relation_ptr->{'tag'}->{'route'} eq 'coach' && $allow_coach) ||
                                  $relation_ptr->{'tag'}->{'route'} eq 'tram'                   ||
                                  $relation_ptr->{'tag'}->{'route'} eq 'share_taxi'               ) {
                                if ( $RELATIONS{$rel_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}}          &&
                                     $RELATIONS{$rel_ref->{'ref'}}->{'tag'}->{$relation_ptr->{'tag'}->{'route'}} eq "yes"    ) {
                                   ; # fine
                                }
                                else {
                                    $issues_string = gettext( "PTv2 route: missing '%s' = 'yes' on 'public_transport' = '%s'" );
                                    $help_string   = sprintf( $issues_string, $relation_ptr->{'tag'}->{'route'}, 'platform' );
                                    $role_mismatch{$help_string}->{$rel_ref->{'ref'}} = 1;
                                    $role_mismatch_found++;
                                }
                            }
                        }
                    } elsif ( $RELATIONS{$rel_ref->{'ref'}}                                &&
                              $RELATIONS{$rel_ref->{'ref'}}->{'tag'}->{'public_transport'}    ) {
                        $issues_string = gettext( "PTv2 route: mismatch between 'role' = '%s' and 'public_transport' = '%s'" );
                        $help_string   = sprintf( $issues_string, $rel_ref->{'role'}, $RELATIONS{$rel_ref->{'ref'}}->{'tag'}->{'public_transport'} );
                        $role_mismatch{$help_string}->{$rel_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    } else {
                        $issues_string = gettext( "PTv2 route: 'role' = '%s' but 'public_transport' is not set" );
                        $help_string   = sprintf( $issues_string, $rel_ref->{'role'} );
                        $role_mismatch{$help_string}->{$rel_ref->{'ref'}} = 1;
                        $role_mismatch_found++;
                    }
                }
            } else {
                $issues_string = gettext( "PTv2 route: wrong 'role' = '%s'" );
                $help_string = sprintf( $issues_string, ctrl_escape($rel_ref->{'role'}) );
                $role_mismatch{$help_string}->{$rel_ref->{'ref'}} = 1;
                $role_mismatch_found++;
            }
        } else {
            $issues_string = gettext( "PTv2 route: empty 'role'" );
            $role_mismatch{$issues_string}->{$rel_ref->{'ref'}} = 1;
            $role_mismatch_found++;
        }
    }
    if ( $role_mismatch_found ) {
        foreach my $role ( sort ( keys ( %role_mismatch ) ) ) {
            @help_array     = sort(keys(%{$role_mismatch{$role}}));
            $num_of_errors  = scalar(@help_array);
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $role, join(', ', map { printRelationTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $role, join(', ', map { printRelationTemplate($_,'name;ref'); } @help_array )) );
            }
        }
    }
    $return_code += $role_mismatch_found;

    #
    # for WAYS used by vehicles             vehicles must use the right type of way
    #
    if ( $check_way_type ) {
        $return_code += CheckWayType( $relation_ptr );
    }

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

sub FindRouteHighWays {
    my $relation_ptr                = shift;
    my $highway_ref                 = undef;
    my @relations_route_highways    = ();

    foreach $highway_ref ( @{$relation_ptr->{'route_highway'}} ) {
        push( @relations_route_highways, $highway_ref->{'ref'} )    unless ( $platform_ways{$highway_ref->{'ref'}} );
        #printf STDERR "FindRouteHighWays(): not pushed() %s\n", $highway_ref->{'ref'}   if ( $platform_ways{$highway_ref->{'ref'}} );
        #printf STDERR "FindRouteHighWays(): pushed() %s\n", $highway_ref->{'ref'}       unless ( $platform_ways{$highway_ref->{'ref'}} );
    }

    return @relations_route_highways;
}


#############################################################################################

sub FindRouteStopPositions {
    my $relation_ptr                    = shift;
    my $node_ref                        = undef;
    my @relations_route_stop_positions  = ();

    foreach $node_ref ( @{$relation_ptr->{'node'}} ) {
        if ( $stop_nodes{$node_ref->{'ref'}} ) {
            push( @relations_route_stop_positions, $node_ref->{'ref'} );
        } elsif ( $ptv1_compatibility ne "no"  ) {
            my $compatible_tag = PTv2CompatibleNodeStopTag( $node_ref->{'ref'}, $relation_ptr->{'tag'}->{'route'} );
            if ( $compatible_tag ) {
                push( @relations_route_stop_positions, $node_ref->{'ref'} );
            }
        }
    }

    return @relations_route_stop_positions;
}


#############################################################################################

sub FindRoutePlatformNodes {
    my $relation_ptr                    = shift;
    my $node_ref                        = undef;
    my @relations_route_platform_nodes  = ();

    foreach $node_ref ( @{$relation_ptr->{'node'}} ) {
        if ( $platform_nodes{$node_ref->{'ref'}} ) {
            push( @relations_route_platform_nodes, $node_ref->{'ref'} );
        } elsif ( $ptv1_compatibility ne "no"  ) {
            my $compatible_tag = PTv2CompatibleNodePlatformTag( $node_ref->{'ref'}, $relation_ptr->{'tag'}->{'route'} );
            if ( $compatible_tag ) {
                push( @relations_route_platform_nodes, $node_ref->{'ref'} );
            }
        }
    }

    return @relations_route_platform_nodes;
}


#############################################################################################

sub FindRoutePlatformWays {
    my $relation_ptr                    = shift;
    my $way_ref                         = undef;
    my @relations_route_platform_ways   = ();

    foreach $way_ref ( @{$relation_ptr->{'way'}} ) {
        push( @relations_route_platform_ways, $way_ref->{'ref'} )    if ( $platform_ways{$way_ref->{'ref'}} );
    }

    return @relations_route_platform_ways;
}


#############################################################################################

sub FindRoutePlatformRelations {
    my $relation_ptr                        = shift;
    my $rel_ref                             = undef;
    my @relations_route_platform_relations  = ();

    foreach $rel_ref ( @{$relation_ptr->{'relation'}} ) {
        push( @relations_route_platform_relations, $rel_ref->{'ref'} )    if ( $platform_multipolygon_relations{$rel_ref->{'ref'}} );
    }

    return @relations_route_platform_relations;
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

                if ( $current_way_id == $next_way_id && isClosedWay($current_way_id) ) {
                    $relation_ptr->{'roundabout_follows_itself'}->{$current_way_id} = 1;
                }

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

                                $relation_ptr->{'roundabout_segments_at'}{$current_way_id}= 1;

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
                                    push( @{$relation_ptr->{'gap_at_way'}}, $current_way_id );
                                    printf STDERR "SortRouteWayNodes() : relation_ptr->{'number_of_segments'}++ = %d at Way %s and the next Way %s\n", $relation_ptr->{'number_of_segments'}, $current_way_id, $next_way_id      if ( $debug );
                                }
                            }
                        } else {
                            printf STDERR "SortRouteWayNodes() : handle Nodes of first, closed, single Way %s:\nNodes: %s\n", $current_way_id, join( ', ', @{$WAYS{$current_way_id}->{'chain'}} )     if ( $debug );
                            push( @sorted_nodes, @{$WAYS{$current_way_id}->{'chain'}} );
                            push( @sorted_nodes, 0 );      # mark a gap in the sorted nodes
                            $relation_ptr->{'number_of_segments'}++;
                            push( @{$relation_ptr->{'gap_at_way'}}, $current_way_id );
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
                                push( @{$relation_ptr->{'gap_at_way'}}, $current_way_id );
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
                        push( @{$relation_ptr->{'gap_at_way'}}, $current_way_id );
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
                            push( @{$relation_ptr->{'gap_at_way'}}, $current_way_id );
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
                            push( @{$relation_ptr->{'gap_at_way'}}, $current_way_id );
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
                        push( @{$relation_ptr->{'gap_at_way'}}, $current_way_id );
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
                            push( @{$relation_ptr->{'gap_at_way'}}, $current_way_id );
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
                                push( @{$relation_ptr->{'gap_at_way'}}, $current_way_id );
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
                        push( @{$relation_ptr->{'gap_at_way'}}, $current_way_id );
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
    my $ret_val         = '';

    if ( $NODES{$node_id}->{'member_of_way'} ) {
        # this node is a member of a way,  don't care at the moment which type
        if ( !defined($vehicle_type)                    ||
              $vehicle_type eq 'bus'                    ||
             ($vehicle_type eq 'coach' && $allow_coach) ||
              $vehicle_type eq 'share_taxi'             ||
              $vehicle_type eq 'trolleybus'                ) {
            if ( $NODES{$node_id}->{'tag'}->{'highway'} ) {
                if ( $NODES{$node_id}->{'tag'}->{'highway'} eq 'bus_stop' ) {
                     $ret_val = "'highway' = " . $NODES{$node_id}->{'tag'}->{'highway'} . "'";
                }
            }
        }
    }else {
        ; # PTv2 compatible stop_position must be member of a way, higway=bus_stop can be placed next to a way though
    }

    return $ret_val;
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

sub CheckThisWayTypeForThisVehicle {
    my $way_id          = shift;
    my $vehicle_type    = shift;
    my $help_string     = '';
    my $waykey_list     = '';

    if ( $way_id && $WAYS{$way_id} && $WAYS{$way_id}->{'tag'} && $vehicle_type ) {
        if ( !$WAYS{$way_id}->{'tag'}->{'public_transport'} ||
             ($WAYS{$way_id}->{'tag'}->{'public_transport'} ne 'stop_position' &&
              $WAYS{$way_id}->{'tag'}->{'public_transport'} ne 'platform'        )  ) {
            if ( $transport_type_uses_way_type{$vehicle_type} ) {
                foreach my $waykey ( keys( %{$transport_type_uses_way_type{$vehicle_type}} ) ) {
                    if ( $WAYS{$way_id}->{'tag'}->{$waykey} ) {
                        foreach my $wayvalue ( @{${$transport_type_uses_way_type{$vehicle_type}}{$waykey}}) {
                            if ( $wayvalue eq $WAYS{$way_id}->{'tag'}->{$waykey} ) {
                                printf STDERR "CheckThisWayTypeForThisVehicle() : way %d has appropriate '%s' = '%s' for vehicle '%s'\n", $way_id, $waykey, $wayvalue, $vehicle_type       if ( $debug );
                                return '';
                            }
                        }
                        printf STDERR "CheckThisWayTypeForThisVehicle() : way %d has wrong '%s' = '%s' for vehicle '%s'\n", $way_id, $waykey, $WAYS{$way_id}->{'tag'}->{$waykey}, $vehicle_type       if ( $debug );
                        return sprintf( "%s: '%s' = '%s'", gettext("wrong value"), $waykey, $WAYS{$way_id}->{'tag'}->{$waykey} );
                    }
                }
                if ( $WAYS{$way_id}->{'tag'}->{'route'} && $WAYS{$way_id}->{'tag'}->{'route'} eq 'ferry' ) {
                    if ( $vehicle_type eq 'bus' || $vehicle_type eq 'trolleybus' || $vehicle_type eq 'share_taxi' || $vehicle_type eq 'coach' ) {
                        foreach my $v ( $vehicle_type, 'psv', 'motor_vehicle', 'vehicle', 'taxi', 'motor_car' ) {
                            if ( $WAYS{$way_id}->{'tag'}->{$v} &&
                                ($WAYS{$way_id}->{'tag'}->{$v} eq 'yes'        ||
                                 $WAYS{$way_id}->{'tag'}->{$v} eq 'permissive' ||
                                 $WAYS{$way_id}->{'tag'}->{$v} eq 'designated' ||
                                 $WAYS{$way_id}->{'tag'}->{$v} eq 'official'      ) ) {
                                printf STDERR "CheckThisWayTypeForThisVehicle() : way %d has appropriate 'route' = 'ferry' for vehicle '%s': '%s' = '%s'\n", $way_id, $vehicle_type, $v, $WAYS{$way_id}->{'tag'}->{$v}       if ( $debug );
                                return '';
                            }
                        }
                    }
                }
                $help_string = ' ' . gettext( 'or' ) . ' ';
                $waykey_list = join( $help_string, sort ( keys( %{$transport_type_uses_way_type{$vehicle_type}} ) ) );
                printf STDERR "CheckThisWayTypeForThisVehicle() : way %d has missing key(s) '%s' for vehicle '%s'\n", $way_id, $waykey_list, $vehicle_type       if ( $debug );
                return sprintf( "%s: '%s'", gettext("missing key"), $waykey_list );
            }
        }
    }

    printf STDERR "CheckThisWayTypeForThisVehicle() : way %d is globally appropriate for vehicle '%s'\n", $way_id, $vehicle_type       if ( $debug );
    return '';
}


#############################################################################################

sub noAccessOnWay {
    my $way_id          = shift;
    my $vehicle_type    = shift;        # optional !
    my $ptv             = shift;        # optional !

    if ( $way_id && $WAYS{$way_id} && $WAYS{$way_id}->{'tag'} ) {
        my $way_tag_ref = $WAYS{$way_id}->{'tag'};

        if ( $way_tag_ref->{'psv'} && ($way_tag_ref->{'psv'} eq 'yes' || $way_tag_ref->{'psv'} eq 'designated' || $way_tag_ref->{'psv'} eq 'permissive' || $way_tag_ref->{'psv'} eq 'official') ) {
            #
            # fine for all public service vehicles
            #
            printf STDERR "noAccessOnWay() : access for all psv for way %d\n", $way_id       if ( $debug );
            return '';
        } elsif ( $way_tag_ref->{'psv:conditional'} && $way_tag_ref->{'psv:conditional'} =~ m/^yes\s*@/ ) {
            #
            # to be checked for conditional access for public service vehicles
            #
            printf STDERR "noAccessOnWay() : unclear access for all psv for way %d\n", $way_id       if ( $debug );
            return sprintf( "'psv:conditional'='%s'", $way_tag_ref->{'psv:conditional'} );
        } elsif ( $vehicle_type && $way_tag_ref->{$vehicle_type} &&
                  ($way_tag_ref->{$vehicle_type} eq 'yes' || $way_tag_ref->{$vehicle_type} eq 'destination' || $way_tag_ref->{$vehicle_type} eq 'designated' || $way_tag_ref->{$vehicle_type} eq 'permissive' || $way_tag_ref->{$vehicle_type} eq 'official') ) {
            #
            # fine for this specific type of vehicle (bus, train, subway, ...) == @supported_route_types
            #
            printf STDERR "noAccessOnWay() : access for %s for way %d\n", $vehicle_type, $way_id       if ( $debug );
            return '';
        } elsif ( $vehicle_type && $way_tag_ref->{$vehicle_type.':conditional'} && $way_tag_ref->{$vehicle_type.':conditional'} =~ m/^yes\s*@/ ) {
            #
            # to be checked for conditional access for this specific type of vehicle (bus, train, subway, ...) == @supported_route_types
            #
            printf STDERR "noAccessOnWay() : unclear access for %s for way %d\n", $vehicle_type, $way_id       if ( $debug );
            return sprintf( "'%s:conditional'='%s'", $vehicle_type, $way_tag_ref->{$vehicle_type.':conditional'} );
        } elsif ( $vehicle_type && $vehicle_type eq 'ferry' && $way_tag_ref->{'route'} && ($way_tag_ref->{'route'} eq 'ferry' || $way_tag_ref->{'route'} eq 'boat') ) {
            #
            # fine for ferries on ferry ways
            #
            printf STDERR "noAccessOnWay() : access for %s for way %d\n", $vehicle_type, $way_id       if ( $debug );
            return '';
        } elsif ( $vehicle_type             && ($vehicle_type             eq 'tram' || $vehicle_type             eq 'train' || $vehicle_type             eq 'light_rail' || $vehicle_type             eq 'subway')                                        &&
                  $way_tag_ref->{'railway'} && ($way_tag_ref->{'railway'} eq 'tram' || $way_tag_ref->{'railway'} eq 'train' || $way_tag_ref->{'railway'} eq 'light_rail' || $way_tag_ref->{'railway'} eq 'subway' || $way_tag_ref->{'railway'} eq 'rail')    ) {
            #
            # fine for rail bounded vehicles rails
            #
            printf STDERR "noAccessOnWay() : access for %s for way %d railway=%s)\n", $vehicle_type, $way_id, $way_tag_ref->{'railway'}       if ( $debug );
            return '';
        } elsif ( (!defined($ptv) || $ptv ne '2') && $way_tag_ref->{'public_transport'} && $way_tag_ref->{'public_transport'} eq 'platform' ) {
            #
            # don't check for public_transport=platform (for PTv2 defined only) even if PTv2 is not defined or not '2'
            #
            printf STDERR "noAccessOnWay() : access for %s for way %d for non-PTv2 on Platforms\n", $vehicle_type, $way_id       if ( $debug );
            return '';
        } else {
            foreach my $access_type ( 'vehicle', 'motor_vehicle', 'motorcar', 'access' ) {
                if ( $way_tag_ref->{$access_type} ) {
                    if ( $way_tag_ref->{$access_type} eq 'yes'         ||
                         $way_tag_ref->{$access_type} eq 'permissive'  ||
                         $way_tag_ref->{$access_type} eq 'official'    ||
                         $way_tag_ref->{$access_type} eq 'destination' ||
                         $way_tag_ref->{$access_type} eq 'designated'     ) {
                        last;
                    } else {
                        printf STDERR "noAccessOnWay() : no access for way %d (%s=%s)\n", $way_id, $access_type, $way_tag_ref->{$access_type}       if ( $debug );
                        return sprintf( "'%s'='%s'", $access_type, $way_tag_ref->{$access_type} );
                    }
                }
            }
            foreach my $highway_type ( 'pedestrian', 'footway', 'cycleway', 'path', 'construction' ) {
                if ( $way_tag_ref->{'highway'} && $way_tag_ref->{'highway'} eq $highway_type ) {
                    if ( ($way_tag_ref->{'access'}          && $way_tag_ref->{'access'}         eq 'yes') ||
                         ($way_tag_ref->{'vehicle'}         && $way_tag_ref->{'vehicle'}        eq 'yes') ||
                         ($way_tag_ref->{'motor_vehicle'}   && $way_tag_ref->{'motor_vehicle'}  eq 'yes') ||
                         ($way_tag_ref->{'motorcar'}        && $way_tag_ref->{'motorcar'}       eq 'yes')    ) {
                        ; # fine
                    } else {
                        printf STDERR "noAccessOnWay() : no access for way %d (%s=%s)\n", $way_id, 'highway', $highway_type       if ( $debug );
                        return sprintf( "'highway'='%s'", $highway_type );
                    }
                }
            }
            if ( $way_tag_ref->{'construction'}               &&
                 $way_tag_ref->{'highway'}                    &&
                 $way_tag_ref->{'highway'} ne 'construction'  &&
                 $way_tag_ref->{'construction'} ne 'no'       &&
                 $way_tag_ref->{'construction'} ne 'minor'    &&
                 $way_tag_ref->{'construction'} ne 'widening'    ) {
                printf STDERR "noAccessOnWay() : suspicious 'construction' = '%s' on 'highway' = '%s'\n", $way_id, $way_tag_ref->{'construction'}, $way_tag_ref->{'highway'}      if ( $debug );
                return sprintf( "'construction'='%s'", $way_tag_ref->{'construction'} );
            }
        }
    }
    printf STDERR "noAccessOnWay() : access for all for way %d\n", $way_id       if ( $debug );
    return '';
}


#############################################################################################

sub noAccessOnNode {
    my $node_id         = shift;
    my $vehicle_type    = shift;        # optional !

    my @list_of_access_levels = ( 'psv', 'motorcar', 'motor_vehicle', 'vehicle', 'access' );

    if ( $node_id && $NODES{$node_id} && $NODES{$node_id}->{'tag'}&& $NODES{$node_id}->{'tag'}->{'barrier'} ) {

        my $node_tag_ref = $NODES{$node_id}->{'tag'};

        if ( $vehicle_type ) {
            unshift( @list_of_access_levels, $vehicle_type );
        }

        foreach my $access_type ( @list_of_access_levels ) {
            if ( $node_tag_ref->{$access_type} ) {
                if ( $node_tag_ref->{$access_type} eq 'yes'         ||
                     $node_tag_ref->{$access_type} eq 'destination' ||
                     $node_tag_ref->{$access_type} eq 'designated'  ||
                     $node_tag_ref->{$access_type} eq 'permissive'  ||
                     $node_tag_ref->{$access_type} eq 'official'       ) {
                    printf STDERR "noAccessOnNode() : access for node %d (barrier=%s, %s=%s)\n", $node_id, $node_tag_ref->{'barrier'}, $access_type, $node_tag_ref->{$access_type}       if ( $debug );
                    return '';
                } elsif ( $node_tag_ref->{$access_type} eq 'no'      ||
                          $node_tag_ref->{$access_type} eq 'private'    ) {
                    printf STDERR "noAccessOnNode() : no access for node %d (barrier=%s, %s=%s)\n", $node_id, $node_tag_ref->{'barrier'}, $access_type, $node_tag_ref->{$access_type}       if ( $debug );
                    return sprintf( "'barrier'='%s', '%s'='%s'", $node_tag_ref->{'barrier'}, $access_type, $node_tag_ref->{$access_type} );
                }
            }
        }

        if ( $node_tag_ref->{'barrier'} eq 'no'          || $node_tag_ref->{'barrier'} eq 'kerb'              ||
             $node_tag_ref->{'barrier'} eq 'entrance'    || $node_tag_ref->{'barrier'} eq 'toll_booth'        ||
             $node_tag_ref->{'barrier'} eq 'bus_trap'    || $node_tag_ref->{'barrier'} eq 'height_restrictor' ||
             $node_tag_ref->{'barrier'} eq 'cattle_grid' || $node_tag_ref->{'barrier'} eq 'border_control'    ||
             $node_tag_ref->{'barrier'} eq 'sally_port'                                                          ) {
            printf STDERR "noAccessOnNode() : access for node %d (barrier=%s with implied access=yes)\n", $node_id, $node_tag_ref->{'barrier'}       if ( $debug );
            return '';
        } else {
            printf STDERR "noAccessOnNode() : no access for node %d (barrier=%s, implied access=no)\n", $node_id, $node_tag_ref->{'barrier'}       if ( $debug );
            return sprintf( gettext("'barrier'='%s' with implied 'access'='no'"), $node_tag_ref->{'barrier'} );
        }
    }
    printf STDERR "noAccessOnNode() : access for all for node %d\n", $node_id       if ( $debug );
    return '';
}


#############################################################################################
#
# for syntax of 'name' with 'ref', 'from', 'to' and maybe 'via' included (also ref:*)
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
                $notes_string = gettext( "PTv2 route: 'name' includes deprecated '&lt;=&gt;'" );
                push( @{$relation_ptr->{'__notes__'}}, $notes_string );
                $preconditions_failed++;
                $return_code++;
            }
            if ( $name =~ m/==>/ ) {
                $notes_string = gettext( "PTv2 route: 'name' includes deprecated '==&gt;'" );
                push( @{$relation_ptr->{'__notes__'}}, $notes_string );
                $preconditions_failed++;
                $return_code++;
            }
        }

        if ( $name && $ref && $preconditions_failed == 0) {

            if ( $name =~ m/^(.*):\s{0,1}(.*?)\s{0,1}=>\s{0,1}(.*)\s{0,1}=>\s{0,1}(.*)$/ ||
                 $name =~ m/^(.*):\s{0,1}(.*?)\s{0,1}=>\s{0,1}(.*)$/                     ||
                 ( $check_name_relaxed &&
                    ( $name =~ m/^(.*):\s*(.*?)\s*(?:=>|->|→|⇒)\s*(.*)\s*(?:=>|->|→|⇒)\s*(.*)$/ ||
                      $name =~ m/^(.*):\s*(.*?)\s*(?:=>|->|→|⇒)\s*(.*)$/
                    )
                 )
               ) {

                my $ref_in_name       = $1;
                my $from_in_name      = $2;
                my $vias_in_name      = $3;
                my $to_in_name        = $4;
                my @via_parts_in_name = ();

                if ( $to_in_name) {
                    if ( $check_name_relaxed ) {
                        @via_parts_in_name = split( '(?:=>|->|→|⇒)', $vias_in_name );
                    } else {
                        @via_parts_in_name = split( '=>', $vias_in_name );
                   }
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
                    # this will check only combinations of verious refs:  ref='025/9567/11'
                    #                                                     name='Bus LAVV 025/RVO 9567/VLK 11 .....'
                    #                                                     ref:LAV='025'
                    #                                                     ref:RVO='9567'
                    #                                                     ref:VLK='11'
                    my $ref_in_name_w_boundary = ';' . $ref_in_name . ';';
                    foreach my $tag ( sort ( keys ( %{$relation_ptr->{'tag'}} ) ) ) {
                        if ( $tag =~ m/^ref:(\S+)$/ && $tag !~ m/^ref:FR:STIF/ ) {
                            $number_of_ref_colon_tags++;
                            $ref_string = $relation_ptr->{'tag'}->{$tag};
                            if ( $ref_in_name_w_boundary !~ m|[ ;/]$ref_string[ ;/:]| ) {
                                $notes_string = gettext( "PTv2 route: '%s' is not part of 'name' (derived from '%s' = '%s')" );
                                push( @{$relation_ptr->{'__notes__'}}, sprintf($notes_string,html_escape($ref_string),html_escape($tag),html_escape($relation_ptr->{'tag'}->{$tag})) );
                                $return_code++;
                            }
                        }
                    }
                    if ( $number_of_ref_colon_tags == 0 ) {     # there are no 'ref:*' tags, so check 'ref' being present in 'name'
                        $notes_string = gettext( "PTv2 route: 'ref' is not part of 'name'" );
                        push( @{$relation_ptr->{'__notes__'}}, $notes_string );
                        $return_code++;
                    }
                }

                if ( $from ) {
                    if ( $from_in_name ne $from ) {
                        if ( $check_name_relaxed ) {
                            my $temp_from         = $from;
                            my $temp_from_in_name = $from_in_name;
                            $temp_from            =~ s/,//g;
                            $temp_from_in_name    =~ s/,//g;
                            if ( index($temp_from,$temp_from_in_name) == -1 ) {
                                $notes_string = gettext( "PTv2 route: from-part ('%s') of 'name' is not part of 'from' = '%s'" );
                                push( @{$relation_ptr->{'__notes__'}}, sprintf($notes_string, html_escape($from_in_name), html_escape($from)) );
                                $return_code++;
                            }
                        } else {
                            $notes_string = gettext( "PTv2 route: from-part ('%s') of 'name' is not equal to 'from' = '%s'" );
                            push( @{$relation_ptr->{'__notes__'}}, sprintf($notes_string, html_escape($from_in_name), html_escape($from)) );
                            $return_code++;
                        }
                    }
                } else {
                    $notes_string = gettext( "PTv2 route: 'from' is not set" );
                    push( @{$relation_ptr->{'__notes__'}}, $notes_string );
                    $return_code++;
                }

                if ( $to ) {
                    if ( $to_in_name ne $to ) {
                        if ( $check_name_relaxed ) {
                            my $temp_to         = $to;
                            my $temp_to_in_name = $to_in_name;
                            $temp_to            =~ s/,//g;
                            $temp_to_in_name    =~ s/,//g;
                            if ( index($temp_to,$temp_to_in_name) == -1 ) {
                                $notes_string = gettext( "PTv2 route: to-part ('%s') of 'name' is not part of 'to' = '%s'" );
                                push( @{$relation_ptr->{'__notes__'}}, sprintf($notes_string, html_escape($to_in_name), html_escape($to)) );
                                $return_code++;
                            }
                        } else {
                            $notes_string = gettext( "PTv2 route: to-part ('%s') of 'name' is not equal to 'to' = '%s'" );
                            push( @{$relation_ptr->{'__notes__'}}, sprintf($notes_string, html_escape($to_in_name), html_escape($to)) );
                            $return_code++;
                        }
                    }
                } else {
                    $notes_string = gettext( "PTv2 route: 'to' is not set" );
                    push( @{$relation_ptr->{'__notes__'}}, $notes_string );
                    $return_code++;
                }

                if ( scalar(@via_parts_in_name) ) {
                    if ( $via ) {
                        my @via_values  = split( ";", $via );

                        if ( scalar(@via_parts_in_name) == scalar(@via_values) ) {
                            for ( my $index = 0; $index < scalar(@via_parts_in_name); $index++ ) {
                                if ( $via_parts_in_name[$index] ne $via_values[$index] ) {
                                    if ( $check_name_relaxed ) {
                                        #printf STDERR "check %d via = %s against %s\n", $index, $via_values[$index], $via_parts_in_name[$index];
                                        if ( index($via_values[$index],$via_parts_in_name[$index]) == -1 ) {
                                            $notes_string = gettext( "PTv2 route: 'via' is set: %d. via-part ('%s') of 'name' is not part of %d. via-value = '%s'" );
                                            push( @{$relation_ptr->{'__notes__'}}, sprintf($notes_string,$index+1,html_escape($via_parts_in_name[$index]),$index+1,html_escape($via_values[$index])) );
                                            $return_code++;
                                        }
                                    } else {
                                        $notes_string = gettext( "PTv2 route: 'via' is set: %d. via-part ('%s') of 'name' is not equal to %d. via-value = '%s'" );
                                        push( @{$relation_ptr->{'__notes__'}}, sprintf($notes_string,$index+1,html_escape($via_parts_in_name[$index]),$index+1,html_escape($via_values[$index])) );
                                        $return_code++;
                                    }
                                }
                            }
                        } elsif ( scalar(@via_parts_in_name) > scalar(@via_values) ) {
                            $notes_string = gettext( "PTv2 route: there are more via-parts in 'name' (%d) than in 'via' (%d)" );
                            push( @{$relation_ptr->{'__notes__'}}, sprintf($notes_string,scalar(@via_parts_in_name),scalar(@via_values)) );
                            $return_code++;
                        } else {
                            $notes_string = gettext( "PTv2 route: there are less via-parts in 'name' (%d) than in 'via' (%d)" );
                            push( @{$relation_ptr->{'__notes__'}}, sprintf($notes_string,scalar(@via_parts_in_name),scalar(@via_values)) );
                            $return_code++;
                        }
                    } else {
                        $notes_string = gettext( "PTv2 route: 'name' has more than one '=>' but 'via' is not set" );
                        push( @{$relation_ptr->{'__notes__'}}, $notes_string );
                        $return_code++;
                    }
                } elsif ( $via ) {
                    $notes_string = gettext( "PTv2 route: 'name' has no via-parts but 'via' is set" );
                    push( @{$relation_ptr->{'__notes__'}}, $notes_string );
                    $return_code++;
                }
            } else {
                if ( $check_name_relaxed ) {
                    $notes_string = gettext( "PTv2 route: 'name' should be similar to the form '... ref ...: from => to'" );
                    push( @{$relation_ptr->{'__notes__'}}, $notes_string );
                } else {
                    $notes_string = gettext( "PTv2 route: 'name' should (at least) be of the form '... ref ...: from => to'" );
                    push( @{$relation_ptr->{'__notes__'}}, $notes_string );
                }
                $return_code++;
            }
        } else {
            if ( !$name ) {
                # already checked at a very early position, but must increase return_code here
                #$issues_string = gettext( "'name' is not set" );
                #push( @{$relation_ptr->{'__issues__'}}, $issues_string );
                $return_code++;
            }
            if ( !$ref ) {
                # already checked at a very early position, but must increase return_code here
                #$issues_string = gettext( "'ref' is not set" );
                #push( @{$relation_ptr->{'__issues__'}}, $issues_string );
                $return_code++;
            }
        }
    }

    return $return_code;
}


#############################################################################################
#
# for WAYS used by vehicles             vehicles must use the right way type
#
#############################################################################################

sub CheckWayType {
    my $relation_ptr = shift;
    my $ret_val      = 0;

    if ( $relation_ptr ) {
        my $this_is_wrong        = '';
        my %using_wrong_way_type = ();

        foreach my $route_highway ( @{$relation_ptr->{'route_highway'}} ) {
            $this_is_wrong = CheckThisWayTypeForThisVehicle( $route_highway->{'ref'}, $relation_ptr->{'tag'}->{'route'} );
            if ( $this_is_wrong ) {
                $using_wrong_way_type{$this_is_wrong}->{$route_highway->{'ref'}} = 1;
                $ret_val++;
            }
        }
        if ( scalar(keys(%using_wrong_way_type)) ) {
            my $helpstring     = '';
            my @help_array     = ();
            my $num_of_errors  = 0;
            foreach $this_is_wrong ( sort(keys(%using_wrong_way_type)) ) {
                @help_array     = sort(keys(%{$using_wrong_way_type{$this_is_wrong}}));
                $num_of_errors  = scalar(@help_array);
                $issues_string  = gettext( "PTv2 route: using wrong way type (%s)" );
                $helpstring     = sprintf( $issues_string, $this_is_wrong );
                if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $helpstring, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $helpstring, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
                }
            }
        }
    }
}


#############################################################################################
#
# for WAYS used by vehicles             vehicles must have access permission
# for NODES of WAYS used by vehicles    vehicles must have access permission on barrier NODES
#
#############################################################################################

sub CheckAccessOnWaysAndNodes {
    my $relation_ptr = shift;
    my $ret_val      = 0;

    if ( $relation_ptr ) {
        my $access_restriction          = undef;
        my %restricted_access_on_ways   = ();
        my %restricted_access_on_nodes  = ();

        foreach my $route_highway ( @{$relation_ptr->{'route_highway'}} ) {
            $access_restriction = noAccessOnWay( $route_highway->{'ref'}, $relation_ptr->{'tag'}->{'route'}, $relation_ptr->{'tag'}->{'public_transport:version'} );
            if ( $access_restriction ) {
                $restricted_access_on_ways{$access_restriction}->{$route_highway->{'ref'}} = 1;
                $ret_val++;
            }

            foreach my $highway_node_ID ( @{$WAYS{$route_highway->{'ref'}}->{'chain'}} ) {
                $access_restriction = noAccessOnNode( $highway_node_ID, $relation_ptr->{'tag'}->{'route'} );
                if ( $access_restriction ) {
                    $restricted_access_on_nodes{$access_restriction}->{$highway_node_ID} = 1;
                    $ret_val++;
                }
            }
        }
        if ( scalar(keys(%restricted_access_on_ways)) ) {
            my $helpstring     = '';
            my @help_array     = ();
            my $num_of_errors  = 0;
            foreach $access_restriction ( sort(keys(%restricted_access_on_ways)) ) {
                @help_array     = sort(keys(%{$restricted_access_on_ways{$access_restriction}}));
                $num_of_errors  = scalar(@help_array);
                if ( $access_restriction =~ m/^'([^']+)'='(trolleybus|share_taxi|bus|coach|psv)'$/ ) {
                    $issues_string = ngettext( "Route: incorrect access restriction (%s) to way. Consider tagging as '%s'='no' and '%s'='yes'", "Route: incorrect access restriction (%s) to ways. Consider tagging as '%s'='no' and '%s'='yes'", $num_of_errors );
                    $helpstring    = sprintf( $issues_string, $access_restriction, $1, $2 );
                    if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $helpstring, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                    } else {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $helpstring, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
                    }
                } elsif ( $access_restriction =~ m/conditional/ ) {
                    $notes_string = ngettext( "Route: unclear access (%s) to way", "Route: unclear access (%s) to ways", $num_of_errors );
                    $helpstring   = sprintf( $notes_string, $access_restriction );
                    if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                        push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("%s: %s and %d more ..."), $helpstring, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                    } else {
                        push( @{$relation_ptr->{'__notes__'}}, sprintf("%s: %s", $helpstring, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
                    }
                } elsif ( $access_restriction =~ m/^\'construction\'=\'/ ) {
                    $notes_string = ngettext( "Route: suspicious %s along with 'highway' unequal to 'construction' on way", "Route: suspicious %s along with 'highway' unequal to 'construction' on ways", $num_of_errors );
                    $helpstring   = sprintf( $notes_string, $access_restriction );
                    if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                        push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("%s: %s and %d more ..."), $helpstring, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                    } else {
                        push( @{$relation_ptr->{'__notes__'}}, sprintf("%s: %s", $helpstring, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
                    }
                } else {
                    $issues_string = ngettext( "Route: restricted access (%s) to way without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", "Route: restricted access (%s) to ways without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", $num_of_errors );
                    $helpstring    = sprintf( $issues_string, $access_restriction, $relation_ptr->{'tag'}->{'route'}, $relation_ptr->{'tag'}->{'route'} );
                    if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $helpstring, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                    } else {
                        push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $helpstring, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
                    }
                }
            }
        }
        if ( scalar(keys(%restricted_access_on_nodes)) ) {
            my $helpstring     = '';
            my @help_array     = ();
            my $num_of_errors  = 0;
            foreach $access_restriction ( sort(keys(%restricted_access_on_nodes)) ) {
                @help_array     = sort(keys(%{$restricted_access_on_nodes{$access_restriction}}));
                $num_of_errors  = scalar(@help_array);
                $issues_string  = ngettext( "Route: restricted access at barrier (%s) without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", "Route: restricted access at barriers (%s) without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", $num_of_errors );
                $helpstring     = sprintf( $issues_string, $access_restriction, $relation_ptr->{'tag'}->{'route'}, $relation_ptr->{'tag'}->{'route'} );
                if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $helpstring, join(', ', map { printNodeTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $helpstring, join(', ', map { printNodeTemplate($_,'name;ref'); } @help_array )) );
                }
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
               $issues_string  = ngettext( "Route: 'highway' = 'bus_stop' is set on way. Allowed on nodes only!", "Route: 'highway' = 'bus_stop' is set on ways. Allowed on nodes only!", $num_of_errors);
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $issues_string, join(', ', map { printWayTemplate($_,'name;ref'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $issues_string, join(', ', map { printWayTemplate($_,'name;ref'); } @help_array )) );
            }
            $ret_val       += $num_of_errors;
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
                                        $issues_string = gettext( "Route: 'route_ref' = '%s' of stop does not include 'ref' = '%s' value of this route%s" );
                                        $not_set_on{sprintf($issues_string,html_escape($object_ref->{'tag'}->{'route_ref'}),html_escape($sub_ref),$hint)}->{$member->{'ref'}} = $member->{'type'};
                                    }
                                }

                                if ( $check_osm_separator ) {
#                                    if ( $object_ref->{'tag'}->{'route_ref'} =~ m/\s+;/ ||
#                                         $object_ref->{'tag'}->{'route_ref'} =~ m/;\s+/    ) {
#                                        $notes_string = gettext( "Route: 'route_ref' = '%s' of stop includes the separator value ';' (semi-colon) with sourrounding blank" );
#                                        $separator_with_blank_on{sprintf($notes_string,html_escape($object_ref->{'tag'}->{'route_ref'}))}->{$member->{'ref'}} = $member->{'type'};
#                                    }
                                    if ( $object_ref->{'tag'}->{'route_ref'} =~ m/,/ ) {
                                        $notes_string = gettext( "Route: 'route_ref' = '%s' of stop: ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank" );
                                        $comma_as_separator{sprintf($notes_string,html_escape($object_ref->{'tag'}->{'route_ref'}))}->{$member->{'ref'}} = $member->{'type'};
                                    }
                                }

                                foreach my $tag ( 'bus_lines', 'bus_routes', 'lines', 'routes', 'line' ) {
                                    if ( $object_ref->{'tag'}->{$tag} ) {
                                        $notes_string = gettext( "Route: '%s' = '%s' of stop should be deleted, 'route_ref' = '%s' exists" );
                                        $to_be_deleted{sprintf($notes_string,$tag,html_escape($object_ref->{'tag'}->{$tag}),html_escape($object_ref->{'tag'}->{'route_ref'}))}->{$member->{'ref'}} = $member->{'type'};
                                    }
                                }
                                if ( $object_ref->{'tag'}->{'ref'} ) {
                                    $temp_stop_ref =  ';' . $object_ref->{'tag'}->{'ref'} . ';';
                                    $temp_stop_ref =~ s/\s*;\s*/;/g;

                                    foreach my $sub_ref ( split( $ref_separator, $ref ) ) {
                                        if ( $temp_stop_ref =~ m/;\Q$sub_ref\E;/ ) {
                                            $hint = sprintf( gettext( "(consider adding '%s' to the 'route_ref' tag of the stop)" ), html_escape($sub_ref) );
                                            $notes_string = gettext( "Route: 'ref' = '%s' of stop should represent the reference of the stop, but includes the 'ref' = '%s' of this route %s" );
                                            $to_be_replaced{sprintf($notes_string,html_escape($object_ref->{'tag'}->{'ref'}),html_escape($sub_ref),$hint)}->{$member->{'ref'}} = $member->{'type'};
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
                                        $notes_string = gettext( "Route: '%s' = '%s' of stop should be replaced by 'route_ref' = '%s'" );
                                        $to_be_replaced{sprintf($notes_string,$tag,html_escape($object_ref->{'tag'}->{$tag}),html_escape($replace_by))}->{$member->{'ref'}} = $member->{'type'};
                                    }
                                }
                                if ( $object_ref->{'tag'}->{'ref'} ) {
                                    $temp_stop_ref =  ';' . $object_ref->{'tag'}->{'ref'} . ';';
                                    $temp_stop_ref =~ s/\s*;\s*/;/g;

                                    foreach my $sub_ref ( split( $ref_separator, $ref ) ) {
                                        if ( $temp_stop_ref =~ m/;\Q$sub_ref\E;/ ) {
                                            $hint = sprintf( gettext( "(consider creating a 'route_ref' = '%s' tag for the stop)" ), html_escape($sub_ref) );
                                            $notes_string = gettext( "Route: 'ref' = '%s' of stop should represent the reference of the stop, but includes the 'ref' = '%s' of this route %s" );
                                            $to_be_replaced{sprintf($notes_string,html_escape($object_ref->{'tag'}->{'ref'}),html_escape($sub_ref),$hint)}->{$member->{'ref'}} = $member->{'type'};
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
                    push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $message, join(', ', map { printXxxTemplate($not_set_on{$message}->{$_},$_,'name'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $message, join(', ', map { printXxxTemplate($not_set_on{$message}->{$_},$_,'name'); } @help_array )) );
                }
            }
            foreach my $message ( sort( keys( %separator_with_blank_on ) ) ) {
                @help_array     = sort( keys( %{$separator_with_blank_on{$message}} ) );
                $num_of_errors  = scalar( @help_array );
                $ret_val       += $num_of_errors;
                if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("%s: %s and %d more ..."), $message, join(', ', map { printXxxTemplate($separator_with_blank_on{$message}->{$_},$_,'name'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf("%s: %s", $message, join(', ', map { printXxxTemplate($separator_with_blank_on{$message}->{$_},$_,'name'); } @help_array )) );
                }
            }
            foreach my $message ( sort( keys( %comma_as_separator ) ) ) {
                @help_array     = sort( keys( %{$comma_as_separator{$message}} ) );
                $num_of_errors  = scalar( @help_array );
                $ret_val       += $num_of_errors;
                if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("%s: %s and %d more ..."), $message, join(', ', map { printXxxTemplate($comma_as_separator{$message}->{$_},$_,'name'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf("%s: %s", $message, join(', ', map { printXxxTemplate($comma_as_separator{$message}->{$_},$_,'name'); } @help_array )) );
                }
            }
            foreach my $message ( sort( keys( %to_be_replaced ) ) ) {
                @help_array     = sort( keys( %{$to_be_replaced{$message}} ) );
                $num_of_errors  = scalar( @help_array );
                $ret_val       += $num_of_errors;
                if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("%s: %s and %d more ..."), $message, join(', ', map { printXxxTemplate($to_be_replaced{$message}->{$_},$_,'name'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf("%s: %s", $message, join(', ', map { printXxxTemplate($to_be_replaced{$message}->{$_},$_,'name'); } @help_array )) );
                }
            }
            foreach my $message ( sort( keys( %to_be_deleted ) ) ) {
                @help_array     = sort( keys( %{$to_be_deleted{$message}} ) );
                $num_of_errors  = scalar( @help_array );
                $ret_val       += $num_of_errors;
                if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf(gettext("%s: %s and %d more ..."), $message, join(', ', map { printXxxTemplate($to_be_deleted{$message}->{$_},$_,'name'); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
                } else {
                    push( @{$relation_ptr->{'__notes__'}}, sprintf("%s: %s", $message, join(', ', map { printXxxTemplate($to_be_deleted{$message}->{$_},$_,'name'); } @help_array )) );
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
               $issues_string  = gettext( "Error in input data: insufficient data for ways" );
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $issues_string, join(', ', map { printWayTemplate($_); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $issues_string, join(', ', map { printWayTemplate($_); } @help_array )) );
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
               $issues_string  = gettext( "Error in input data: insufficient data for nodes" );
            if ( $max_error && $max_error > 0 && $num_of_errors > $max_error ) {
                push( @{$relation_ptr->{'__issues__'}}, sprintf(gettext("%s: %s and %d more ..."), $issues_string, join(', ', map { printWayTemplate($_); } splice(@help_array,0,$max_error) ), ($num_of_errors-$max_error) ) );
            } else {
                push( @{$relation_ptr->{'__issues__'}}, sprintf("%s: %s", $issues_string, join(', ', map { printWayTemplate($_); } @help_array )) );
            }
            $relation_ptr->{'missing_node_data'}   = 1;
            printf STDERR "%s Error in input data: insufficient data for nodes of route ref=%s\n", get_time(), ( $relation_ptr->{'tag'}->{'ref'} ? $relation_ptr->{'tag'}->{'ref'} : 'no ref' );
        }
    }

    return $ret_val;
}


#############################################################################################
#
#
#############################################################################################

sub getGtfsInfo {
    my $relation_ptr  = shift;

    my $gtfs_guid         = $opt_gtfs_feed;
    my $gtfs_feed         = $opt_gtfs_feed;
    my $feed_info_from    = '--gtfs-feed';
    my $gtfs_release_date = '';
    my $release_date_from = '';
    my $gtfs_country      = '';
    my $gtfs_html_tag     = '';


    if ( $relation_ptr && $relation_ptr->{'tag'} ) {
        if ( $relation_ptr->{'tag'}->{'gtfs:feed'} ) {
            $gtfs_feed      = $relation_ptr->{'tag'}->{'gtfs:feed'};
            $feed_info_from = 'gtfs:feed';
        } elsif ( $relation_ptr->{'tag'}->{'operator:guid'} ) {
            $gtfs_feed      = $relation_ptr->{'tag'}->{'operator:guid'};
            $feed_info_from = 'operator:guid';
        } elsif ( $relation_ptr->{'tag'}->{'network:guid'} ) {
            $gtfs_feed      = $relation_ptr->{'tag'}->{'network:guid'};
            $feed_info_from = 'network:guid';
        }
        $gtfs_guid    =  $gtfs_feed;
        $gtfs_country =  $gtfs_feed;
        $gtfs_country =~ s/-.*$//;

        if ( $relation_ptr->{'tag'}->{'gtfs:release_date'} ) {
            $gtfs_release_date  = $relation_ptr->{'tag'}->{'gtfs:release_date'};
            $release_date_from  = 'gtfs:release_date';
            $gtfs_guid         .= '-' .  $relation_ptr->{'tag'}->{'gtfs:release_date'};
        } elsif ( $relation_ptr->{'tag'}->{'gtfs:source_date'} ) {
            $gtfs_release_date  = $relation_ptr->{'tag'}->{'gtfs:source_date'};
            $release_date_from  = 'gtfs:source_date';
            $gtfs_guid         .= '-' .  $relation_ptr->{'tag'}->{'gtfs:source_date'};
        }

        if ( $relation_ptr->{'tag'}->{'type'} eq 'route' ) {
            if ( $relation_ptr->{'tag'}->{'gtfs:trip_id'} ) {
                $relation_ptr->{'tag'}->{'gtfs:trip_id'} =~ s/\s*;\s*/;/g;
                $gtfs_html_tag = join( ', ', map { GTFS::PtnaSQLite::getGtfsTripIdHtmlTag( $gtfs_feed, $gtfs_release_date, $_ ); } split ( ';', $relation_ptr->{'tag'}->{'gtfs:trip_id'} ) );
            } elsif ( $relation_ptr->{'tag'}->{'gtfs:trip_id:sample'} ) {
                $relation_ptr->{'tag'}->{'gtfs:trip_id:sample'} =~ s/\s*;\s*/;/g;
                $gtfs_html_tag = join( ', ', map { GTFS::PtnaSQLite::getGtfsTripIdHtmlTag( $gtfs_feed, $gtfs_release_date, $_ ); } split ( ';', $relation_ptr->{'tag'}->{'gtfs:trip_id:sample'} ) );
            } elsif ( $relation_ptr->{'tag'}->{'gtfs:shape_id'} ) {
                $relation_ptr->{'tag'}->{'gtfs:shape_id'} =~ s/\s*;\s*/;/g;
                $gtfs_html_tag = join( ', ', map { GTFS::PtnaSQLite::getGtfsShapeIdHtmlTag( $gtfs_feed, $gtfs_release_date, $_ ); } split ( ';', $relation_ptr->{'tag'}->{'gtfs:shape_id'} ) );
            } elsif ( $relation_ptr->{'tag'}->{'gtfs:route_id'} ) {
                $relation_ptr->{'tag'}->{'gtfs:route_id'} =~ s/\s*;\s*/;/g;
                $gtfs_html_tag = join( ', ', map { GTFS::PtnaSQLite::getGtfsRouteIdHtmlTag( $gtfs_feed, $gtfs_release_date, $_ ); } split ( ';', $relation_ptr->{'tag'}->{'gtfs:route_id'} ) );
            }
        } elsif ( $relation_ptr->{'tag'}->{'gtfs:route_id'} ) {
            $relation_ptr->{'tag'}->{'gtfs:route_id'} =~ s/\s*;\s*/;/g;
            $gtfs_html_tag = join( ', ', map { GTFS::PtnaSQLite::getGtfsRouteIdHtmlTag( $gtfs_feed, $gtfs_release_date, $_ ); } split ( ';', $relation_ptr->{'tag'}->{'gtfs:route_id'} ) );
        }
    }

    if ( $gtfs_html_tag ) {
        if ( $gtfs_release_date eq '' ) {
            $gtfs_release_date = ' latest ';
            $release_date_from = ' empty ';
        }
        $gtfs_relation_info_from{$gtfs_feed}{$feed_info_from}{$gtfs_release_date}{$release_date_from}{$relation_ptr->{'id'}} = 1;
    }

    return $gtfs_html_tag;
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
my %id_markers                  = ();                   # printTableSubHeader() auto-generates id='' strings based on 'route_type' and 'ref'; they may appear multiple times
my $local_navigation_at_index   = 0;


sub printInitialHeader {
    my $title       = shift;
    my $osm_base    = shift;
    my $areas       = shift;

    my $html_lang   = $opt_language || 'en';

    $no_of_columns               = 0;
    @columns                     = ();
    @table_columns               = ();

    push( @HTML_start, "<!DOCTYPE html>\n" );
    push( @HTML_start, sprintf( "<html lang=\"%s\">\n", $html_lang ) );
    push( @HTML_start, "    <head>\n" );
    push( @HTML_start, sprintf( "        <title>PTNA - %s</title>\n", ($title ? html_escape($title) : 'Results') ) );
    push( @HTML_start, "        <meta charset=\"utf-8\" />\n" );
    push( @HTML_start, "        <meta name=\"generator\" content=\"PTNA\">\n" );
    push( @HTML_start, "        <meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\" />\n" );
    push( @HTML_start, "        <meta name=\"keywords\" content=\"OSM Public Transport PTv2\">\n" );
    push( @HTML_start, "        <meta name=\"description\" content=\"PTNA - Public Transport Network Analysis\">\n" );
    if ( $opt_test ) {
        push( @HTML_start, "        <style>\n" );
        push( @HTML_start, "            #analysis table           { border-width: 1px; border-style: solid; border-collapse: collapse; vertical-align: center; }\n" );
        push( @HTML_start, "            #analysis th              { border-width: 1px; border-style: solid; border-collapse: collapse; padding: 0.2em; }\n" );
        push( @HTML_start, "            #analysis td              { border-width: 1px; border-style: solid; border-collapse: collapse; padding: 0.2em; }\n" );
        push( @HTML_start, "            #analysis ol              { list-style: none; }\n" );
        push( @HTML_start, "            #analysis img             { width: 20px; vertical-align: top; }\n" );
        push( @HTML_start, "            #analysis .tableheaderrow { background-color: LightSteelBlue;   }\n" );
        push( @HTML_start, "            #analysis .sketchline     { background-color: LightBlue;        }\n" );
        push( @HTML_start, "            #analysis .sketch         { text-align:left;  font-weight: 500; }\n" );
        push( @HTML_start, "            #analysis .csvinfo        { text-align:right; font-size: 0.8em; }\n" );
        push( @HTML_start, "            #analysis .ref            { white-space:nowrap; }\n" );
        push( @HTML_start, "            #analysis .relation       { white-space:nowrap; }\n" );
        push( @HTML_start, "            #analysis .PTv            { text-align:center; }\n" );
        push( @HTML_start, "            #analysis .number         { text-align:right; }\n" );
        push( @HTML_start, "            #analysis .gtfs_feed      { white-space:nowrap; }\n" );
        push( @HTML_start, "            #analysis .feed_from      { white-space:nowrap; }\n" );
        push( @HTML_start, "            #analysis .date           { white-space:nowrap; }\n" );
        push( @HTML_start, "            #analysis .date_from      { white-space:nowrap; }\n" );
        push( @HTML_start, "            #analysis .attention      { background-color: yellow; font-weight: 500; font-size: 1.2em; }\n" );
        push( @HTML_start, "            .gtfs-dateold             { text-align:center; background-color: orange; }\n" );
        push( @HTML_start, "            .gtfs-datenew             { text-align:center; background-color: lightgreen; }\n" );
        push( @HTML_start, "            .gtfs-dateprevious        { text-align:center; background-color: rgb(128, 128, 255); }\n" );
        push( @HTML_start, "            .bad-link                 { text-decoration: line-through; background-color: yellow; }\n" );
        push( @HTML_start, "        </style>\n" );
    } else {
        push( @HTML_start, "        <link rel=\"stylesheet\" href=\"/css/main.css\" />\n" );
        push( @HTML_start, "        <link rel=\"shortcut icon\" href=\"/favicon.ico\" />\n" );
        push( @HTML_start, "        <link rel=\"icon\" type=\"image/png\" href=\"/favicon.png\" sizes=\"32x32\" />\n" );
        push( @HTML_start, "        <link rel=\"icon\" type=\"image/png\" href=\"/favicon.png\" sizes=\"96x96\" />\n" );
        push( @HTML_start, "        <link rel=\"icon\" type=\"image/svg+xml\" href=\"/favicon.svg\" sizes=\"any\" />\n" );
        push( @HTML_start, "        <script>\n" );
        push( @HTML_start, "            function ToggleView() {\n" );
        push( @HTML_start, "                var filename = location.pathname.substring(location.pathname.lastIndexOf(\"/\") + 1);\n" );
        push( @HTML_start, "                var prefix   = filename.substring(0,filename.lastIndexOf(\"-Analysis.\"));\n" );
        push( @HTML_start, "                var suffix   = filename.substring(filename.lastIndexOf(\"-Analysis.\"));\n" );
        push( @HTML_start, "                if ( suffix == '-Analysis.html' ) {\n" );
        push( @HTML_start, "                    filename = prefix + '-Analysis.diff.html';\n" );
        push( @HTML_start, "                } else if ( suffix == '-Analysis.diff.html' ) {\n" );
        push( @HTML_start, "                    filename = prefix + '-Analysis.html';\n" );
        push( @HTML_start, "                }\n" );
        push( @HTML_start, "                window.open( filename, '_self' );\n" );
        push( @HTML_start, "            }\n" );
        push( @HTML_start, "        </script>\n" );
    }
    push( @HTML_start, "    </head>\n" );
    push( @HTML_start, "    <body>\n" );
    if ( !$opt_test ) {
        printPtnaHeader( 'language'       => $opt_language );
    }
    push( @HTML_start, "        <div id=\"analysis\">\n" );
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
    push( @HTML_main, sprintf( "%8s<p>\n",  ' ' ) );
    push( @HTML_main, sprintf( "%12s%s\n",  ' ', gettext("The data will be updated when the result of the analysis has changed.") ) );
    push( @HTML_main, sprintf( "%8s</p>\n", ' ' ) );
    push( @HTML_main, sprintf( "%8s<p>\n",  ' ' ) );
    push( @HTML_main, sprintf( "%12s%s\n",  ' ', gettext("An explanation of the error texts can be found in the documentation at '<a href='/en/index.php#messages'>Messages</a>'.") ) );
    push( @HTML_main, sprintf( "%8s</p>\n", ' ' ) );

}


#############################################################################################

sub printPtnaHeader {
    my %hash        = @_;
    my $language    = $hash{'language'};

    push( @HTML_start, "        <header id=\"headerblock\">\n" );
    push( @HTML_start, "            <div id=\"headerimg\" class=\"logo\">\n" );
    push( @HTML_start, "                <a href=\"/\"><img src=\"/img/logo.png\" alt=\"logo\" /></a>\n" );
    push( @HTML_start, "            </div>\n" );
    push( @HTML_start, "            <div id=\"headertext\">\n" );
    push( @HTML_start, "                <h1><a href=\"/\">PTNA - Public Transport Network Analysis</a></h1>\n" );
    push( @HTML_start, sprintf( "                <h2>%s</h2>\n", gettext("Static Analysis for OpenStreetMap") ) );
    push( @HTML_start, "            </div>\n" );
    push( @HTML_start, "            <div id=\"headernav\">\n" );
    push( @HTML_start, "                <a href=\"/\">Home</a> | \n" );
    push( @HTML_start, sprintf( "                <a href=\"\" onclick=\"ToggleView(); return false;\" title=\"%s\">%s</a> |\n", gettext("Click here to toggle between 'analysis' page and 'differences' page"), gettext("Toggle View") ) );
    push( @HTML_start, "                <a href=\"/contact.html\">Contact</a> | \n" );
    push( @HTML_start, "                <a target=\"_blank\" href=\"https://www.openstreetmap.de/impressum.html\">Impressum</a> | \n" );
    push( @HTML_start, "                <a target=\"_blank\" href=\"https://www.fossgis.de/datenschutzerklärung\">Datenschutzerklärung</a> | \n" );
    push( @HTML_start, "                <a href=\"/en/index.html\" title=\"english\"><img src=\"/img/GreatBritain16.png\" alt=\"Union Jack\" /></a>\n" );
    push( @HTML_start, "                <a href=\"/de/index.html\" title=\"deutsch\"><img src=\"/img/Germany16.png\" alt=\"deutsche Flagge\" /></a>\n" );
    push( @HTML_start, "                <a href=\"/fr/index.html\" title=\"français\"><img src=\"/img/France16.png\" alt=\"drapeau français\" /></a>\n" );
    push( @HTML_start, "            </div>\n" );
    push( @HTML_start, "        </header>\n" );

}


#############################################################################################

sub printFinalFooter {

    push( @HTML_main, "        </div> <!-- analysis -->\n" );
    if ( !$opt_test ) {
        printPtnaFooter( 'language' => $opt_language );
    }
    push( @HTML_main, "        <iframe style=\"display:none\" id=\"hiddenIframe\" name=\"hiddenIframe\"></iframe>\n" );
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

sub printPtnaFooter {
    my %hash        = @_;
    my $language    = $hash{'language'};
}


#############################################################################################

sub printTableOfContents {

    my $toc_line        = undef;
    my $last_level      = 0;
    my $anchor_level    = undef;
    my $header_number   = undef;
    my $label           = undef;
    my $header_text     = undef;

    print "        <h1>";
    print gettext("Contents");
    printf "</h1>\n";
    foreach $toc_line ( @html_header_anchors ) {
        if ( $toc_line =~ m/^A(\d+)\s+N([0-9\.]+)\s+L([^ ]+)\s+T(.*)$/ ) {
            $anchor_level   = $1;
            $header_number  = $2;
            $label          = $3;
            $header_text    = wiki2html($4, 1 );
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
}


#############################################################################################

sub printHintUnassignedRelations {

    push( @HTML_main, "<p>\n" );
    push( @HTML_main, gettext( "This section lists the lines that could not be clearly assigned." ) );
    push( @HTML_main, " " );
    push( @HTML_main, gettext( "The line numbers 'ref' have been specified several times in the CSV file." ) );
    push( @HTML_main, " " );
    push( @HTML_main, gettext( "This means that the same line number exists in the transport network several times in different municipalities / cities." ) );
    push( @HTML_main, " " );
    push( @HTML_main, gettext( "In order to be able to clearly assign the lines, the following should be indicated:" ) );
    push( @HTML_main, "\n</p>" );
    push( @HTML_main, "<ul>\n    <li>" );
    push( @HTML_main, gettext( "Relation" ) );
    push( @HTML_main, ":\n        <ul>\n            <li>" );
    push( @HTML_main, gettext( "'network', 'operator', as well as 'from' and 'to' should be tagged with the relation." ) );
    push( @HTML_main, "\n                <ul>\n                    <li>" );
    push( @HTML_main, gettext( "If the value of 'operator' is sufficient for differentiation, 'from' and 'to' need not be specified." ) );
    push( @HTML_main, "</li>\n                </ul>\n" );
    push( @HTML_main, "            </li>\n" );
    push( @HTML_main, "        </ul>\n" );
    push( @HTML_main, "    </li>\n    <li>" );
    push( @HTML_main, gettext( "CSV file" ) );
    push( @HTML_main, ":\n        <ul>\n            <li>" );
    push( @HTML_main, gettext( "'Operator', as well as 'From' and 'To' should be specified in the CSV file with the same values as with the relation." ) );
    push( @HTML_main, "\n                <ul>\n                    <li>" );
    push( @HTML_main, gettext( "See the instructions for such entries at the beginning of the CSV file." ) );
    push( @HTML_main, "</li>\n                </ul>\n" );
    push( @HTML_main, "            </li>\n" );
    push( @HTML_main, "        </ul>\n" );
    push( @HTML_main, "    </li>\n" );
    push( @HTML_main, "</ul>\n" );
    push( @HTML_main, "<p>\n" );
    push( @HTML_main, gettext( "Examples for an entry in the CSV file of the form: 'ref;type;Comment;From;To;Operator':" ) );
    push( @HTML_main, "\n</p>\n" );
    push( @HTML_main, "<table>\n" );
    push( @HTML_main, "    <thead class=\"tableheaderrow\">\n" );
    push( @HTML_main, "        <tr><th>&nbsp;</th><th>ref</th><th>type</th><th>" );
    push( @HTML_main, gettext( "Comment" ) );
    push( @HTML_main, "</th><th>" );
    push( @HTML_main, gettext( "From" ) );
    push( @HTML_main, "</th><th>" );
    push( @HTML_main, gettext( "To" ) );
    push( @HTML_main, "</th><th>" );
    push( @HTML_main, gettext( "Operator" ) );
    push( @HTML_main, "</th></tr>\n" );
    push( @HTML_main, "    </thead>\n" );
    push( @HTML_main, "    <tbody>\n" );
    push( @HTML_main, "        <tr><td><strong>1.)</strong> </td><td>9</td><td>bus</td><td>Bus 9 " );
    push( @HTML_main, gettext( "provides services in City-A" ) );
    push( @HTML_main, "</td><td>" );
    push( @HTML_main, gettext( "First Avenue" ) );
    push( @HTML_main, "</td><td>" );
    push( @HTML_main, gettext( "Sixth Avenue" ) );
    push( @HTML_main, "</td><td>" );
    push( @HTML_main, gettext( "Operator-X" ) );
    push( @HTML_main, "</td></tr>\n" );
    push( @HTML_main, "        <tr><td><strong>2.)</strong> </td><td>9</td><td>bus</td><td>Bus 9 " );
    push( @HTML_main, gettext( "provides services in Village-B" ) );
    push( @HTML_main, "</td><td>" );
    push( @HTML_main, gettext( "Main Street" ) );
    push( @HTML_main, "</td><td>" );
    push( @HTML_main, gettext( "Second Street" ) );
    push( @HTML_main, "</td><td>" );
    push( @HTML_main, gettext( "Operator-X" ) );
    push( @HTML_main, "</td></tr>\n" );
    push( @HTML_main, "        <tr><td><strong>3.)</strong> </td><td>9</td><td>bus</td><td>Bus 9 " );
    push( @HTML_main, gettext( "provides services in Town-C" ) );
    push( @HTML_main, "</td><td>" );
    push( @HTML_main, gettext( "Sunset Boulevard" ) );
    push( @HTML_main, "</td><td>" );
    push( @HTML_main, gettext( "Rainbow Boulevard" ) );
    push( @HTML_main, "</td><td>" );
    push( @HTML_main, gettext( "Operator-Z" ) );
    push( @HTML_main, "</td></tr>\n" );
    push( @HTML_main, "    </tbody>\n" );
    push( @HTML_main, "</table>\n" );
    push( @HTML_main, "<p>\n   " );
    push( @HTML_main, gettext( "1.) and 2.) are only distinguishable by means of 'From'/'from' and 'To'/'to', since 'Operator'/'operator' are identical (='Operator-X')." ) );
    push( @HTML_main, "<br>\n   " );
    push( @HTML_main, gettext( "1.) and 3.) as well as 2.) and 3.) can be distinguished by 'Operator'/'operator', as these are different (='Operator-X' or ='Operator-Z')." ) );
    push( @HTML_main, "\n</p>\n" );

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
        push( @HTML_main, gettext("The following values and combinations have been found in the provided data but they will not be listed here.") );
        push( @HTML_main, "\n" );
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

    foreach my $network ( sort( keys( %used_networks ) ) ) {
        push( @relations_of_network, keys( %{$used_networks{$network}} ) );
    }

    if ( scalar @relations_of_network > 0 ) {
        printHeader( gettext("Considered 'network'-Values"), 2, 'considerednetworks' );

        push( @HTML_main, "<p>\n" );
        push( @HTML_main, gettext("This section lists the 'network'-values which have been considered; i.e. which match to one of the values above.") );
        push( @HTML_main, "\n</p>\n" );

        printTableInitialization( 'network', 'number', 'relations' );
        printTableHeader();
        foreach my $network ( sort( keys( %used_networks ) ) ) {
            @relations_of_network = sort( keys( %{$used_networks{$network}} ) );
            $network = $network eq '__unset_network__' ? '' : $network;
            if ( scalar @relations_of_network <= 10 ) {
                printTableLine( 'network'           =>    $network,
                                'number'            =>    scalar @relations_of_network,
                                'relations'         =>    join( ',', @relations_of_network )
                            );
            } else {
                printTableLine( 'network'           =>    $network,
                                'number'            =>    scalar @relations_of_network,
                                'relations'         =>    join( ',', splice(@relations_of_network,0,10) ),
                                'and more'          =>    gettext( "and more ..." )
                            );
            }
        }
        printTableFooter();

        if ( scalar keys (%unused_operators) ) {
            push( @HTML_main, "<p>\n" );
            push( @HTML_main, gettext("This section lists the 'operator'-values which have not been considered.") );
            push( @HTML_main, "\n" );
            push( @HTML_main, gettext("They might include typos in values which otherwise should have been considered.") );
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
                                    'relations'         =>    join( ',', splice(@relations_of_operator,0,10) ),
                                    'and more'          =>    gettext( "and more ..." )
                                );
                }
            }
            printTableFooter();
        }
    }
}


#############################################################################################

sub printHintAddedNetworks {

    my @relations_of_network  = ();

    foreach my $network ( sort( keys( %added_networks ) ) ) {
        push( @relations_of_network, keys( %{$added_networks{$network}} ) );
    }

    if ( scalar @relations_of_network > 0 ) {
        printHeader( gettext("Additionally considered 'network'-Values"), 2, 'addednetworks' );

        push( @HTML_main, "<p>\n" );
        push( @HTML_main, gettext("This section lists 'network' values that were additionally considered because the 'network' value of the Route-Master or member Route matched.") );
        push( @HTML_main, "\n</p>\n" );

        printTableInitialization( 'network', 'number', 'relations' );
        printTableHeader();
        foreach my $network ( sort( keys( %added_networks ) ) ) {
            @relations_of_network    = sort( keys( %{$added_networks{$network}} ) );
            $network = $network eq '__unset_network__' ? '' : $network;
            if ( scalar @relations_of_network <= 10 ) {
                printTableLine( 'network'           =>    $network,
                                'number'            =>    scalar @relations_of_network,
                                'relations'         =>    join( ',', @relations_of_network )
                            );
            } else {
                printTableLine( 'network'           =>    $network,
                                'number'            =>    scalar @relations_of_network,
                                'relations'         =>    join( ',', splice(@relations_of_network,0,10) ),
                                'and more'          =>    gettext( "and more ..." )
                            );
            }
        }
        printTableFooter();
    }
}


#############################################################################################

sub printHintUnusedNetworks {

    my @relations_of_network = ();

    foreach my $network ( sort( keys( %unused_networks ) ) ) {
        push( @relations_of_network, keys( %{$unused_networks{$network}} ) );
    }

    if ( scalar @relations_of_network > 0 ) {
        printHeader( gettext("Not Considered 'network'-Values"), 2, 'notconsiderednetworks' );

        push( @HTML_main, "<p>\n" );
        push( @HTML_main, gettext("This section lists the 'network'-values which have not been considered.") );
        push( @HTML_main, "\n" );
        push( @HTML_main, gettext("They might include typos in values which otherwise should have been considered.") );
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
                                'relations'         =>    join( ',', splice(@relations_of_network,0,10) ),
                                'and more'          =>    gettext( "and more ..." )
                            );
            }
        }
        printTableFooter();
    }
}


#############################################################################################

sub printGtfsReferences {

    push( @HTML_main, "<p>\n" );
    push( @HTML_main, gettext("This section lists references to GTFS feed information found in the CSV list and in Route-Master and Route relations.") );
    push( @HTML_main, "\n</p>\n" );

    if ( scalar(keys(%gtfs_csv_info_from)) ) {
        printHeader( gettext("References to GTFS from CSV list"), 2, 'gtfsreferences_csv' );

        push( @HTML_main, "<p>\n" );
        push( @HTML_main, gettext("This section lists the name of the GTFS feed and the related release date information as found in the CSV list.") . "\n" );
        push( @HTML_main, gettext("An empty release date means: reference to the latest GTFS information, the latest available at PTNA.") );
        push( @HTML_main, "\n</p>\n" );

        push( @HTML_main, "<p>\n" );
        push( @HTML_main, gettext("Example") . ":<br />\n" );
        push( @HTML_main, "<code>&nbsp;&nbsp;&nbsp;&nbsp;#ref;route;comment;from;to;operator;gtfs_feed;route_id;release_date</code><br />\n" );
        push( @HTML_main, "<code>&nbsp;&nbsp;&nbsp;&nbsp;210;bus;;Brunnthal, Zusestraße;Neuperlach Süd U S;Verkehrsbetrieb Ettenhuber GmbH;DE-BY-MVV;19-210-s20-1;2020-07-24</code><br />\n" );
        push( @HTML_main, gettext("Where the GTFS feed name is 'DE-BY-MVV' and the release date is '2020-07-24'.") . "\n" );
        push( @HTML_main, "\n</p>\n" );

        printTableInitialization( 'gtfs_feed', 'date' );
        printTableHeader();
        foreach my $gtfs_feed ( sort( keys( %gtfs_csv_info_from ) ) ) {
            foreach my $gtfs_release_date (  sort( keys( %{$gtfs_csv_info_from{$gtfs_feed}} ) ) ) {
                $gtfs_release_date =~ s/ latest //;
                printTableLine( 'gtfs_feed'    =>  $gtfs_feed,
                                'date'         =>  $gtfs_release_date
                              );
            }
        }
        printTableFooter();
    }

    if ( scalar(keys(%gtfs_relation_info_from)) ) {

        my @relations_of_feed = ();

        printHeader( gettext("References to GTFS from relations"), 2, 'gtfsreferences_relations' );

        push( @HTML_main, "<p>\n" );
        push( @HTML_main, gettext("This section lists the name of the GTFS feed and the related release date information as found in Route-Master and Route relations.") . "\n" );
        push( @HTML_main, gettext("An empty release date means: reference to the latest GTFS information, the latest available at PTNA.") . "\n" );
        push( @HTML_main, gettext("In addition to that, the source of the information (name and date) is listed.") . "\n" );
        push( @HTML_main, gettext("The value '--gtfs-feed' refers to the corresponding global analysis option, because no information about the source of the GTFS feed information was found in the Route-Master or Route relation." ) . "\n" );
        push( @HTML_main, "\n</p>\n" );

        push( @HTML_main, "<p>\n" );
        push( @HTML_main, gettext("Example" ) . " (" . gettext("key = value") . "):<br />\n" );
        push( @HTML_main, "<code>&nbsp;&nbsp;&nbsp;&nbsp;gtfs:feed&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;=&nbsp;DE-BY-MVV</code><br />\n" );
        push( @HTML_main, "<code>&nbsp;&nbsp;&nbsp;&nbsp;gtfs:release_date&nbsp;=&nbsp;2020-07-24</code><br />\n" );
        push( @HTML_main, "<code>&nbsp;&nbsp;&nbsp;&nbsp;gtfs:route_id&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;=&nbsp;19-210-s20-1</code><br />\n" );
        push( @HTML_main, "\n</p>\n" );

        printTableInitialization( 'gtfs_feed', 'feed_from', 'date', 'date_from', 'number', 'relations' );
        printTableHeader();
        foreach my $gtfs_feed ( sort( keys( %gtfs_relation_info_from ) ) ) {
            foreach my $feed_from ( sort( keys( %{$gtfs_relation_info_from{$gtfs_feed}} ) ) ) {
                foreach my $gtfs_release_date ( sort( keys( %{$gtfs_relation_info_from{$gtfs_feed}{$feed_from}} ) ) ) {
                    foreach my $date_from ( sort( keys( %{$gtfs_relation_info_from{$gtfs_feed}{$feed_from}{$gtfs_release_date}} ) ) ) {
                        my $grd = $gtfs_release_date;
                           $grd =~ s/ latest //;
                        my $df  = $date_from;
                           $df  =~ s/ empty //;
                        @relations_of_feed    = sort( keys( %{$gtfs_relation_info_from{$gtfs_feed}{$feed_from}{$gtfs_release_date}{$date_from}} ) );
                        if ( scalar @relations_of_feed <= 10 ) {
                            printTableLine( 'gtfs_feed' =>  $gtfs_feed,
                                            'feed_from' =>  $feed_from,
                                            'date'      =>  $grd,
                                            'date_from' =>  $df,
                                            'number'    =>  scalar @relations_of_feed,
                                            'relations' =>  join( ',', @relations_of_feed )
                                        );
                        } else {
                            printTableLine( 'gtfs_feed' =>  $gtfs_feed,
                                            'feed_from' =>  $feed_from,
                                            'date'      =>  $grd,
                                            'date_from' =>  $df,
                                            'number'    =>  scalar @relations_of_feed,
                                            'relations' =>  join( ',', splice(@relations_of_feed,0,10) ),
                                            'and more'  =>  gettext( "and more ..." )
                                        );
                        }
                    }
                }
            }
        }
        printTableFooter();
    }
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
    push( @HTML_main, "" );
    $local_navigation_at_index = $#HTML_main;
}


#############################################################################################

sub printText {
    my $text = shift;

    $printText_buffer = "<p>\n"   unless ( $printText_buffer );

    if ( $text ) {
        my $wikitext = wiki2html( $text );
        while ( $wikitext =~ m/^\s/ ) {
            $wikitext =~ s/^(\s*)\s/$1&nbsp;/;
        }
        $printText_buffer .= sprintf( "%s\n", $wikitext );
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
    my %hash                = ( @_ );
    my $ref                 = $hash{'ref'}           || '';
    my $ref_or_list         = $hash{'ref-or-list'};
    my $network             = $hash{'network'}       || '';
    my $operator            = $hash{'operator'}      || '';
    my $pt_type             = $hash{'pt_type'}       || '';
    my $colour              = $hash{'colour'}        || '';
    my $ref_text            = undef;
    my $csv_text            = '';       # some information comming from the CSV input file
    my $info                = '';
    my @ref_or_array        = ();
    my $ref_or_list_text    = '';
    my $id_string           = '';
    my $id_label            = '';

    if ( $ref_or_list ) {
        @ref_or_array = @{$ref_or_list};
        $ref_or_list_text = join(' ', @ref_or_array );
    } elsif ( $ref ) {
        push( @ref_or_array, $ref );
        $ref_or_list_text = $ref;
    }

    if ( scalar @ref_or_array ) {
        $ref_text = join(' ', map { printSketchLineTemplate( $_, $network, $operator, $pt_type, $colour ) } @ref_or_array );
    }

    if ( scalar @ref_or_array && $pt_type ) {
        my $id_label  = sprintf( "%s_%s", $pt_type, join('_', @ref_or_array ) );
           $id_label  =~ s/[^0-9A-Za-z_.-]/_/g;                                # other characters are not allowed in 'id'
        my $nav_label = '';
        if ( $id_markers{$id_label} ) {                                        # if the same combination appears more than one, add a number as suffix (e.g. "Bus A" of VMS in Saxony, Germany
            $id_markers{$id_label}++;
            $nav_label = sprintf( "%s-%d", $id_label, $id_markers{$id_label} );
        } else {
            $id_markers{$id_label} = 1;
            $nav_label = $id_label;
        }
        $id_string = sprintf( "id=\"%s\" ", $nav_label );
        printAddIdLabelToLocalNavigation( $nav_label, join(' ',@ref_or_array), $colour );
    }

    if ( $hash{'CSV-Comment'}  ) {
        $csv_text .= sprintf( "%s: %s; ", ( $column_name{'CSV-Comment'}  ? $column_name{'CSV-Comment'}  : 'Comment' ),  wiki2html( $hash{'CSV-Comment'} )  );
        $csv_text =~ s|!([^!]+)!|<span class=\"attention\">$1</span>|g;
    }
    $csv_text .= sprintf( "%s: %s; ", ( $column_name{'CSV-From'}          ? $column_name{'CSV-From'}          : 'From' ),          html_escape($hash{'CSV-From'})     )      if ( $hash{'CSV-From'}          );
    $csv_text .= sprintf( "%s: %s; ", ( $column_name{'CSV-To'}            ? $column_name{'CSV-To'}            : 'To' ),            html_escape($hash{'CSV-To'})       )      if ( $hash{'CSV-To'}            );
    $csv_text .= sprintf( "%s: %s; ", ( $column_name{'CSV-Operator'}      ? $column_name{'CSV-Operator'}      : 'Operator' ),      html_escape($hash{'CSV-Operator'}) )      if ( $hash{'CSV-Operator'}      );
    if ( $hash{'GTFS-Feed'} && $hash{'GTFS-Route-Id'} ) {
        if ( $hash{'GTFS-Release-Date'} ) {
            printf STDERR "printTableSubHeader(1): \$gtfs_csv_info_from{$hash{'GTFS-Feed'}}{$hash{'GTFS-Release-Date'}} = 1;\n" if ( $debug );
            $gtfs_csv_info_from{$hash{'GTFS-Feed'}}{$hash{'GTFS-Release-Date'}} = 1;
            $csv_text .= join( ', ', map { GTFS::PtnaSQLite::getGtfsRouteIdHtmlTag( $hash{'GTFS-Feed'}, $hash{'GTFS-Release-Date'}, $_ ); } split( ';', $hash{'GTFS-Route-Id'} ) );
        } else {
            printf STDERR "printTableSubHeader(1): \$gtfs_csv_info_from{$hash{'GTFS-Feed'}}{' latest } = 1;\n" if ( $debug );
            $gtfs_csv_info_from{$hash{'GTFS-Feed'}}{' latest '} = 1;
            $csv_text .= join( ', ', map { GTFS::PtnaSQLite::getGtfsRouteIdHtmlTag( $hash{'GTFS-Feed'}, '', $_ ); } split( ';', $hash{'GTFS-Route-Id'} ) );
        }
    } else {
        if ( $hash{'GTFS-Feed'} ) {
            if ( $hash{'GTFS-Release-Date'} ) {
                printf STDERR "printTableSubHeader(2): \$gtfs_csv_info_from{$hash{'GTFS-Feed'}}{$hash{'GTFS-Release-Date'}} = 1;\n" if ( $debug );
                $gtfs_csv_info_from{$hash{'GTFS-Feed'}}{$hash{'GTFS-Release-Date'}} = 1;
                $csv_text .= GTFS::PtnaSQLite::getGtfsRouteIdHtmlTag( $hash{'GTFS-Feed'}, $hash{'GTFS-Release-Date'}, '' );
            } else {
                printf STDERR "printTableSubHeader(2): \$gtfs_csv_info_from{$hash{'GTFS-Feed'}}{' latest } = 1;\n" if ( $debug );
                $gtfs_csv_info_from{$hash{'GTFS-Feed'}}{' latest '} = 1;
                $csv_text .= GTFS::PtnaSQLite::getGtfsRouteIdHtmlTag( $hash{'GTFS-Feed'},'','' );
            }
        } elsif ( $hash{'GTFS-Route-Id'} ) {
            $csv_text .= join( ', ', map { sprintf( "%s: %s; ", ( $column_name{'GTFS-Route-Id'} ? $column_name{'GTFS-Route-Id'} : 'GTFS-Route-Id' ), html_escape($_) ); } split( ';', $hash{'GTFS-Route-Id'} ) );
        }
    }
    $csv_text =~ s/; $//;

    $info = $csv_text ? $csv_text : '???';
    $info =~ s/\"/_/g;

    if ( $no_of_columns > 1 && $ref_or_list_text && $ref_text ) {
        push( @HTML_main, sprintf( "%16s<tr %sdata-info=\"%s\" data-ref=\"%s\" class=\"sketchline\"><td class=\"sketch\">%s</td><td class=\"csvinfo\" colspan=\"%d\">%s</td></tr>\n", ' ', $id_string, $info, $ref_or_list_text, $ref_text, $no_of_columns-1, $csv_text ) );
    }
}


#############################################################################################

sub printTableLine {
    my %hash        = ( @_ );
    my $val         = undef;
    my $i           = 0;
    my $ref         = $hash{'ref'} || '???';
    my $info        = $hash{'relation'} ? $hash{'relation'}       : ( $hash{'network'} ? $hash{'network'} : $ref);
    my $andmore     = $hash{'and more'} ? ' ' . $hash{'and more'} : '';
    my $id_string   = '';

    if ( $hash{'relation'} ) {
        $id_string = html_escape($hash{'relation'});
        $id_string =~ s/[^0-9A-Za-z_.-]/_/g;                                    # other characters are not allowed in 'id'
        if ( $id_markers{$id_string} ) {                                        # don't print id="<relation-id>" a second time, once is enough
            $id_string = '';
        } else {
            $id_markers{$id_string} = 1;
            $id_string = sprintf( "id=\"%s\" ", $id_string );
        }
    } elsif ( $hash{'gtfs_feed'} ) {
        $info = 'GTFS';
        if ( $hash{'date'} ) {
            $ref  = $hash{'gtfs_feed'} . '-' . $hash{'date'};
        } else {
            $ref  = $hash{'gtfs_feed'};
        }
    }

    $info =~ s/\"/_/g;
    push( @HTML_main, sprintf( "%16s<tr %sdata-info=\"%s\" data-ref=\"%s\" class=\"line\">", ' ', $id_string, html_escape($info), html_escape($ref) ) );
    for ( $i = 0; $i < $no_of_columns; $i++ ) {
        $val =  $hash{$columns[$i]} || '';
        if ( $columns[$i] eq "relation" ) {
            push( @HTML_main, sprintf( "<td class=\"relation\">%s</td>", printRelationTemplate($val) ) );
        } elsif ( $columns[$i] eq "relations"  ){
            push( @HTML_main, sprintf( "<td class=\"relations\">%s%s</td>", join( ', ', map { printRelationTemplate($_,'ref'); } split( ',', $val ) ), $andmore ) );
        } elsif ( $columns[$i] eq "issues"  ){
            $val =~ s/__separator__/<br>/g;
            push( @HTML_main, sprintf( "<td class=\"%s\">%s</td>", $columns[$i], $val ) );
        } elsif ( $columns[$i] eq "notes"  ){
            $val =~ s/__separator__/<br>/g;
            push( @HTML_main, sprintf( "<td class=\"%s\">%s</td>", $columns[$i], $val ) );
        } elsif ( $columns[$i] eq "gtfs_feed"  ) {
            push( @HTML_main, sprintf( "<td class=\"%s\">%s</td>", $columns[$i], GTFS::PtnaSQLite::getGtfsLinkToRoutes( $hash{'gtfs_feed'}, $hash{'date'} ))  );
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
    my $rel_id  = shift;
    my $tags    = shift;

    my $val     = $rel_id;

    if ( $rel_id ) {
        my $info_string = '';
        if ( $tags ) {
            foreach my $tag ( split( ';', $tags ) ) {
                if ( $RELATIONS{$rel_id} && $RELATIONS{$rel_id}->{'tag'} && $RELATIONS{$rel_id}->{'tag'}->{$tag} ) {
                    $info_string .= sprintf( "'%s' ", $RELATIONS{$rel_id}->{'tag'}->{$tag} );
                    last;
                }
            }
        }

        my $image_url = "<img src=\"/img/Relation.svg\" alt=\"Relation\" />";

        if ( $rel_id > 0 ) {
            my $relation_url = sprintf( "<a href=\"https://osm.org/relation/%s\" title=\"%s\">%s</a>", $rel_id, html_escape(gettext("Browse on map")), $rel_id );
            my $id_url       = sprintf( "<a href=\"https://osm.org/edit?editor=id&amp;relation=%s\" title=\"%s\">iD</a>", $rel_id, html_escape(gettext("Edit in iD")) );
            my $josm_url     = sprintf( "<a href=\"http://127.0.0.1:8111/load_object?new_layer=false&amp;relation_members=true&amp;objects=r%s\" target=\"hiddenIframe\" title=\"%s\">JOSM</a>", $rel_id, html_escape(gettext("Edit in JOSM")) );

            $val = sprintf( "%s %s%s <small>(%s, %s", $image_url, $info_string, $relation_url, $id_url, $josm_url );

            if ( $RELATIONS{$rel_id} && $RELATIONS{$rel_id}->{'show_relation'} ) {
                my $langparam   = $opt_language? '&lang=' . uri_escape($opt_language) : '';
                my $show_url    = sprintf( "<a href=\"/relation.php?id=%d%s\" title=\"%s\">PTNA</a>", $rel_id, $langparam, html_escape(gettext("Show relation on special map")) );
                $val .= sprintf( ", %s", $show_url );
            }

            if ( $RELATIONS{$rel_id} && $RELATIONS{$rel_id}->{'GTFS-HTML-TAG'} ) {
                $val .= sprintf( ", %s", $RELATIONS{$rel_id}->{'GTFS-HTML-TAG'} );
            }

            $val .= ")</small>";
        } else {
            $val = sprintf( "%s %s%s", $image_url, $info_string, $rel_id );

            if ( $RELATIONS{$rel_id} && $RELATIONS{$rel_id}->{'GTFS-HTML-TAG'} ) {
                $val .= sprintf( " <small>(%s)</small>", $RELATIONS{$rel_id}->{'GTFS-HTML-TAG'} );
            }

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
            my $way_url   = sprintf( "<a href=\"https://osm.org/way/%s\" title=\"%s\">%s</a>", $val, html_escape(gettext("Browse on map")), $val );
            my $id_url    = sprintf( "<a href=\"https://osm.org/edit?editor=id&amp;way=%s\" title=\"%s\">iD</a>", $val, html_escape(gettext("Edit in iD")) );
            my $josm_url  = sprintf( "<a href=\"http://127.0.0.1:8111/load_object?new_layer=false&amp;objects=w%s\" target=\"hiddenIframe\" title=\"%s\">JOSM</a>", $val, html_escape(gettext("Edit in JOSM")) );

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
            my $node_url = sprintf( "<a href=\"https://osm.org/node/%s\" title=\"%s\">%s</a>", $val, html_escape(gettext("Browse on map")), $val );
            my $id_url   = sprintf( "<a href=\"https://osm.org/edit?editor=id&amp;node=%s\" title=\"%s\">iD</a>", $val, html_escape(gettext("Edit in iD")) );
            my $josm_url = sprintf( "<a href=\"http://127.0.0.1:8111/load_object?new_layer=false&amp;objects=n%s\" target=\"hiddenIframe\" title=\"%s\">JOSM</a>", $val, html_escape(gettext("Edit in JOSM")) );

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
    my $ref               = shift;
    my $network           = shift;
    my $operator          = shift || '';
    my $pt_type           = shift || '';
    my $colour            = shift || '';
    my $text              = undef;
    my $colour_string     = '';
    my $pt_string         = '';
    my $a_begin           = '';
    my $a_end             = '';
    my $outer_span_begin  = '';
    my $inner_span_begin  = '';
    my $outer_span_end    = '';
    my $inner_span_end    = '';
    my $bg_colour         = GetColourFromString( $colour );
    my $fg_colour         = GetForeGroundFromBackGround( $bg_colour );

    if ( $bg_colour && $fg_colour && $coloured_sketchline ) {
        $colour_string    = "&bg=" . uri_escape($bg_colour) . "&fg=". uri_escape($fg_colour);
        $pt_string        = "&r=1"                                        if ( $pt_type eq 'train' || $pt_type eq 'light_rail'     );
        $outer_span_begin = sprintf( "<span style=\"background-color: %s; border-style: solid; border-color: gray; border-width: 1px;\">&nbsp;", $bg_colour );
        $inner_span_begin = sprintf( "<span style=\"color: %s\">", $fg_colour );
        $outer_span_end   = "&nbsp;</span>";
        $inner_span_end   = "</span>";
    }

    if ( $network || $operator ) {
        $a_begin = sprintf( "<a href=\"https://overpass-api.de/api/sketch-line?ref=%s&network=%s&operator=%s&style=wuppertal%s%s\" title=\"Sketch-Line\">", uri_escape($ref), uri_escape($network), uri_escape($operator), $colour_string, $pt_string );
        $a_end   = '</a>';
    }

    $text = sprintf( "%s%s%s%s%s%s%s", $outer_span_begin, $a_begin, $inner_span_begin, $ref, $inner_span_end, $a_end, $outer_span_end );

    return $text;
}


#############################################################################################

sub printAddIdLabelToLocalNavigation {
    my $id_label        = shift;
    my $visible_string  = shift;
    my $colour          = shift;

    if ( !$no_additional_navigation && $local_navigation_at_index && $id_label && $visible_string ) {

        my $bg_colour   = GetColourFromString( $colour );
        my $fg_colour   = GetForeGroundFromBackGround( $bg_colour );
        my $outer_span_begin  =  '';
        my $inner_span_begin  =  '';
        my $outer_span_end    =  '';
        my $inner_span_end    =  '';

        $HTML_main[$local_navigation_at_index] =~ s|</br></br>\n$||;
        if ( $bg_colour && $fg_colour && $coloured_sketchline ) {
            $outer_span_begin = sprintf( "<span style=\"background-color: %s; border-style: solid; border-color: gray; border-width: 1px;\"><nobr>&nbsp;", $bg_colour );
            $inner_span_begin = sprintf( "<span style=\"color: %s\">", $fg_colour );
            $outer_span_end   = "&nbsp;</nobr></span>";
            $inner_span_end   = "</span>";
        }
        $HTML_main[$local_navigation_at_index] .= sprintf( "%s<a href=\"#%s\">%s%s%s</a>%s </br></br>\n", $outer_span_begin, html_escape($id_label), $inner_span_begin, html_escape($visible_string), $inner_span_end, $outer_span_end );
    }

    return;
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
        #$text =~ s/Ä/&Auml;/g;
        #$text =~ s/ä/&auml;/g;
        #$text =~ s/Ö/&Ouml;/g;
        #$text =~ s/ö/&ouml;/g;
        #$text =~ s/Ü/&Uuml;/g;
        #$text =~ s/ü/&uuml;/g;
        #$text =~ s/ß/&szlig;/g;
    }
    return $text;
}


#############################################################################################

sub uri_escape {
    my $text = shift;
    if ( $text ) {
        $text =~ s/([ !"#\$%&'()*+,.\/:;<=>?@\[\\\]{|}-])/ sprintf "%%%02x", ord $1 /eg;
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
    my $text           = shift;
    my $suppress_links = shift || 0;
    my $sub            = undef;
    if ( $text ) {
        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
        $text =~ s/>/&gt;/g;
        $text =~ s/"/&quot;/g;
        # ignore: [[Category:Nürnberg]]
        $text =~ s/\[\[Category:[^\]]+\]\]//g;
        # convert: [[Nürnberg/Transportation/Analyse/DE-BY-VGN-Linien|VGN Linien]]
        while ( $text =~ m/\[\[([^|]+)\|([^\]]+)\]\]/g ) {
            if ( $suppress_links ) {
                $sub = $2;
            } else {
                $sub = sprintf( "<a href=\"https://wiki.openstreetmap.org/wiki/%s\">%s</a>", $1, $2 );
            }
            $text =~ s/\[\[[^|]+\|[^\]]+\]\]/$sub/;
        }
        # convert: [[Nürnberg/Transportation/Analyse/DE-BY-VGN-Linien]]
        while ( $text =~ m/\[\[([^\]]+)\]\]/g ) {
            if ( $suppress_links ) {
                $sub = $1;
            } else {
                $sub = sprintf( "<a href=\"https://wiki.openstreetmap.org/wiki/%s\">%s</a>", $1, $1 );
            }
            $text =~ s/\[\[[^\]]+\]\]/$sub/;
        }
        # convert: [https://example.com/index.html External Link]
        while ( $text =~ m/\[([^ ]+) ([^\]]+)\]/g ) {
            if ( $suppress_links ) {
                $sub = $2;
            } else {
                $sub = sprintf( "<a href=\"%s\">%s</a>", $1, $2 );
            }
            $text =~ s/\[[^ ]+ [^\]]+\]/$sub/;
        }
        # convert: [https://example.com/index.html]
        while ( $text =~ m/\[([^\]]+)\]/g ) {
            if ( $suppress_links ) {
                $sub = $1;
            } else {
                $sub = sprintf( "<a href=\"%s\">%s</a>", $1, $1 );
            }
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
        $text =~ s/'/&#039;/g;
    }
    return $text;
}


#############################################################################################

sub GetColourFromString {

    my $string      = shift;
    my $ret_value   = undef;

    if ( $string ) {
        $string = lc( $string );
        if ( $string =~ m/^#[a-f0-9]{6}$/ ) {
            $ret_value= $string;
        } elsif ( $string =~ m/^#([a-f0-9])([a-f0-9])([a-f0-9])$/ ) {
            $ret_value= lc("#" . $1 . $1 . $2 . $2 . $3 . $3);
        } else {
            $ret_value = ( $colour_table{$string} ) ? lc($colour_table{$string}) : undef;
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


#############################################################################################
#
# overwrite Locale::gettext::gettext() by our own function which simply decodes the getrieved data
#
#############################################################################################

sub gettext {
    return decode( 'utf8', Locale::gettext::gettext( @_ ) );
}


#############################################################################################
#
# overwrite Locale::gettext::ngettext() by our own function which simply decodes the getrieved data
#
#############################################################################################

sub ngettext {
    return decode( 'utf8', Locale::gettext::ngettext( @_ ) );
}

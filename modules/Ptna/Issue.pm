package Ptna::Issue;

use strict;
use warnings;

use Locale::gettext qw();       # 'gettext()' and 'ngettext()' are overwritten in this file, so don't import them
use Encode;


#############################################################################################
#
# constructor: returns a blessed hash reference which stores the 'codename' of the issue as string
# and, in 'args', a reference to the list of any further arguments (their number depends on the codename)
#
#############################################################################################

sub new {
    my ( $class, $codename, @args ) = @_;

    my $self     = bless { 'codename' => "$codename", 'args' => \@args }, $class;

    return $self;
}


#############################################################################################
#
# dispatch table: issue codename => sub which takes the further arguments of the issue
# (see args()) and returns the translated, human readable message for that issue
#
#############################################################################################

my %TO_STRING = (
    'note.tag_value' => sub {
        my ( $tag, $value ) = @_;
        return sprintf q{'%s' = '%s'}, $tag, $value;
    },
    'note.tag_url' => sub {
        my ( $tag, $value ) = @_;
        return sprintf q{'%s' ~ '%s'}, $tag, $value;
    },
    'access.barrier' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( q{Route: restricted access at barrier (%s) without 'psv'='yes', '%s'='yes', '%s'='designated', or ...}, q{Route: restricted access at barriers (%s) without 'psv'='yes', '%s'='yes', '%s'='designated', or ...}, $count );
        return sprintf $issues_string, @args;
    },
    'access.platform' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( q{Route: restricted access (%s) at platform without 'psv'='yes', '%s'='yes', '%s'='designated', or ...}, q{Route: restricted access (%s) at platforms without 'psv'='yes', '%s'='yes', '%s'='designated', or ...}, $count );
        return sprintf $issues_string, @args;
    },
    'access.platform_foot' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( 'Route: restricted access (%s) for pedestrians at platform', 'Route: restricted access (%s) for pedestrians at platforms', $count );
        return sprintf $issues_string, @args;
    },
    'access.platform_school_bus' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( 'Route: restricted access (%s) for a school bus at platform', 'Route: restricted access (%s) for a school bus at platforms', $count );
        return sprintf $issues_string, @args;
    },
    'access.way_busway' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( q{Route: incorrect access restriction (%s) to way. Consider tagging as 'busway'='%s'}, q{Route: incorrect access restriction (%s) to ways. Consider tagging as 'busway'='%s'}, $count );
        return sprintf $issues_string, @args;
    },
    'access.way_designated' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( q{Route: restricted access (%s) to way. Consider tagging as '%s'='yes', '%s'=designated, or ... along with 'motor_vehicle='no'}, q{Route: restricted access (%s) to ways. Consider tagging as '%s'='yes', '%s'=designated, or ... along with 'motor_vehicle='no'}, $count );
        return sprintf $issues_string, @args;
    },
    'access.way_no_psv' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( q{Route: restricted access (%s) to way without 'psv'='yes', '%s'='yes', '%s'='designated', or ...}, q{Route: restricted access (%s) to ways without 'psv'='yes', '%s'='yes', '%s'='designated', or ...}, $count );
        return sprintf $issues_string, @args;
    },
    'access.way_no_yes' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( q{Route: incorrect access restriction (%s) to way. Consider tagging as '%s'='no' and '%s'='yes'}, q{Route: incorrect access restriction (%s) to ways. Consider tagging as '%s'='no' and '%s'='yes'}, $count );
        return sprintf $issues_string, @args;
    },
    'access.way_psv_included' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( q{Route: restricted access (%s) to way. The key '%s' also includes public transport buses}, q{Route: restricted access (%s) to ways, The key '%s' also includes public transport buses}, $count );
        return sprintf $issues_string, @args;
    },
    'access.way_school' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( q{Route: restricted access ('%s'='school') to way for a route relation not tagged with 'bus'='school'}, q{Route: restricted access ('%s'='school') to ways for a route relation not tagged with 'bus'='school'}, $count );
        return sprintf $issues_string, @args;
    },
    'access.way_suspicious_lanes' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( q{Route: suspicious access restriction (%s) to way. Check whether this should be '%s:lanes%s'='%s'}, q{Route: suspicious access restriction (%s) to ways. Check whether this should be '%s:lanes%s'='%s'}, $count );
        return sprintf $issues_string, @args;
    },
    'access.way_suspicious_psv' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( q{Route: suspicious access restriction (%s) to way. Check whether this should be '%s'='yes' or 'psv'='yes'}, q{Route: suspicious access restriction (%s) to ways. Check whether this should be '%s'='yes' or 'psv'='yes'}, $count );
        return sprintf $issues_string, @args;
    },
    'colour.missing_hash' => sub {
        my $issues_string = gettext( q{'%s' has unknown value '%s'. Add '#' as first character.} );
        return sprintf $issues_string, @_;
    },
    'colour.unknown_value' => sub {
        my $issues_string = gettext( q{'%s' has unknown value '%s'. Choose one of the 140 well defined HTML/CSS colour names or the HTML Hex colour codes '#...' or '#......'.} );
        return sprintf $issues_string, @_;
    },
    'data.insufficient_nodes' => sub {
        return gettext( 'Error in input data: insufficient data for nodes' );
    },
    'data.insufficient_relations' => sub {
        return gettext( 'Error in input data: insufficient data for relations' );
    },
    'data.insufficient_relations_dist' => sub {
        my ( $first, $second ) = @_;
        return sprintf '%s: %s, %s', gettext( 'Error in input data: insufficient data for relations' ), $first, $second;
    },
    'data.insufficient_ways' => sub {
        return gettext( 'Error in input data: insufficient data for ways' );
    },
    'data.skipped_incomplete' => sub {
        return gettext( 'Skipping further analysis. PTNA did not download all needed OSM data.' );
    },
    'date.not_exists' => sub {
        my ( $tag, $value ) = @_;
        return sprintf q{'%s' = '%s': %s}, $tag, $value, gettext( 'The date does not exist' );
    },
    'gtfs.deprecated_key' => sub {
        my $issues_string = gettext( q{Deprecated GTFS key '%s'. For valid key names, see the} );
        $issues_string .= ' %s';
        return sprintf $issues_string, @_;
    },
    'gtfs.invalid_feed_code' => sub {
        my $issues_string = gettext( q{Invalid GTFS feed code ('%s') in GTFS key '%s'. For valid feed codes, see the} );
        $issues_string .= ' %s';
        return sprintf $issues_string, @_;
    },
    'gtfs.invalid_key' => sub {
        my $issues_string = gettext( q{Invalid GTFS key '%s'. For valid key names, see the} );
        $issues_string .= ' %s';
        return sprintf $issues_string, @_;
    },
    'gtfs.key_has_feed_suffix' => sub {
        my $issues_string = gettext( q{Invalid GTFS key '%s'. This key must not have any feed code as suffix.} );
        return sprintf $issues_string, @_;
    },
    'gtfs.mixed_feed_suffix' => sub {
        my $issues_string = gettext( q{Mixed use of GTFS keys with and without feed code as suffix. E.g.: '%s' and '%s'.} );
        return sprintf $issues_string, @_;
    },
    'gtfs.orphaned_key' => sub {
        my $issues_string = gettext( q{Orphaned GTFS key '%s' = '%s' with no other GTFS-specific information.} );
        return sprintf $issues_string, @_;
    },
    'gtfs.problem' => sub {
        my ( $problem ) = @_;
        return $problem;
    },
    'master.fewer_routes' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( 'Route-Master has less Routes than actually match (%d versus %d) in the given data set', 'Route-Masters have less Routes than actually match (%d versus %d) in the given data set', $count );
        return sprintf $issues_string, @args;
    },
    'master.has_nodes' => sub {
        return gettext( 'Route-Master with Node(s)' );
    },
    'master.has_relations' => sub {
        return gettext( q{Route-Master with Relation(s) unequal to 'route'} );
    },
    'master.has_ways' => sub {
        return gettext( 'Route-Master with Way(s)' );
    },
    'master.members_with_role' => sub {
        my ( $count ) = @_;
        my $issues_string = ngettext( q{Route-Master has %d member with 'role' being set}, q{Route-Master has %d members with 'role' being set}, $count );
        return sprintf $issues_string, $count;
    },
    'master.members_with_role_list' => sub {
        my ( $count, $roles ) = @_;
        my $prefix_string = ngettext( q{Route-Master has %d member with 'role' being set}, q{Route-Master has %d members with 'role' being set}, $count );
        my $prefix = sprintf $prefix_string, $count;
        return sprintf q{%s: 'role' = '%s'.}, $prefix, join q{', 'role' = '}, @{$roles};
    },
    'master.more_routes' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( 'Route-Master has more Routes than actually match (%d versus %d) in the given data set', 'Route-Masters have more Routes than actually match (%d versus %d) in the given data set', $count );
        return sprintf $issues_string, @args;
    },
    'master.multiple' => sub {
        return gettext( 'There is more than one Route-Master' );
    },
    'master.no_ref_in_data' => sub {
        my $issues_string = gettext( q{Route-Master exists in the given data set but 'ref' tag is not set: %s} );
        return sprintf $issues_string, @_;
    },
    'master.no_routes' => sub {
        return gettext( 'Route-Master without Route(s)' );
    },
    'master.other_section_ref' => sub {
        my $issues_string = gettext( q{Route-Master might be listed with 'ref' = '%s' in a different section or in section 'Not clearly assigned routes' of this analysis: %s} );
        return sprintf $issues_string, @_;
    },
    'master.other_section_unknown_ref' => sub {
        my ( $masters_ref ) = @_;
        my $issues_string = gettext( q{Route-Master might be listed with unknown 'ref' in section 'Public Transport Lines without 'ref'' of this analysis: %s} );
        return sprintf $issues_string, $masters_ref;
    },
    'master.ref_mismatch' => sub {
        my $issues_string = gettext( q{Route-Master has not matching 'ref' = '%s': %s} );
        return sprintf $issues_string, @_;
    },
    'name.not_set' => sub {
        return gettext( q{'name' is not set} );
    },
    'network.differs_from_master' => sub {
        my $issues_string = gettext( q{'network' = '%s' of Route does not fit to 'network' = '%s' of Route-Master: %s} );
        return sprintf $issues_string, @_;
    },
    'network.not_set' => sub {
        return gettext( q{'network' is not set} );
    },
    'operator.differs_from_master' => sub {
        my $issues_string = gettext( q{'operator' = '%s' of Route does not fit to 'operator' = '%s' of Route-Master: %s} );
        return sprintf $issues_string, @_;
    },
    'operator.irrelevant_value' => sub {
        my $issues_string = gettext( q{Route has 'operator' = '%s' value which is considered as not relevant: %s} );
        return sprintf $issues_string, @_;
    },
    'ptv2.empty_role_no_pt' => sub {
        return gettext( q{PTv2 route: empty 'role' and 'public_transport' is not set on object} );
    },
    'ptv2.empty_role_platform' => sub {
        return gettext( q{PTv2 route: empty 'role'. Consider setting 'role'='platform' or 'role'='platform_entry_only' or 'role'='platform_exit_only'} );
    },
    'ptv2.empty_role_stop' => sub {
        return gettext( q{PTv2 route: empty 'role'. Consider setting 'role'='stop' or 'role'='stop_entry_only' or 'role'='stop_exit_only'} );
    },
    'ptv2.empty_role_stop_relation' => sub {
        return gettext( q{PTv2 route: empty 'role' for a relation object which has 'public_transport'='stop_position' set. For PTv2, 'public_transport'='stop_position' is allow on nodes only} );
    },
    'ptv2.empty_role_stop_way' => sub {
        return gettext( q{PTv2 route: empty 'role' for a way object which has 'public_transport'='stop_position' set. For PTv2, 'public_transport'='stop_position' is allow on nodes only} );
    },
    'ptv2.empty_role_unknown_pt' => sub {
        my $issues_string = gettext( q{PTv2 route: empty 'role'. Unknown value for 'public_transport' on object (='%s')} );
        return sprintf $issues_string, @_;
    },
    'ptv2.end_not_near_last' => sub {
        my $issues_string = gettext( 'PTv2 route: the end of the route on the last way (%s) is not near the last platform stop (%s).' );
        $issues_string .= ' ' . gettext( 'Distance = %d metres / %d feet.' );
        return sprintf $issues_string, @_;
    },
    'ptv2.first_node_exit_only' => sub {
        return gettext( q{PTv2 route: first node of way has 'role' = 'stop_exit_only'. Is the route sorted in reverse order?} );
    },
    'ptv2.first_node_not_first_stop' => sub {
        my $issues_string = gettext( 'PTv2 route: first node of way is not the first stop position of this route: %s versus %s' );
        return sprintf $issues_string, @_;
    },
    'ptv2.first_node_not_stop' => sub {
        my $issues_string = gettext( 'PTv2 route: first node of way is not a stop position of this route: %s' );
        return sprintf $issues_string, @_;
    },
    'ptv2.first_node_oneway_exit_only' => sub {
        return gettext( q{PTv2 route: first node of oneway way has 'role' = 'stop_exit_only'} );
    },
    'ptv2.first_oneway_no_exit' => sub {
        return gettext( q{PTv2 route: first way is a oneway road and ends in a 'stop_position' of this route and there is no exit. Is the route sorted in reverse order?} );
    },
    'ptv2.first_stop_not_first' => sub {
        my $issues_string = gettext( 'PTv2 route: first stop position on first way is not the first stop position of this route: %s versus %s' );
        return sprintf $issues_string, @_;
    },
    'ptv2.gap_in_route' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( 'PTv2 route: consists of %d segments, has a gap. Gap appears at way', 'PTv2 route: consists of %d segments, has gaps. Gaps appear at ways', $count );
        return sprintf $issues_string, @args;
    },
    'ptv2.last_node_entry_only' => sub {
        return gettext( q{PTv2 route: last node of way has 'role' = 'stop_entry_only'. Is the route sorted in reverse order?} );
    },
    'ptv2.last_node_not_last_stop' => sub {
        my $issues_string = gettext( 'PTv2 route: last node of way is not the last stop position of this route: %s versus %s' );
        return sprintf $issues_string, @_;
    },
    'ptv2.last_node_not_stop' => sub {
        my $issues_string = gettext( 'PTv2 route: last node of way is not a stop position of this route: %s' );
        return sprintf $issues_string, @_;
    },
    'ptv2.last_node_oneway_entry_only' => sub {
        return gettext( q{PTv2 route: last node of oneway way has 'role' = 'stop_entry_only'} );
    },
    'ptv2.last_stop_not_last' => sub {
        my $issues_string = gettext( 'PTv2 route: last stop position on last way is not the last stop position of this route: %s versus %s' );
        return sprintf $issues_string, @_;
    },
    'ptv2.missing_yes_on_pt' => sub {
        my $issues_string = gettext( q{PTv2 route: missing '%s' = 'yes' on 'public_transport' = '%s'} );
        return sprintf $issues_string, @_;
    },
    'ptv2.motorway_link_no_motorway' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( 'PTv2 route: using motorway_link way without entering a motorway way', 'PTv2 route: using motorway_link ways without entering a motorway way', $count );
        return sprintf $issues_string, @args;
    },
    'ptv2.no_stop_no_platform' => sub {
        return gettext( q{PTv2 route: there is no 'public_transport' = 'stop_position' (Node) and no 'public_transport' = 'platform' (Node, Way, Area or Relation)} );
    },
    'ptv2.no_stop_on_first_way' => sub {
        my $issues_string = gettext( 'PTv2 route: there is no stop position of this route on the first way: %s' );
        return sprintf $issues_string, @_;
    },
    'ptv2.no_stop_on_last_way' => sub {
        my $issues_string = gettext( 'PTv2 route: there is no stop position of this route on the last way: %s' );
        return sprintf $issues_string, @_;
    },
    'ptv2.one_platform' => sub {
        return gettext( q{PTv2 route: there is only one 'public_transport' = 'platform' (Node, Way, Area or Relation)} );
    },
    'ptv2.one_stop' => sub {
        return gettext( q{PTv2 route: there is only one 'public_transport' = 'stop_position' (Node)} );
    },
    'ptv2.oneway_wrong_direction' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( 'PTv2 route: using oneway way in wrong direction', 'PTv2 route: using oneway ways in wrong direction', $count );
        return sprintf $issues_string, @args;
    },
    'ptv2.platform_part_of_way' => sub {
        return gettext( q{PTv2 route: 'public_transport' = 'platform' is part of way} );
    },
    'ptv2.role_pt_mismatch' => sub {
        my $issues_string = gettext( q{PTv2 route: mismatch between 'role' = '%s' and 'public_transport' = '%s'} );
        return sprintf $issues_string, @_;
    },
    'ptv2.role_pt_unset' => sub {
        my $issues_string = gettext( q{PTv2 route: 'role' = '%s' but 'public_transport' is not set} );
        return sprintf $issues_string, @_;
    },
    'ptv2.role_pt_unset_but_set' => sub {
        my $issues_string = gettext( q{PTv2 route: 'role' = '%s' and 'public_transport' is not set but '%s' is set} );
        return sprintf $issues_string, @_;
    },
    'ptv2.role_suggest_platform' => sub {
        my $issues_string = gettext( q{PTv2 route: 'role' = '%s' and %s: consider setting 'public_transport' = 'platform'} );
        return sprintf $issues_string, @_;
    },
    'ptv2.role_suggest_stop' => sub {
        my $issues_string = gettext( q{PTv2 route: 'role' = '%s' and %s: consider setting 'public_transport' = 'stop_position'} );
        return sprintf $issues_string, @_;
    },
    'ptv2.roundabout_twice' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( 'PTv2 route: roundabout appears twice, following itself', 'PTv2 route: roundabouts appear twice, following themselves', $count );
        return sprintf $issues_string, @args;
    },
    'ptv2.roundtrip_not_same_stops' => sub {
        my $issues_string = gettext( q{PTv2 route: 'roundtrip' = '%s' but the first and the last platform stops are not the same.} );
        $issues_string .= ' ' . gettext( q{Consider setting 'roundtrip' = '%s'} ) . '%s.';
        return sprintf $issues_string, @_;
    },
    'ptv2.roundtrip_same_stops' => sub {
        my $issues_string = gettext( q{PTv2 route: 'roundtrip' = '%s' and the first and the last platform stops are the same.} );
        $issues_string .= ' ' . gettext( q{Consider setting 'roundtrip' = '%s'} ) . '%s.';
        return sprintf $issues_string, @_;
    },
    'ptv2.roundtrip_yes_far' => sub {
        my $issues_string = gettext( q{PTv2 route: 'roundtrip' = 'yes' but the first and the last platform stops are more than %d metres / %d feet apart (actual distance = %d metres / %d feet).} );
        $issues_string .= ' ' . gettext( q{Consider setting 'roundtrip' = '%s'} ) . '%s.';
        return sprintf $issues_string, @_;
    },
    'ptv2.start_not_near_first' => sub {
        my $issues_string = gettext( 'PTv2 route: the beginning of the route on the first way (%s) is not near the first platform stop (%s).' );
        $issues_string .= ' ' . gettext( 'Distance = %d metres / %d feet.' );
        return sprintf $issues_string, @_;
    },
    'ptv2.stop_not_part_of_way' => sub {
        return gettext( q{PTv2 route: 'public_transport' = 'stop_position' is not part of way} );
    },
    'ptv2.tag_undefined_for_route' => sub {
        my $issues_string = gettext( q{The tag 'public_transport' (='%s') is not defined for 'route_master' and 'route' relations. Do you mean 'public_transport:version'='2'} );
        $issues_string .= '%s?';
        return sprintf $issues_string, @_;
    },
    'ptv2.version_invalid' => sub {
        my ( $relation_inject_data ) = @_;
        return gettext( q{'public_transport:version' is neither '1' nor '2'} ) . $relation_inject_data;
    },
    'ptv2.version_not_2' => sub {
        my ( $relation_inject_data ) = @_;
        return gettext( q{'public_transport:version' is not set to '2'} ) . $relation_inject_data;
    },
    'ptv2.way_after_last_stop' => sub {
        my $issues_string = gettext( 'PTv2 route: consider removing the last way of the route from the relation, it is a way after the last stop position: %s' );
        return sprintf $issues_string, @_;
    },
    'ptv2.way_before_first_stop' => sub {
        my $issues_string = gettext( 'PTv2 route: consider removing the first way of the route from the relation, it is a way before the first stop position: %s' );
        return sprintf $issues_string, @_;
    },
    'ptv2.way_into_roundabout' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( 'PTv2 route: way leads into/through roundabout/closed way %s', 'PTv2 route: ways lead into/through roundabout/closed way %s', $count );
        return sprintf $issues_string, @args;
    },
    'ptv2.wrong_order' => sub {
        return gettext( q{PTv2 route: incorrect order of 'stop_position', 'platform' and 'way' (stop/platform after way)} );
    },
    'ptv2.wrong_role' => sub {
        my $issues_string = gettext( q{PTv2 route: wrong 'role' = '%s'} );
        return sprintf $issues_string, @_;
    },
    'ptv2.wrong_role_first_platform' => sub {
        my $issues_string = gettext( q{PTv2 route: wrong 'role' = '%s' for first platform} );
        return sprintf $issues_string, @_;
    },
    'ptv2.wrong_role_first_stop' => sub {
        my $issues_string = gettext( q{PTv2 route: wrong 'role' = '%s' for first stop} );
        return sprintf $issues_string, @_;
    },
    'ptv2.wrong_role_last_platform' => sub {
        my $issues_string = gettext( q{PTv2 route: wrong 'role' = '%s' for last platform} );
        return sprintf $issues_string, @_;
    },
    'ptv2.wrong_role_last_stop' => sub {
        my $issues_string = gettext( q{PTv2 route: wrong 'role' = '%s' for last stop} );
        return sprintf $issues_string, @_;
    },
    'ptv2.wrong_way_type' => sub {
        my ( $reason, @args ) = @_;
        my $detail = '';
        if ( $reason eq 'wrong_value' ) {
            $detail = sprintf q{%s: '%s' = '%s'}, gettext( 'wrong value' ), @args;
        } elsif ( $reason eq 'missing_key' ) {
            $detail = sprintf q{%s: '%s'}, gettext( 'missing key' ), join( ' ' . gettext( 'or' ) . ' ', @args );
        }
        my $issues_string = gettext( 'PTv2 route: using wrong way type (%s)' );
        return sprintf $issues_string, $detail;
    },
    'ref.not_set' => sub {
        return gettext( q{'ref' is not set} );
    },
    'rel.type_not_route' => sub {
        my $issues_string = gettext( q{'type' = '%s' is not 'route': %s} );
        return sprintf $issues_string, @_;
    },
    'rel.type_not_set' => sub {
        my $issues_string = gettext( q{'type' tag is not set: %s} );
        return sprintf $issues_string, @_;
    },
    'route.bus_stop_on_way' => sub {
        my ( $count, @args ) = @_;
        my $issues_string = ngettext( q{Route: 'highway' = 'bus_stop' is set on way. Allowed on nodes only!}, q{Route: 'highway' = 'bus_stop' is set on ways. Allowed on nodes only!}, $count );
        return sprintf $issues_string, @args;
    },
    'route.has_relations' => sub {
        return gettext( 'Route with Relation(s)' );
    },
    'route.in_multiple_masters' => sub {
        my ( @route_masters ) = @_;
        my $issues_string = gettext( 'This Route is direct member of more than one Route-Master: %s' );
        return sprintf $issues_string, join ', ', @route_masters;
    },
    'route.multiple_no_master' => sub {
        return gettext( 'Multiple Routes but no Route-Master' );
    },
    'route.multiple_no_ptv2' => sub {
        my ( $relation_inject_data ) = @_;
        return gettext( q{Multiple Routes but 'public_transport:version' is not set to '2'} ) . $relation_inject_data;
    },
    'route.multiple_not_in_master' => sub {
        return gettext( 'Multiple Routes but this Route is not a member of any Route-Master' );
    },
    'route.network_differs_master' => sub {
        my $issues_string = gettext( q{Route has different 'network' = '%s' than Route-Master 'network' = '%s': %s} );
        return sprintf $issues_string, @_;
    },
    'route.no_master' => sub {
        return gettext( 'This Route is not a member of any Route-Master' );
    },
    'route.no_ref_in_data' => sub {
        my $issues_string = gettext( q{Route exists in the given data set but 'ref' tag is not set: %s} );
        return sprintf $issues_string, @_;
    },
    'route.no_stops' => sub {
        return gettext( 'Route without Stops(Nodes)' );
    },
    'route.no_ways' => sub {
        return gettext( 'Route without Way(s)' );
    },
    'route.not_in_data' => sub {
        my $issues_string = gettext( 'Route does not exist in the given data set: %s' );
        return sprintf $issues_string, @_;
    },
    'route.not_in_master' => sub {
        my $issues_string = gettext( 'Route is not member of Route-Master: %s' );
        return sprintf $issues_string, @_;
    },
    'route.one_stop' => sub {
        return gettext( 'Route with only 1 Stop(Node)' );
    },
    'route.one_way' => sub {
        return gettext( 'Route with only 1 Way' );
    },
    'route.operator_differs_master' => sub {
        my $issues_string = gettext( q{Route has different 'operator' = '%s' than Route-Master 'operator' = '%s': %s} );
        return sprintf $issues_string, @_;
    },
    'route.other_section_ref' => sub {
        my $issues_string = gettext( q{Route might be listed with 'ref' = '%s' in a different section or in section 'Not clearly assigned routes' of this analysis: %s} );
        return sprintf $issues_string, @_;
    },
    'route.ref_mismatch' => sub {
        my $issues_string = gettext( q{Route has not matching 'ref' = '%s': %s} );
        return sprintf $issues_string, @_;
    },
    'route.tag_not_set' => sub {
        my $issues_string = gettext( q{'route' tag is not set: %s} );
        return sprintf $issues_string, @_;
    },
    'route.type_differs_master' => sub {
        my $issues_string = gettext( q{Route has different 'route' = '%s' than Route-Master 'route_master' = '%s': %s} );
        return sprintf $issues_string, @_;
    },
    'route.type_not_fit_master' => sub {
        my $issues_string = gettext( q{'route' = '%s' of Route does not fit to 'route_master' = '%s' of Route-Master: %s} );
        return sprintf $issues_string, @_;
    },
    'route.value_irrelevant' => sub {
        my $issues_string = gettext( q{Route has 'route' = '%s' value which is considered as not relevant: %s} );
        return sprintf $issues_string, @_;
    },
    'stop_ref.lacks_route_ref' => sub {
        my ( $route_ref, $ref, $hint ) = @_;
        my $issues_string = gettext( q{Route: 'route_ref' = '%s' of stop does not include 'ref' = '%s' value of this route} );
        $issues_string .= '%s';
        my $hint_string = $hint ? ' (' . gettext( q{separate multiple values by ';' (semi-colon) without blank} ) . ')' : '';
        return sprintf $issues_string, $route_ref, $ref, $hint_string;
    },
    'tag.differs_from_master' => sub {
        my $issues_string = gettext( q{'%s' = '%s' of Route does not fit to '%s' = '%s' of Route-Master: %s} );
        return sprintf $issues_string, @_;
    },
    'tag.empty_value' => sub {
        my $issues_string = gettext( q{The tag '%s' has an empty value.} );
        return sprintf $issues_string, @_;
    },
    'tag.identical_to_other_route' => sub {
        my $issues_string = gettext( q{'%s' = '%s' of Route is identical to '%s' of other Route(s)} );
        return sprintf $issues_string, @_;
    },
    'tag.matches_other_route' => sub {
        my $issues_string = gettext( q{'%s' = '%s' of Route has a match with '%s' = '%s' of other Route(s)} );
        return sprintf $issues_string, @_;
    },
    'tag.not_set_but_on_master' => sub {
        my $issues_string = gettext( q{'%s' of Route is not set but '%s' = '%s' of Route-Master is set: %s} );
        return sprintf $issues_string, @_;
    },
    'tag.set_but_not_on_master' => sub {
        my $issues_string = gettext( q{'%s' = '%s' of Route is set but '%s' of Route-Master is not set: %s} );
        return sprintf $issues_string, @_;
    },
);


#############################################################################################
#
# accessors: the codename of the issue and the list of its further arguments
#
#############################################################################################

sub codename {
    my $self = shift;

    return $self->{'codename'};
}

sub args {
    my $self = shift;

    return @{$self->{'args'}};
}


#############################################################################################
#
# list_items( \@items [, $remaining] ): the message is followed by the list of the affected objects,
# $remaining is the number of further objects which are not listed. Returns the issue itself.
#
#############################################################################################

sub list_items {
    my ( $self, $items, $remaining ) = @_;

    $self->{'items'}     = $items;
    $self->{'remaining'} = $remaining;

    return $self;
}


#############################################################################################
#
# key(): a string which identifies the message by its codename and arguments (without translating it),
# so that equal messages can be grouped, e.g. as hash key
#
#############################################################################################

sub key {
    my $self = shift;

    return join "\x1f", $self->{'codename'}, map { _key_of( $_ ) } @{$self->{'args'}};
}

sub _key_of {
    my $value = shift;

    if ( ref $value eq 'ARRAY' ) {
        return '[' . join( "\x1e", map { _key_of( $_ ) } @{$value} ) . ']';
    }
    return defined $value ? "$value" : '';
}


#############################################################################################
#
# returns the translated, human readable message for the issue, built from its codename and
# further arguments, or an empty return (plus a message on STDERR) for an unknown codename
#
#############################################################################################

sub to_string {
    my $self = shift;

    my $handler = $TO_STRING{$self->{'codename'}};
    if ( $handler ) {
        my $issues_string = $handler->( $self->args() );
        if ( $self->{'items'} ) {
            my $items_string = join ', ', @{$self->{'items'}};
            if ( $self->{'remaining'} ) {
                my $more_string = gettext( '%s: %s and %d more ...' );
                return sprintf $more_string, $issues_string, $items_string, $self->{'remaining'};
            }
            return sprintf '%s: %s', $issues_string, $items_string;
        }
        return $issues_string;
    }

    printf {*STDERR} "Unknown issue codename %s\n", $self->{'codename'};
    return;
}


#############################################################################################
#
# overwrite Locale::gettext::gettext() and ngettext() by our own functions which simply decode the retrieved data
#
#############################################################################################

sub gettext {
    return decode( 'utf8', Locale::gettext::gettext( @_ ) );
}

sub ngettext {
    return decode( 'utf8', Locale::gettext::ngettext( @_ ) );
}

1;

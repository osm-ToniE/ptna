package Ptna::Note;

use strict;
use warnings;

use Locale::gettext qw();       # 'gettext()' and 'ngettext()' are overwritten in this file, so don't import them
use Encode;


#############################################################################################
#
# constructor: returns a blessed hash reference which stores the 'codename' of the note as string
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
# dispatch table: note codename => sub which takes the further arguments of the note
# (see args()) and returns the translated, human readable message for that note
#
#############################################################################################

my %TO_STRING = (
    'date.not_iso8601' => sub {
        my $notes_string = gettext( q{The value of '%s' (= '%s') should be specified in ISO 8601 format: YYYY-MM-DD} );
        return sprintf $notes_string, @_;
    },
    'network.irrelevant_value' => sub {
        my $notes_string = gettext( q{Route has 'network' = '%s' value which is considered as not relevant: %s} );
        return sprintf $notes_string, @_;
    },
    'network.long_form_set' => sub {
        return gettext( q{'network:long' is long form} );
    },
    'network.matches_long_form' => sub {
        return gettext( q{'network:long' matches long form} );
    },
    'network.part_of_master' => sub {
        my $notes_string = gettext( q{'network' = '%s' of Route is a part of 'network' = '%s' of Route-Master: %s} );
        return sprintf $notes_string, @_;
    },
    'network.part_of_master_value' => sub {
        my $notes_string = gettext( q{Route has 'network' = '%s' value which is part of 'network' = '%s' of Route-Master: %s} );
        return sprintf $notes_string, @_;
    },
    'network.should_be_long' => sub {
        my $notes_string = gettext( q{'network' = '%s' should be long form} );
        return sprintf $notes_string, @_;
    },
    'network.should_be_short' => sub {
        my $notes_string = gettext( q{'network' = '%s' should be short form} );
        return sprintf $notes_string, @_;
    },
    'note.network_equal' => sub {
        my ( $value ) = @_;
        return sprintf q{'network' = '%s'}, $value;
    },
    'note.network_long_equal' => sub {
        my ( $value ) = @_;
        return sprintf q{'network:long' = '%s'}, $value;
    },
    'note.network_similar' => sub {
        my ( $value ) = @_;
        return sprintf q{'network' ~ '%s'}, $value;
    },
    'note.tag_url' => sub {
        my ( $tag, $value ) = @_;
        return sprintf q{'%s' ~ '%s'}, $tag, $value;
    },
    'note.tag_value' => sub {
        my ( $tag, $value ) = @_;
        return sprintf q{'%s' = '%s'}, $tag, $value;
    },
    'ptv2.from_differs_platform' => sub {
        my $notes_string = gettext( q{PTv2 route: 'from' = '%s' is not equal to 'name' of first platform: %s} );
        return sprintf $notes_string, @_;
    },
    'ptv2.from_mismatch_platform' => sub {
        my $notes_string = gettext( q{PTv2 route: 'from' = '%s' does not match 'name' of first platform: %s} );
        return sprintf $notes_string, @_;
    },
    'ptv2.from_not_set' => sub {
        return gettext( q{PTv2 route: 'from' is not set} );
    },
    'ptv2.name_deprecated_arrow' => sub {
        return gettext( q{PTv2 route: 'name' includes deprecated '==&gt;'} );
    },
    'ptv2.name_deprecated_bidir_arrow' => sub {
        return gettext( q{PTv2 route: 'name' includes deprecated '&lt;=&gt;'} );
    },
    'ptv2.name_form_required' => sub {
        return gettext( q{PTv2 route: 'name' should (at least) be of the form '... ref ...: from => to'} );
    },
    'ptv2.name_form_similar' => sub {
        return gettext( q{PTv2 route: 'name' should be similar to the form '... ref ...: from => to'} );
    },
    'ptv2.name_from_differs' => sub {
        my $notes_string = gettext( q{PTv2 route: from-part ('%s') of 'name' is not equal to 'from' = '%s'} );
        return sprintf $notes_string, @_;
    },
    'ptv2.name_from_mismatch' => sub {
        my $notes_string = gettext( q{PTv2 route: from-part ('%s') of 'name' does not match 'from' = '%s'} );
        return sprintf $notes_string, @_;
    },
    'ptv2.name_identical_other' => sub {
        return gettext( q{PTv2 route: 'name' of Route is identical to 'name' of other Route(s), consider setting an appropriate 'via' value and include that into 'name'} );
    },
    'ptv2.name_lacks_value' => sub {
        my $notes_string = gettext( q{PTv2 route: '%s' is not part of 'name' (derived from '%s' = '%s')} );
        return sprintf $notes_string, @_;
    },
    'ptv2.name_multi_arrow_no_via' => sub {
        return gettext( q{PTv2 route: 'name' has more than one '=>' but 'via' is not set} );
    },
    'ptv2.name_no_via_but_via_set' => sub {
        return gettext( q{PTv2 route: 'name' has no via-parts but 'via' is set} );
    },
    'ptv2.name_to_differs' => sub {
        my $notes_string = gettext( q{PTv2 route: to-part ('%s') of 'name' is not equal to 'to' = '%s'} );
        return sprintf $notes_string, @_;
    },
    'ptv2.name_to_mismatch' => sub {
        my $notes_string = gettext( q{PTv2 route: to-part ('%s') of 'name' does not match 'to' = '%s'} );
        return sprintf $notes_string, @_;
    },
    'ptv2.no_platform' => sub {
        return gettext( q{PTv2 route: there is no 'public_transport' = 'platform' (Node, Way, Area or Relation)} );
    },
    'ptv2.no_stop' => sub {
        return gettext( q{PTv2 route: there is no 'public_transport' = 'stop_position' (Node)} );
    },
    'ptv2.ref_not_in_name' => sub {
        return gettext( q{PTv2 route: 'ref' is not part of 'name'} );
    },
    'ptv2.roundabout_partial' => sub {
        my ( $count ) = @_;
        my $notes_string = ngettext( q{PTv2 route: includes %d entire roundabout but uses only segments}, q{PTv2 route: includes %d entire roundabouts but uses only segments}, $count );
        return sprintf $notes_string, $count;
    },
    'ptv2.roundtrip_unset_same_stops' => sub {
        my $notes_string  = gettext( q{PTv2 route: 'roundtrip' is not set and the first and the last platform stops are the same.} );
        $notes_string    .= ' ' . gettext( q{Consider setting 'roundtrip' = '%s'} ) . '%s.';
        return sprintf $notes_string, @_;
    },
    'ptv2.roundtrip_yes_near' => sub {
        my $notes_string  = gettext( q{PTv2 route: 'roundtrip' = 'yes' and the first and the last platform stops are less than %d metres / %d feet apart (actual distance = %d metres / %d feet).} );
        $notes_string    .= ' ' . gettext( q{This is considered acceptable.} );
        return sprintf $notes_string, @_;
    },
    'ptv2.to_differs_platform' => sub {
        my $notes_string = gettext( q{PTv2 route: 'to' = '%s' is not equal to 'name' of last platform: %s} );
        return sprintf $notes_string, @_;
    },
    'ptv2.to_mismatch_platform' => sub {
        my $notes_string = gettext( q{PTv2 route: 'to' = '%s' does not match 'name' of last platform: %s} );
        return sprintf $notes_string, @_;
    },
    'ptv2.to_not_set' => sub {
        return gettext( q{PTv2 route: 'to' is not set} );
    },
    'ptv2.via_few_platforms' => sub {
        my $notes_string = gettext( q{PTv2 route: 'via' is set, but there are less than 3 platforms (=%d).} );
        return sprintf $notes_string, @_;
    },
    'ptv2.via_few_platforms_n' => sub {
        my $notes_string = gettext( q{PTv2 route: 'via' is set (%d parts), but there are less than %d platforms (=%d).} );
        return sprintf $notes_string, @_;
    },
    'ptv2.via_name_fewer' => sub {
        my $notes_string = gettext( q{PTv2 route: there are less via-parts in 'name' (%d) than in 'via' (%d)} );
        return sprintf $notes_string, @_;
    },
    'ptv2.via_name_more' => sub {
        my $notes_string = gettext( q{PTv2 route: there are more via-parts in 'name' (%d) than in 'via' (%d)} );
        return sprintf $notes_string, @_;
    },
    'ptv2.via_part_differs' => sub {
        my $notes_string = gettext( q{PTv2 route: 'via' is set: %d. via-part ('%s') of 'name' is not equal to %d. via-value = '%s'} );
        return sprintf $notes_string, @_;
    },
    'ptv2.via_part_mismatch' => sub {
        my $notes_string = gettext( q{PTv2 route: 'via' is set: %d. via-part ('%s') of 'name' does not match %d. via-value = '%s'} );
        return sprintf $notes_string, @_;
    },
    'ptv2.via_part_multi_platform' => sub {
        my $notes_string = gettext( q{PTv2 route: 'via' is set. %d. via-part ('%s') matches name of more than one platform (platform numbers: %s)} );
        return sprintf $notes_string, @_;
    },
    'ptv2.via_part_no_platform' => sub {
        my $notes_string = gettext( q{PTv2 route: 'via' is set. %d. via-part ('%s') does not match any platform name.} );
        return sprintf $notes_string, @_;
    },
    'route.see_conditional' => sub {
        return sprintf q{%s <a href="#conditional_on_ways">%s</a>}, gettext( q{Route: see} ), gettext( q{Conditional access statements found on ways} );
    },
    'route.suspicious_construction' => sub {
        my ( $count, @args ) = @_;
        my $notes_string = ngettext( q{Route: suspicious %s along with 'highway' unequal to 'construction' on way}, q{Route: suspicious %s along with 'highway' unequal to 'construction' on ways}, $count );
        return sprintf $notes_string, @args;
    },
    'route.way_type' => sub {
        my ( $reason, @args ) = @_;
        my $detail = '';
        if ( $reason eq 'suspicious_sub_type' ) {
            $detail = sprintf q{%s: 'service'='%s'}, gettext( 'suspicious sub-type' ), @args;
        }
        my $notes_string = gettext( q{Route: using way type (%s)} );
        return sprintf $notes_string, $detail;
    },
    'stop_ref.comma_separator' => sub {
        my $notes_string = gettext( q{Route: 'route_ref' = '%s' of stop: ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank} );
        return sprintf $notes_string, @_;
    },
    'stop_ref.delete' => sub {
        my $notes_string = gettext( q{Route: '%s' = '%s' of stop should be deleted, 'route_ref' = '%s' exists} );
        return sprintf $notes_string, @_;
    },
    'stop_ref.replace' => sub {
        my $notes_string = gettext( q{Route: '%s' = '%s' of stop should be replaced by 'route_ref' = '%s'} );
        return sprintf $notes_string, @_;
    },
    'stop_ref.represents_stop_add' => sub {
        my ( $ref, $sub_ref ) = @_;
        my $hint         = sprintf gettext( q{(consider adding '%s' to the 'route_ref' tag of the stop)} ), $sub_ref;
        my $notes_string = gettext( q{Route: 'ref' = '%s' of stop should represent the reference of the stop, but includes the 'ref' = '%s' of this route %s} );
        return sprintf $notes_string, $ref, $sub_ref, $hint;
    },
    'stop_ref.represents_stop_create' => sub {
        my ( $ref, $sub_ref ) = @_;
        my $hint         = sprintf gettext( q{(consider creating a 'route_ref' = '%s' tag for the stop)} ), $sub_ref;
        my $notes_string = gettext( q{Route: 'ref' = '%s' of stop should represent the reference of the stop, but includes the 'ref' = '%s' of this route %s} );
        return sprintf $notes_string, $ref, $sub_ref, $hint;
    },
    'tag.comma_separator' => sub {
        my $notes_string = gettext( q{'%s' = '%s': ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank} );
        return sprintf $notes_string, @_;
    },
    'tag.line_reserved' => sub {
        my $notes_string = gettext( q{The tag 'line' (='%s') is reserved for 'power' = 'line' related tagging. For public transport 'route_master' and 'route' are used.} );
        return sprintf $notes_string, @_;
    },
    'tag.missing_alternatives' => sub {
        my $notes_string = gettext( q{'%s' = '%s' is set but neither '%s' nor '%s' is set: consider setting one of them as they provide additional information about stops (their names, sequence and locations).} );
        return sprintf $notes_string, @_;
    },
    'tag.problematic_char_key' => sub {
        my $notes_string = gettext( q{The tag '%s' includes potentially problematic character '%s' in key. Value of tag: '%s'} );
        return sprintf $notes_string, @_;
    },
    'tag.whitespace_in_key' => sub {
        my $notes_string = gettext( q{The tag '%s' includes whitespace character '%s' (=%#2x) in key. Value of tag: '%s'} );
        return sprintf $notes_string, @_;
    },
);


#############################################################################################
#
# accessors: the codename of the note and the list of its further arguments
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
# $remaining is the number of further objects which are not listed. Returns the note itself.
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
# returns the translated, human readable message for the note, built from its codename and
# further arguments, or an empty return (plus a message on STDERR) for an unknown codename
#
#############################################################################################

sub to_string {
    my $self = shift;

    my $handler = $TO_STRING{$self->{'codename'}};
    if ( $handler ) {
        my $notes_string = $handler->( $self->args() );
        if ( $self->{'items'} ) {
            my $items_string = join ', ', @{$self->{'items'}};
            if ( $self->{'remaining'} ) {
                my $more_string = gettext( '%s: %s and %d more ...' );
                return sprintf $more_string, $notes_string, $items_string, $self->{'remaining'};
            }
            return sprintf '%s: %s', $notes_string, $items_string;
        }
        return $notes_string;
    }

    printf {*STDERR} "Unknown note codename %s\n", $self->{'codename'};
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

package PtnaStrings;

use strict;

use POSIX;
use Locale::gettext qw();       # 'gettext()' will be overwritten in this file (at the end), so don't import from module into our name space

use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Encode;

use Exporter;
use base qw (Exporter);

our @EXPORT_OK  = qw( InitMessageStrings InitOptionStrings GetMessageKeys GetMessageValue GetOptionKeys GetOptionValue %MessageHash @MessageList %OptionHash @OptionList );


my %MessageHash = ();
my @MessageList = ();
my %OptionHash =  ();
my @OptionList =  ();


#############################################################################################
#
#
#
#############################################################################################

sub InitMessageStrings {

    my $i = 0;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'%s' = '%s' includes the separator value ';' (semi-colon) with sourrounding blank" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'colour' has unknown value '%s'. Add '#' as first character." );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'colour' has unknown value '%s'. Choose one of the 140 well defined HTML/CSS colour names or the HTML Hex colour codes '#...' or '#......'." );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'colour' of Route is not set but 'colour' of Route-Master is set: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'colour' of Route is set but 'colour' of Route-Master is not set: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'gtfs:shape_id' = '%s' is set but neither 'gtfs:trip_id' nor 'gtfs:trip_id:sample' is set: consider setting one of them as they provide additional information about stops (their names, sequence and locations)." );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-gtfs";
    $MessageList[$i]->{'description'}            = gettext( "GTFS shape data provides (only) information about the itinerary of the vehicle." ) . ' ' .
                                                   gettext( "In addition, GTFS trip data provides useful information about stops: their names, their sequences and their locations." ) . ' ' .
                                                   gettext( "This additional information can be used to compare OSM data with GTFS data." );
    $MessageList[$i]->{'fix'}                    = gettext( "Add either 'gtfs:trip_id' or 'gtfs:trip_id:sample' information." );
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'name' is not set" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network' = '%s' of Route does not fit to 'network' = '%s' of Route-Master: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network' = '%s' should be long form" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network' = '%s' should be short form" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'%s' = '%s': ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network' is not set" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network:long' is long form" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network:long' matches long form" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'operator' = '%s' of Route does not fit to 'operator' = '%s' of Route-Master: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'public_transport:version' is neither '1' nor '2'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'public_transport:version' is not set" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'public_transport:version' is not set to '2'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'ref' is not set" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'route' = '%s' of Route does not fit to 'route_master' = '%s' of Route-Master: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'route' tag is not set: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'type' = '%s' is not 'route': %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'type' tag is not set: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Error in input data: insufficient data for nodes" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "This Route relation has been included into the input data as a side-effect, the member ways and member nodes of this Route have not been included." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Error in input data: insufficient data for ways" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "This Route relation has been included into the input data as a side-effect, the member ways and member nodes of this Route have not been included." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Missing route for ref='%s' and route='%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "This route is expected as '%s' ('bus', 'tram', ...) according to CSV data, but does not exist in the given data set (see also section: \"Overpass API Query\")." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Multiple Routes but 'public_transport:version' is not set to '2'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Multiple Routes but no Route-Master" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Multiple Routes but this Route is not a member of any Route-Master" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: '%s' is not part of 'name' (derived from '%s' = '%s')" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'from' is not set" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'name' has no via-parts but 'via' is set" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'name' has more than one '=>' but 'via' is not set" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'name' includes deprecated '&lt;=&gt;'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'name' includes deprecated '==&gt;'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'name' of Route is identical to 'name' of other Route(s), consider setting an appropriate 'via' value and include that into 'name'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'name' should (at least) be of the form '... ref ...: from => to'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'name' should be similar to the form '... ref ...: from => to'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name-relaxed";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'public_transport' = 'platform' is part of way" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'public_transport' = 'stop_position' is not part of way" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'ref' is not part of 'name'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'role' = '%s' and %s: consider setting 'public_transport' = 'platform'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "ptv1-compatibility=show";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'role' = '%s' and %s: consider setting 'public_transport' = 'stop_position'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "ptv1-compatibility=show";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'role' = '%s' but 'public_transport' is not set" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'to' is not set" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'via' is set: %d. via-part ('%s') of 'name' is not equal to %d. via-value = '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'via' is set: %d. via-part ('%s') of 'name' is not part of %d. via-value = '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name-relaxed";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: consider removing the first way of the route from the relation, it is a way before the first stop position: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: consider removing the last way of the route from the relation, it is a way after the last stop position: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: empty 'role'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first node of oneway way has 'role' = 'stop_exit_only'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first node of way has 'role' = 'stop_exit_only'. Is the route sorted in reverse order?" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first node of way is not a stop position of this route: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first node of way is not the first stop position of this route: %s versus %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first stop position on first way is not the first stop position of this route: %s versus %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first way is a oneway road and ends in a 'stop_position' of this route and there is no exit. Is the route sorted in reverse order?" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: from-part ('%s') of 'name' is not equal to 'from' = '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: from-part ('%s') of 'name' is not part of 'from' = '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name-relaxed";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "PTv2 route: has a gap, consists of %d segments. Gap appears at way", "PTv2 route: has gaps, consists of %d segments. Gaps appear at ways", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "message-has_gaps.png";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "PTv2 route: includes %d entire roundabout but uses only segments", "PTv2 route: includes %d entire roundabouts but uses only segments", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-sequence\ncheck-roundabout";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: incorrect order of 'stop_position', 'platform' and 'way' (stop/platform after way)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "message-incorrect_order_of_stop_platform_and_way.png";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: last node of oneway way has 'role' = 'stop_entry_only'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: last node of way has 'role' = 'stop_entry_only'. Is the route sorted in reverse order?" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: last node of way is not a stop position of this route: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: last node of way is not the last stop position of this route: %s versus %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: last stop position on last way is not the last stop position of this route: %s versus %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: mismatch between 'role' = '%s' and 'public_transport' = '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "PTv2 route: roundabout appears twice, following itself", "PTv2 route: roundabouts appear twice, following themselves", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "message-roundabout_appears_twice.png";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there are less via-parts in 'name' (%d) than in 'via' (%d)" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there are more via-parts in 'name' (%d) than in 'via' (%d)" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there are no 'public_transport' = 'stop_position' and no 'public_transport' = 'platform'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there is no 'public_transport' = 'platform'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there is no 'public_transport' = 'stop_position'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there is no stop position of this route on the first way: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there is no stop position of this route on the last way: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there is only one 'public_transport' = 'platform'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there is only one 'public_transport' = 'stop_position'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: to-part ('%s') of 'name' is not equal to 'to' = '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: to-part ('%s') of 'name' is not part of 'to' = '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-name-relaxed";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "PTv2 route: using motorway_link way without entering a motorway way", "PTv2 route: using motorway_link ways without entering a motorway way", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-motorway-link";
    $MessageList[$i]->{'description'}            = gettext( "The vehicle uses a motorway entrance or exit without using a motorway/trunk road immediately after or before it." ) . ' ' .
                                                   gettext( "This may indicate incorrect tagging of the 'highway' = 'motorway_link'." ) . ' ' .
                                                   gettext( "But it can also point to a wrong route, e.g. if it was created automatically by a routing SW." ) . ' ' .
                                                   gettext( "There still seems to be Routing-SW that prefers to use a short stretch of highway enrance to turn around after 20 m and route back to the previous route instead of taking the direct route (because a traffic light influences the result?)." ) . ' ' .
                                                   "\n" .
                                                   gettext( "Precondition: the route is without gap(s)." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "PTv2 route: using oneway way in wrong direction", "PTv2 route: using oneway ways in wrong direction", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-sequence";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "message-using_oneway_way_in_wrong_direction.png";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: using wrong way type (%s)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: wrong 'role' = '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route does not exist in the given data set: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route exists in the given data set but 'ref' tag is not set: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "The Route is member of this Route-Master, but has no 'ref' tag (%s = ID of the route)." );
    $MessageList[$i]->{'fix'}                    = gettext( "See section: \"Public Transport Lines without 'ref'\" of the analysis." );
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has 'network' = '%s' value which is considered as not relevant: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has 'operator' = '%s' value which is considered as not relevant: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has 'route' = '%s' value which is considered as not relevant: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has different 'network' = '%s' than Route-Master 'network' = '%s': %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network' = '%s' of Route is a part of 'network' = '%s' of Route-Master: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has 'network' = '%s' value which is part of 'network' = '%s' of Route-Master: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has different 'operator' = '%s' than Route-Master 'operator' = '%s': %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has different 'ref' = '%s' than Route-Master 'ref' = '%s' - this should be avoided: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "This is currently deactivated." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has different 'route' = '%s' than Route-Master 'route_master' = '%s': %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has not matching 'ref' = '%s': %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route is not member of Route-Master: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route might be listed with 'ref' = '%s' in a different section or in section 'Not clearly assigned routes' of this analysis: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route with Relation(s)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route with only 1 Node" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route with only 1 Way" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route without Node(s)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route without Way(s)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master exists in the given data set but 'ref' tag is not set: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route-Master has less Routes than actually match (%d versus %d) in the given data set", "Route-Masters have less Routes than actually match (%d versus %d) in the given data set", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "This Route-Master has less route relations than listed here (Route(s) not listed in the Route-Master?)." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route-Master has more Routes than actually match (%d versus %d) in the given data set", "Route-Masters have more Routes than actually match (%d versus %d) in the given data set", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "This route master has more route relations than listed here (route without or with other 'ref'/'route'/'network' tag?)." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master has not matching 'ref' = '%s': %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master might be listed with 'ref' = '%s' in a different section or in section 'Not clearly assigned routes' of this analysis: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master might be listed with unknown 'ref' in section 'Public Transport Lines without 'ref'' of this analysis: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master with Node(s)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "The Route-Master relation contains stops or train/bus stops." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master with Relation(s) unequal to 'route'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "The Route-Master relation contains relation(s) that are not of type 'route'." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master with Way(s)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "The Route-Master relation contains streets/railways/trains/bus stops/..." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master without Route(s)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext ("The Route-Master relation does not contain a Route relation (should not happen with the used Overpass API query, see: 'The overpass API query does not return')." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route: '%s' = '%s' of stop should be deleted, 'route_ref' = '%s' exists" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-route-ref";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route: '%s' = '%s' of stop should be replaced by 'route_ref' = '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-route-ref";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route: 'highway' = 'bus_stop' is set on way. Allowed on nodes only!", "Route: 'highway' = 'bus_stop' is set on ways. Allowed on nodes only!", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-bus-stop";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route: 'ref' = '%s' of stop should represent the reference of the stop, but includes the 'ref' = '%s' of this route %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-route-ref";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route: 'route_ref' = '%s' of stop does not include 'ref' = '%s' value of this route%s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-route-ref";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route: 'route_ref' = '%s' of stop includes the separator value ';' (semi-colon) with sourrounding blank" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-route-ref";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route: 'route_ref' = '%s' of stop: ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-route-ref";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route: restricted access (%s) to way without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", "Route: restricted access (%s) to ways without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-access";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route: restricted access at barrier (%s) without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", "Route: restricted access at barriers (%s) without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-access";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route: suspicious %s along with 'highway' unequal to 'construction' on way", "Route: suspicious %s along with 'highway' unequal to 'construction' on ways", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-access";
    $MessageList[$i]->{'description'}            = gettext( "The key 'construction' is set and the key 'highway' is not set to 'construction'." ) . " " .
                                                   gettext( "Construction works on ways are usually mapped as the combination of 'higway' = 'construction' and 'construction' = 'xxx', where 'xxx' is the former value of the 'highway' key." ) . " " .
                                                   gettext( "When the construction works are finished, the key 'highway' is set to its former or a different value while the key 'construction' gets delete." ) . " " .
                                                   gettext( "Sometimes, deleting the key 'construction' is not carried out, which leaves an artifact and can be seen as an error." ) . " " .
                                                   "\n" .
                                                   gettext( "Example" ) . ": 'construction' = 'primary' " .
                                                   gettext( "and" ) . " 'highway' = 'primary' " .
                                                   gettext( "instead of" ) . " 'highway' = 'construction'.";
    $MessageList[$i]->{'fix'}                    = gettext( "Check whether the construction works are finished or not." ) . " " .
                                                   gettext( "If yes, delete the key 'construction'." ) . " " .
                                                   gettext( "If no, check for an appropriate value of the key 'highway'." );
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route: unclear access (%s) to way", "Route: unclear access (%s) to ways", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-access";
    $MessageList[$i]->{'description'}            = gettext( "A conditional access is mapped to a way. PTNA will not analyze the value of the tag." ) . "\n" .
                                                   gettext( "Example" ) . ": 'psv:conditional' = 'yes @ (Mo-Fr 05:00-22:00)'.";
    $MessageList[$i]->{'fix'}                    = gettext( "Please evaluate the value manually and decide whether a fix is needed or not." );
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route: incorrect access restriction (%s) to way. Consider tagging as '%s'='no' and '%s'='yes'", "Route: incorrect access restriction (%s) to ways. Consider tagging as '%s'='no' and '%s'='yes'", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-access";
    $MessageList[$i]->{'description'}            = gettext( "The access restriction does not comply with the map features." );
    $MessageList[$i]->{'fix'}                    = gettext( "Please consult the OSM Wiki: https://wiki.openstreetmap.org/wiki/Map_Features#Restrictions" );
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Skipping further analysis ..." );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "This error is related to:" ) . " '" .
                                                   gettext( "Error in input data: insufficient data for nodes" ) . "' " .
                                                   gettext( "and" ) . " '" .
                                                   gettext( "Error in input data: insufficient data for ways" ) . "'. " .
                                                   gettext( "Further analysis of this Route relation does not make sense without the data for ways and nodes." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "The tag 'line' (='%s') is reserved for 'power' = 'line' related tagging. For public transport 'route_master' and 'route' are used." );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "There is more than one Route-Master" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "Route-Master: There is more than one Route-Master for this line = 'ref' (different 'network'-tags?)." ) . "\n" .
                                                   gettext( "Route: There is more than one Route Master for this line = 'ref' plus the parent Route Master of this route." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "This Route is direct member of more than one Route-Master: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "This Route has more than one parent Route-Master (%s = list of Route-Masters)." );
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "This Route is not a member of any Route-Master" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Type is not set. Line %s of Routes-Data. Contents of line: '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Type is not supported: '%s'. Line %s of Routes-Data. Contents of line: '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'%s' = '%s' of Route does not fit to '%s' = '%s' of Route-Master: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'%s' = '%s' of Route has a match with '%s' = '%s' of other Route(s)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'%s' = '%s' of Route is identical to '%s' of other Route(s)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'%s' = '%s' of Route is set but '%s' of Route-Master is not set: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'%s' of Route is not set but '%s' = '%s' of Route-Master is set: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: missing '%s' = 'yes' on 'public_transport' = '%s'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;
    return 0;
}


sub GetMessageKeys {
    return keys %MessageHash;
}


sub GetMessageValue {
    my $key     = shift;
    my $string  = shift;

    return $MessageList[$MessageHash{$key}]->{$string}    if ( $key && defined $MessageHash{$key} && $string && exists $MessageList[$MessageHash{$key}]->{$string} );
    return undef;
}


sub InitOptionStrings {

    my $i = 0;

    $i++;
    $OptionList[$i]->{'option'}                 = "language";
    $OptionList[$i]->{'default'}                = "en";
    $OptionList[$i]->{'description'}            = gettext( "Defines the language for the output." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "allow-coach";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Allow 'route_master' = 'coach' und 'route' = 'coach' (although they are inofficial)." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-access";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Ways are used which cannot be used explicitly or implicitly ('construction', 'access', ...) and where 'bus' = 'yes', 'bus' = 'designated', 'bus' = 'official', 'psv' =' yes', ... is not set." ) . ' ' .
                                                  gettext( "This applies to 'barrier' = '...' as well." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-bus-stop";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "'highway' = 'bus_stop' can be set on nodes only, not on ways or areas." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-gtfs";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Check 'gtfs:*' tags for validity, ..." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-motorway-link";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Check whether motorway links are used without actually using a motorway/trunk road." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-name";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Check of 'name' = '...ref: from => to' respectively 'name' ='...ref: from => via => ... => to'." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-name-relaxed";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "More relaxed check of 'name' ='...: A => B', where 'A' must be part of 'from' and 'B' must be part of 'to'." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-osm-separator";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Check the value of 'network', ... whether the separator is actually the semicolon ';' (w/o Blanks)." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-roundabouts";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Check whether roundabouts are used partially (segments only) or completely (while not being segmented)." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-route-ref";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Check whether the tag 'route_ref' on the stops of a route includes the value of 'ref' of the route (provided 'route_ref' exists)." ) . "\n" .
                                                  gettext( "Check also whether the tag 'ref' on the stops of a route accidentially includes the value of 'ref' of the route." ) . "\n" .
                                                  gettext( "Check also for tags 'bus_lines', 'bus_routes', 'lines', 'routes' on the stops of a route. Those should be replaced by the tag 'route_ref'." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-sequence";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Check sequence of ways, are there any gaps?" );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-version";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Check of 'public_transport:version' = '...' on Route-Master and Route." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "check-way-type";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Check whether the used way types are appropriate for the vehicle type ('train' using 'railway' = 'rail', 'tram' using 'railway' = 'tram', 'bus' using 'highway' = '...', ...)." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "coloured-sketchline";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "SketchLine considers the value of 'colour' = '...' of Route-Master or Route." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-long";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "The value of 'network' = '...' is expected in long form (see: network-long-regex)." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-long-as";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = gettext( "The value of 'network' = '...' is expected in long form, as shown here." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-long-for";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = gettext( "The value of 'network' = '...' is expected in long form instead of the short form shown here." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-short";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "The value of 'network' = '...' is expected in short form (see: network-short-regex)." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-short-as";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = gettext( "The value of 'network' = '...' is expected in short form, as shown here." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-short-for";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = gettext( "The value of 'network' = '...' is expected in short form instead of the long form shown here." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "gtfs-feed";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = gettext( "Take this value as GTFS feed for option 'link-gtfs' if the relation does not provide the tags 'gtfs:feed', 'operator:guid' or 'network:guid'." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "link-gtfs";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Provide links to GTFS-Analysis for 'gtfs:route_id' or 'gtfs:trip_id' tags." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "max-error";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = gettext( "Limits the number of identical error and note messages for a relation." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "multiple-ref-type-entries";
    $OptionList[$i]->{'default'}                = "analyze";
    $OptionList[$i]->{'description'}            = "allow|analyze|no" . "\n" .
                                                  gettext( "Defines how to react if the combination of \"ref;type\" (e.g. \"N8;bus\") appears more than once in the route data. PTNA expects that there are separate routes with identical 'ref' and 'type' in different cities/villages and that those can be distinguished by also checking 'operator', 'to' and 'from'." ) . "\n" .
                                                  "allow: "   . gettext( "allow further occurances of this entry" ) . ', ' . gettext( "do not analyze 'operator', 'from' and 'to'" ) . "\n" .
                                                  "analyze: " . gettext( "find out whether 'operator', 'from' and 'to' of the CSV data match the tags of the relation" ) . "\n" .
                                                  "no: "      . gettext( "ignore any further occurances of this entry" ) . ', ' . gettext( "do not analyze 'operator', 'from' and 'to'" ) . '.';
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "network-long-regex";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = gettext( "The value of 'network' = '...' of the Route-Master and Route relations must match this regular expression as 'long' form or can be empty (unset)." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "network-short-regex";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = gettext( "The value of 'network' = '...' of the Route-Master and Route relations must match this regular expression as 'short' form or can be empty (unset)." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "no-additional-navigation";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "operator-regex";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = gettext( "The value of 'operator' = '...' of the Route-Master and Route relations must match this regular expression or can be empty (unset)." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "positive-notes";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Also show 'network:short' = '...', 'network:guid' = '...' and other tags and values." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "ptv1-compatibility";
    $OptionList[$i]->{'default'}                = "no";
    $OptionList[$i]->{'description'}            = "allow|no|show" . "\n" .
                                                  gettext( "'highway' = 'bus_stop' on a point beside the road is treated as 'public_transport' = 'platform' if 'role' = 'platform'." ) . "\n" .
                                                  "allow: " . gettext( "silently assume compatibility with legacy bus-stops (aka: PTv1)" ) . "\n" .
                                                  "no: "    . gettext( "no compatibility with legacy bus-stops (aka: PTv1)" ) . "\n" .
                                                  "show: "  . gettext( "assume and show compatibility with legacy bus-stops (aka: PTv1)" ) . '.';
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "relaxed-begin-end-for";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = gettext( "Relaxed check of begin and end of routes regarding stop positions (i.e. for 'train', 'tram', 'light_rail')." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "show-gtfs";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Similar to option '--positive-notes': show values of 'gtfs*' tags in the 'Notes' column." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "strict-network";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Do not consider Route-Master and Route relations with empty 'network'." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "strict-operator";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = gettext( "Do not consider Route-Master and Route relations with empty 'operator'." );
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "separator";
    $OptionList[$i]->{'default'}                = ";";
    $OptionList[$i]->{'description'}            = "";
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "or-separator";
    $OptionList[$i]->{'default'}                = "|";
    $OptionList[$i]->{'description'}            = "";
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "ref-separator";
    $OptionList[$i]->{'default'}                = "/";
    $OptionList[$i]->{'description'}            = "";
    $OptionList[$i]->{'image'}                  = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    return 0;
}


sub GetOptionKeys {
    return keys %OptionHash;
}


sub GetOptionValue {
    my $key     = shift;
    my $string  = shift;

    return $OptionList[$OptionHash{$key}]->{$string}    if ( $key && defined $OptionHash{$key} && $string && exists $OptionList[$OptionHash{$key}]->{$string} );
    return undef;
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



1;

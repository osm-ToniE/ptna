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
    $MessageList[$i]->{'message'}                = gettext( "'colour' has unknown value '%s'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'colour' of Route does not fit to 'colour' of Route-Master: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'colour' of Route is not set but 'colour' of Route-Master is set: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'colour' of Route is set but 'colour' of Route-Master is not set: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'name' is not set" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network' = '%s' includes the separator value ';' (semi-colon) with sourrounding blank" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network' = '%s' of Route does not fit to 'network' = '%s' of Route-Master: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network' = '%s': ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network' is not set" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'operator' = '%s' of Route does not fit to 'operator' = '%s' of Route-Master: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'public_transport:version' is neither '1' nor '2'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'public_transport:version' is not set to '2'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'ref' is not set" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'route' = '%s' of Route does not fit to 'route_master' = '%s' of Route-Master: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'route' tag is not set: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'type' = '%s' is not 'route': %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'type' tag is not set: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Error in input data: insufficient data for nodes" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Error in input data: insufficient data for ways" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Multiple Routes but 'public_transport:version' is not set to '2'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Multiple Routes but no Route-Master" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Multiple Routes but this Route is not a member of any Route-Master" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'public_transport' = 'platform' is part of way" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'public_transport' = 'stop_position' is not part of way" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'role' = '%s' and %s: consider setting 'public_transport' = 'platform'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'role' = '%s' and %s: consider setting 'public_transport' = 'stop_position'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: 'role' = '%s' but 'public_transport' is not set" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: consider removing the first way of the route from the relation, it is a way before the first stop position: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: consider removing the last way of the route from the relation, it is a way after the last stop position: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: empty 'role'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first node of oneway way has 'role' = 'stop_exit_only'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first node of way has 'role' = 'stop_exit_only'. Is the route sorted in reverse order?" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first node of way is not a stop position of this route: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first node of way is not the first stop position of this route: %s versus %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first stop position on first way is not the first stop position of this route: %s versus %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: first way is a oneway road and ends in a 'stop_position' of this route and there is no exit. Is the route sorted in reverse order?" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "PTv2 route: has a gap, consists of %d segments. Gap appears at way", "PTv2 route: has gaps, consists of %d segments. Gaps appear at ways", 1 );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "PTv2 route: includes %d entire roundabout but uses only segments", "PTv2 route: includes %d entire roundabouts but uses only segments", 1 );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: incorrect order of 'stop_position', 'platform' and 'way' (stop/platform after way)" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: last node of oneway way has 'role' = 'stop_entry_only'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: last node of way has 'role' = 'stop_entry_only'. Is the route sorted in reverse order?" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: last node of way is not a stop position of this route: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: last node of way is not the last stop position of this route: %s versus %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: last stop position on last way is not the last stop position of this route: %s versus %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: mismatch between 'role' = '%s' and 'public_transport' = '%s'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: missing '%s' = 'yes' on 'public_transport' = 'stop_position'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "PTv2 route: roundabout appears twice, following itself", "PTv2 route: roundabouts appear twice, following themselves", 1 );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there are no 'public_transport' = 'stop_position' and no 'public_transport' = 'platform'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there is no stop position of this route on the first way: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there is no stop position of this route on the last way: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there is only one 'public_transport' = 'platform'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: there is only one 'public_transport' = 'stop_position'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "PTv2 route: using motorway_link way without entering a motorway way", "PTv2 route: using motorway_link ways without entering a motorway way", 1 );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "PTv2 route: using oneway way in wrong direction", "PTv2 route: using oneway ways in wrong direction", 1 );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: wrong 'role' = '%s'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route does not exist in the given data set: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route exists in the given data set but 'ref' tag is not set: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has 'network' = '%s' value which is considered as not relevant: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has 'operator' = '%s' value which is considered as not relevant: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has 'route' = '%s' value which is considered as not relevant: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has different 'network' = '%s' than Route-Master 'network' = '%s': %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has different 'operator' = '%s' than Route-Master 'operator' = '%s': %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has different 'ref' = '%s' than Route-Master 'ref' = '%s' - this should be avoided: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has different 'route' = '%s' than Route-Master 'route_master' = '%s': %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has not matching 'ref' = '%s': %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route is not member of Route-Master: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route might be listed with 'ref' = '%s' in a different section or in section 'Not clearly assigned routes' of this analysis: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route with Relation(s)" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route with only 1 Node" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route with only 1 Way" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route without Node(s)" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route without Way(s)" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route-Master has less Routes than actually match (%d versus %d) in the given data set", "Route-Masters have less Routes than actually match (%d versus %d) in the given data set", 1 );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route-Master has more Routes than actually match (%d versus %d) in the given data set", "Route-Masters have more Routes than actually match (%d versus %d) in the given data set", 1 );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master has not matching 'ref' = '%s': %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master might be listed with 'ref' = '%s' in a different section or in section 'Not clearly assigned routes' of this analysis: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master might be listed with unknown 'ref' in section 'Public Transport Lines without 'ref'' of this analysis: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master with Node(s)" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master with Relation(s) unequal to 'route'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master with Way(s)" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master without Route(s)" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Type is not set. Line %s of Routes-Data. Contents of line: '%s'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Type is not supported: '%s'. Line %s of Routes-Data. Contents of line: '%s'" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route: 'highway' = 'bus_stop' is set on way. Allowed on nodes only!", "Route: 'highway' = 'bus_stop' is set on ways. Allowed on nodes only!", 1 );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route: 'route_ref' = '%s' of stop does not include 'ref' = '%s' value of this route%s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route: 'route_ref' = '%s' of stop includes the separator value ';' (semi-colon) with sourrounding blank" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route: 'route_ref' = '%s' of stop: ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route: restricted access (%s) to way without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", "Route: restricted access (%s) to ways without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", 1 );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route: restricted access at barrier (%s) without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", "Route: restricted access at barriers (%s) without 'psv'='yes', '%s'='yes', '%s'='designated', or ...", 1 );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route: unclear access (%s) to way", "Route: unclear access (%s) to ways", 1 );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Skipping further analysis ..." );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "There is more than one Route-Master" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "This Route is direct member of more than one Route-Master: %s" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "This Route is not a member of any Route-Master" );
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
    $OptionList[$i]->{'option'}                 = "--check-name";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "--check-name-relaxed";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
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

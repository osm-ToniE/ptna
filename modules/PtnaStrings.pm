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
    $MessageList[$i]->{'message'}                = gettext( "'colour' of Route does not fit to 'colour' of Route-Master: %s" );
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
    $MessageList[$i]->{'message'}                = gettext( "'name' is not set" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "'network' = '%s' includes the separator value ';' (semi-colon) with sourrounding blank" );
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
    $MessageList[$i]->{'message'}                = gettext( "'network' = '%s': ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
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
    $MessageList[$i]->{'description'}            = "";
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
    $MessageList[$i]->{'option'}                 = "check-sequence --check-roundabout";
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
    $MessageList[$i]->{'message'}                = gettext( "PTv2 route: missing '%s' = 'yes' on 'public_transport' = 'stop_position'" );
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
    $MessageList[$i]->{'option'}                 = "--check-name";
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
    $MessageList[$i]->{'description'}            = "";
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
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route has 'network' = '%s' value which is considered as not relevant: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
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
    $MessageList[$i]->{'description'}            = "";
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
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route-Master has more Routes than actually match (%d versus %d) in the given data set", "Route-Masters have more Routes than actually match (%d versus %d) in the given data set", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
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
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master with Relation(s) unequal to 'route'" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master with Way(s)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route-Master without Route(s)" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route: '%s' = '%s' of stop should be deleted, 'route_ref' = '%s' exists" );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "--check-route-ref";
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
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "check-route-ref";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Route: 'route_ref' = '%s' of stop: ',' (comma) as separator value should be replaced by ';' (semi-colon) without blank" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
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
                                                   gettext( "Construction works on ways are usually mapped as the combination of 'higway'='construction' and 'construction'='xxx', where 'xxx' is the former value of the 'highway' key." ) . " " .
                                                   gettext( "When the construction works are finished, the key 'highway' is set to its former or a different value while the key 'construction' gets delete." ) . " " .
                                                   gettext( "Sometimes, deleting the key 'construction' is not carried out, which leaves an artifact and can be seen as an error." ) . " " .
                                                   gettext( "Example" ) . ": 'construction'='primary' " . 
                                                   gettext( "and" ) . " 'highway'='primary' " . 
                                                   gettext( "instead of" ) . " 'highway'='construction'.";
    $MessageList[$i]->{'fix'}                    = gettext( "Check whether the construction works are finished or not." ) . " " .
                                                   gettext( "If yes, delete the key 'construction'." ) . " " .
                                                   gettext( "If no, check for an appropriate value of the key 'highway'." );
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = ngettext( "Route: unclear access (%s) to way", "Route: unclear access (%s) to ways", 1 );
    $MessageList[$i]->{'type'}                   = gettext( "Notes" );
    $MessageList[$i]->{'option'}                 = "check-access";
    $MessageList[$i]->{'description'}            = gettext( "A conditional access is mapped to a way. PTNA will not analyze the value of the tag." ) . " " .
                                                   gettext( "Example" ) . ": 'psv:conditional=yes @ (Mo-Fr 05:00-22:00)'.";
    $MessageList[$i]->{'fix'}                    = gettext( "Please evaluate the value manually and decide whether a fix is needed or not." );
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "Skipping further analysis ..." );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = gettext( "This error is related to:" ) . " \"" . 
                                                   gettext( "Error in input data: insufficient data for nodes" ) . "\" " . 
                                                   gettext( "and" ) . " \"" . 
                                                   gettext( "Error in input data: insufficient data for ways" ) . "\". " .
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
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;

    $i++;
    $MessageList[$i]->{'message'}                = gettext( "This Route is direct member of more than one Route-Master: %s" );
    $MessageList[$i]->{'type'}                   = gettext( "Errors" );
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
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
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "allow-coach";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-access";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-bus-stop";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-motorway-link";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-name";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-name-relaxed";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-osm-separator";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-platform";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-soundabouts";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-route-ref";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-sequence";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-stop-position";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "check-version";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "coloured-sketchline";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-long";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-long-as";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-long-for";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-short";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-short-as";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "expect-network-short-for";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "max-error";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "multiperef-type-entries";
    $OptionList[$i]->{'default'}                = "analyze";
    $OptionList[$i]->{'description'}            = "allow|analyze|no";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "network-long-regex";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "network-short-regex";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "operator-regex";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "positive-notes";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "ptv1-compatibility";
    $OptionList[$i]->{'default'}                = "allow|no|show";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "relaxed-begin-end-for";
    $OptionList[$i]->{'default'}                = "";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "strict-network";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "strict-operator";
    $OptionList[$i]->{'default'}                = "en";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "separator";
    $OptionList[$i]->{'default'}                = ";";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "or-separator";
    $OptionList[$i]->{'default'}                = "|";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;

    $i++;
    $OptionList[$i]->{'option'}                 = "ref-separator";
    $OptionList[$i]->{'default'}                = "/";
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


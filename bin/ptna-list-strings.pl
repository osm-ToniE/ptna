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

use Locale::gettext qw();

use Encode;                                                

use Getopt::Long;
use PtnaStrings     qw( InitMessageStrings InitOptionStrings GetMessageKeys GetMessageValue GetOptionKeys GetOptionValue );


my $opt_language                    = undef;
my $opt_what                        = 'messages';
my $opt_type                        = '';
my $verbose                         = undef;
my $debug                           = undef;


GetOptions( 'language=s'                    =>  \$opt_language,                 # --language=de                     I18N
            'verbose'                       =>  \$verbose,                      # --verbose
            'debug'                         =>  \$debug,                        # --debug
            'what=s'                        =>  \$opt_what,                     # --what=messages || -what=options
            'type=s'                        =>  \$opt_type,                     # none || --type=html ||--type=wiki
          );

if ( $verbose ) {
    printf STDERR "ptna-list-strings.pl -v";
    printf STDERR " --language='%s'", $opt_language  if ( $opt_language );
    printf STDERR " --what=%s",       $opt_what      if ( $opt_what     );
    printf STDERR " --type=%s",       $opt_type      if ( $opt_type     );
    printf STDERR "\n";
}


if ( $opt_language ) {
    my $PATH = $0;
    $PATH =~ s|bin/[^/]*$|locale|;
    $ENV{'LANGUAGE'} = $opt_language;
    Locale::gettext::setlocale( LC_MESSAGES, '' );
    Locale::gettext::bindtextdomain( 'ptna', $PATH );
    Locale::gettext::textdomain( "ptna" );
}


if ( $opt_what eq 'messages' ) {

    InitMessageStrings();

    if ( $opt_type eq 'html') {
        ListMessageStringsDetailsHtml();
    } else {
        ListMessageStrings();
    }
} elsif ( $opt_what eq 'options' ) {

    InitOptionStrings();

    if ( $opt_type eq 'html' ) {
        ListOptionStringsDetailsHtml();
    } elsif ( $opt_type eq 'wiki' ) {
        ListOptionStringsDetailsWiki();
    } else {
        ListOptionStrings();
    }
}


#############################################################################################
#
#
#
#############################################################################################

sub ListMessageStrings {

    foreach my $key ( sort ( GetMessageKeys() ) ) {
        printf STDOUT "%s\n", GetMessageValue( $key, 'message' );
    }
    return;
}


#############################################################################################
#
#
#
#############################################################################################

sub ListMessageStringsDetailsHtml {

    my $key     = undef;
    my $descr   = undef;
    my $replace = gettext( "Example" );
    my $opt     = undef;

    printf STDOUT "    <table id=\"message-table\">\n";
    printf STDOUT "        <thead>\n";
    printf STDOUT "            <tr class=\"message-tableheaderrow\">\n";
    printf STDOUT "                <th class=\"message-text\">%s</th>\n",        gettext( "Message" );
    printf STDOUT "                <th class=\"message-type\">%s</th>\n",        gettext( "Type" );
    printf STDOUT "                <th class=\"message-option\">%s</th>\n",      gettext( "Option" );
    printf STDOUT "                <th class=\"message-description\">%s</th>\n", gettext( "Description" );
    printf STDOUT "                <th class=\"message-fix\">%s</th>\n",         gettext( "How to fix" );
    printf STDOUT "                <th class=\"message-image\">%s</th>\n",       gettext( "Image" );
    printf STDOUT "            </tr>\n";
    printf STDOUT "        </thead>\n";
    printf STDOUT "        <tbody>\n";
    foreach $key ( sort ( GetMessageKeys() ) ) {
        $opt   = GetMessageValue( $key, 'option' );
        $opt   =~ s| --|<br />--|g;
        $descr = GetMessageValue( $key, 'description' );
        $descr =~ s| \Q$replace\E|<br />\Q$replace\E|g;
        printf STDOUT "            <tr class=\"message-tablerow\">\n";
        printf STDOUT "                <td class=\"message-text\">%s</td>\n",        GetMessageValue( $key, 'message' );
        printf STDOUT "                <td class=\"message-type\">%s</td>\n",        GetMessageValue( $key, 'type' );
        printf STDOUT "                <td class=\"message-option\">%s</td>\n",      $opt;
        printf STDOUT "                <td class=\"message-description\">%s</td>\n", $descr;
        printf STDOUT "                <td class=\"message-fix\">%s</td>\n",         GetMessageValue( $key, 'fix' );
        printf STDOUT "                <td class=\"message-image\">%s</td>\n",       GetMessageValue( $key, 'image' );
        printf STDOUT "            </tr>\n";

    }
    printf STDOUT "        </tbody>\n";
    printf STDOUT "    </table>\n";
    return;
}


#############################################################################################
#
#
#
#############################################################################################

sub ListOptionStrings {

    foreach my $key ( sort ( GetOptionKeys() ) ) {
        printf STDOUT "%s\n", GetOptionValue( $key, 'option' );
    }
    return;
}


#############################################################################################
#
#
#
#############################################################################################

sub ListOptionStringsDetailsHtml {

    my $key = undef;

    printf STDOUT "    <table id=\"message-table\">\n";
    printf STDOUT "        <thead>\n";
    printf STDOUT "            <tr class=\"message-tableheaderrow\">\n";
    printf STDOUT "                <th class=\"message-option\">%s</th>\n",         gettext( "Option"        );
    printf STDOUT "                <th class=\"message-default\">%s</th>\n",        gettext( "Default Value" );
    printf STDOUT "                <th class=\"message-description\">%s</th>\n",    gettext( "Description"   );
    printf STDOUT "            </tr>\n";
    printf STDOUT "        </thead>\n";
    printf STDOUT "        <tbody>\n";
    foreach $key ( sort ( GetOptionKeys() ) ) {
        printf STDOUT "            <tr class=\"message-tablerow\">\n";
        printf STDOUT "                <td class=\"message-option\">%s</td>\n",      GetOptionValue( $key, 'option' );
        printf STDOUT "                <td class=\"message-default\">%s</td>\n",     GetOptionValue( $key, 'default' );
        printf STDOUT "                <td class=\"message-description\">%s</td>\n", GetOptionValue( $key, 'description' );
        printf STDOUT "            </tr>\n";

    }
    printf STDOUT "        </tbody>\n";
    printf STDOUT "    </table>\n";
    return;
}


#############################################################################################
#
#
#
#############################################################################################

sub ListOptionStringsDetailsWiki {

    my $key = undef;

    foreach $key ( sort ( GetOptionKeys() ) ) {
        printf STDOUT "|-\n";
        printf STDOUT "|- | %s ||", GetOptionValue( $key, 'option' );
        printf STDOUT " | %s ||",   GetOptionValue( $key, 'default' );
        printf STDOUT " | %s ||\n", GetOptionValue( $key, 'description' );

    }
    return;
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





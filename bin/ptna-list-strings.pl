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
my $opt_type                        = 'html';
my $verbose                         = undef;
my $debug                           = undef;


GetOptions( 'language=s'                    =>  \$opt_language,                 # --language=de                     I18N
            'verbose'                       =>  \$verbose,                      # --verbose
            'debug'                         =>  \$debug,                        # --debug
            'what=s'                        =>  \$opt_what,                     # --what=messages || --what=options
            'type=s'                        =>  \$opt_type,                     # --type=html ||--type=wiki || anything else
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
    my $replace = html_escape(gettext( "Example" ));
    my $msg     = undef;
    my $opt     = undef;
    my $img     = undef;

    printf STDOUT "\n";
    printf STDOUT "<!--\n";
    printf STDOUT "\n";
    printf STDOUT "    Do not edit this file with the '<table id=\"message-table\">', all changes will be lost\n";
    printf STDOUT "\n";
    printf STDOUT "    This file has been created by 'ptna-list-strings.pl' of the 'github.com' repository 'ptna' of 'osm-ToniE'\n";
    printf STDOUT "    The purpose of 'ptna-list-strings.pl' is to allow easy and automated translation of the contents of this file into other languages than English.\n";
    printf STDOUT "    Translations can be done at 'https://www.transifex.com/jungle-bus/ptna/dashboard/'\n";
    printf STDOUT "\n";
    printf STDOUT "-->\n";
    printf STDOUT "\n";
    printf STDOUT "    <table id=\"message-table\">\n";
    printf STDOUT "        <thead>\n";
    printf STDOUT "            <tr class=\"message-tableheaderrow\">\n";
    printf STDOUT "                <th class=\"message-text\">%s</th>\n",        gettext( "Message" );
    printf STDOUT "                <th class=\"message-type\">%s</th>\n",        gettext( "Type" );
    printf STDOUT "                <th class=\"message-option\">%s</th>\n",      gettext( "Option" );
    printf STDOUT "                <th class=\"message-description\">%s</th>\n", gettext( "Description" );
    printf STDOUT "                <th class=\"message-fix\">%s</th>\n",         gettext( "How to fix it" );
    printf STDOUT "                <th class=\"message-image\">%s</th>\n",       gettext( "Image" );
    printf STDOUT "            </tr>\n";
    printf STDOUT "        </thead>\n";
    printf STDOUT "        <tbody>\n";
    foreach $key ( sort ( GetMessageKeys() ) ) {
        $msg   =  html_escape( GetMessageValue( $key, 'message'     ) );
        $opt   =  html_escape( GetMessageValue( $key, 'option'      ) );
        $opt   =~ s| &#045;&#045;|<br />&#045;&#045;|g;
        $descr =  html_escape( GetMessageValue( $key, 'description' ) );
        $descr =~ s| \Q$replace\E|<br />\Q$replace\E|g;
        $img   =  GetMessageValue( $key, 'image' );
        printf STDOUT "            <tr class=\"message-tablerow\">\n";
        printf STDOUT "                <td class=\"message-text\">%s</td>\n",        $msg;
        printf STDOUT "                <td class=\"message-type\">%s</td>\n",        html_escape( GetMessageValue( $key, 'type' ) );
        printf STDOUT "                <td class=\"message-option\">%s</td>\n",      $opt;
        printf STDOUT "                <td class=\"message-description\">%s</td>\n", $descr;
        printf STDOUT "                <td class=\"message-fix\">%s</td>\n",         html_escape( GetMessageValue( $key, 'fix' ) );
        if ( $img ) {
            printf STDOUT "                <td class=\"message-image\">";
            printf STDOUT                      "<div class=\"message-tooltip\"><img src=\"/img/%s\" alt=\"%s\" /><span class=\"message-tooltiptext\">%s</span></div></td>\n", $img, $msg, $msg;
        } else {
            printf STDOUT "                <td class=\"message-image\"></td>\n";
        }
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

    my $key     = undef;
    my $opt     = undef;
    my $descr   = undef;
    my $replace = html_escape(gettext( "Example" ));
    my $img     = undef;

    printf STDOUT "\n";
    printf STDOUT "<!--\n";
    printf STDOUT "\n";
    printf STDOUT "    Do not edit this file with the '<table id=\"message-table\">', all changes will be lost\n";
    printf STDOUT "\n";
    printf STDOUT "    This file has been created by 'ptna-list-strings.pl' of the 'github.com' repository 'ptna' of 'osm-ToniE'\n";
    printf STDOUT "    The purpose of 'ptna-list-strings.pl' is to allow easy and automated translation of the contents of this file into other languages than English.\n";
    printf STDOUT "    Translations can be done at 'https://www.transifex.com/jungle-bus/ptna/dashboard/'\n";
    printf STDOUT "\n";
    printf STDOUT "-->\n";
    printf STDOUT "\n";
    printf STDOUT "    <table id=\"message-table\">\n";
    printf STDOUT "        <thead>\n";
    printf STDOUT "            <tr class=\"message-tableheaderrow\">\n";
    printf STDOUT "                <th class=\"message-option\">%s</th>\n",         gettext( "Option"        );
    printf STDOUT "                <th class=\"message-default\">%s</th>\n",        gettext( "Default Value" );
    printf STDOUT "                <th class=\"message-description\">%s</th>\n",    gettext( "Description"   );
    printf STDOUT "                <th class=\"message-image\">%s</th>\n",          gettext( "Image" );
    printf STDOUT "            </tr>\n";
    printf STDOUT "        </thead>\n";
    printf STDOUT "        <tbody>\n";
    foreach $key ( sort ( GetOptionKeys() ) ) {
        $opt   =  html_escape( GetOptionValue( $key, 'option'      ) );
        $descr =  html_escape( GetOptionValue( $key, 'description' ) );
        $descr =~ s| \Q$replace\E|<br />\Q$replace\E|g;
        $img   =  GetOptionValue( $key, 'image' );
        printf STDOUT "            <tr class=\"message-tablerow\" id=\"option-%s\">\n", $opt;
        printf STDOUT "                <td class=\"message-option\">%s</td>\n",       $opt;
        printf STDOUT "                <td class=\"message-default\">%s</td>\n",      html_escape( GetOptionValue( $key, 'default' ) );
        printf STDOUT "                <td class=\"message-description\">%s</td>\n",  $descr;
        if ( $img ) {
            printf STDOUT "                <td class=\"message-image\">";
            printf STDOUT                      "<div class=\"message-tooltip\"><img src=\"/img/%s\" alt=\"%s\" /><span class=\"message-tooltiptext\">%s</span></div></td>\n", $img, $opt, $opt;
        } else {
            printf STDOUT "                <td class=\"message-image\"></td>\n";
        }
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


#############################################################################################

sub html_escape {
    my $text = shift;
    if ( $text ) {
        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
        $text =~ s/>/&gt;/g;
        $text =~ s/"/&quot;/g;
        $text =~ s/'/&#039;/g;
        $text =~ s/--/&#045;&#045;/g;
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






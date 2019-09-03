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

use Getopt::Long;
use PtnaStrings     qw( InitMessageStrings InitOptionStrings GetMessageKeys GetMessageValue GetOptionKeys GetOptionValue %MessageHash @MessageList %OptionHash @OptionList );


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
    printf STDERR "ptna-list-strings.pl -v", get_time();
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
    } elsif ( $opt_what eq 'wiki' ) {
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

    foreach my $key ( GetMessageKeys() ) {
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

    my $key = undef;
    my $i   = undef;

    printf STDOUT "    <table id=\"message-table\">\n";
    printf STDOUT "        <thead>\n";
    printf STDOUT "            <tr class=\"message-tableheaderrow\">\n";
    #printf STDOUT "                <th class=\"message-text\">%s</th>\n",        gettext( "Message" );
    #printf STDOUT "                <th class=\"message-option\">%s</th>\n",      gettext( "Option" );
    #printf STDOUT "                <th class=\"message-description\">%s</th>\n", gettext( "Description" );
    #printf STDOUT "                <th class=\"message-fix\">%s</th>\n",         gettext( "How to fix" );
    #printf STDOUT "                <th class=\"message-image\">%s</th>\n",       gettext( "Image" );
    printf STDOUT "            </tr>\n";
    printf STDOUT "        </thead>\n";
    printf STDOUT "        <tbody>\n";
    foreach $key ( sort ( keys ( %MessageHash ) ) ) {
        $i = $MessageHash{$key};
        printf STDOUT "            <tr>\n";
        printf STDOUT "                <td class=\"message-text\">%s</td>\n",          $MessageList[$i]->{'message'};
        printf STDOUT "                <td class=\"message-option\">%s</td>\n",      ( $MessageList[$i]->{'option'}      ) ? $MessageList[$MessageHash{$key}]->{'option'}      : '&nbsp;';
        printf STDOUT "                <td class=\"message-description\">%s</td>\n", ( $MessageList[$i]->{'description'} ) ? $MessageList[$MessageHash{$key}]->{'description'} : '&nbsp;';
        #printf STDOUT "                <td class=\"message-fix\">%s</td>\n",         ( $MessageList[$i]->{'fix'}         ) ? $MessageList[$MessageHash{$key}]->{'fix'}         : '&nbsp;';
        #printf STDOUT "                <td class=\"message-image\">%s</td>\n",       ( $MessageList[$i]->{'image'}       ) ? $MessageList[$MessageHash{$key}]->{'image'}       : '&nbsp;';
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

    foreach my $key ( GetOptionKeys() ) {
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
    my $i   = undef;

    printf STDOUT "    <table id=\"message-table\">\n";
    printf STDOUT "        <thead>\n";
    printf STDOUT "            <tr class=\"message-tableheaderrow\">\n";
    printf STDOUT "                <th class=\"message-option\">%s</th>\n",         gettext( "Option"        );
    printf STDOUT "                <th class=\"message-default\">%s</th>\n",        gettext( "Default Value" );
    printf STDOUT "                <th class=\"message-description\">%s</th>\n",    gettext( "Description"   );
    printf STDOUT "            </tr>\n";
    printf STDOUT "        </thead>\n";
    printf STDOUT "        <tbody>\n";
    foreach $key ( sort ( keys ( %OptionHash ) ) ) {
        $i = $OptionHash{$key};
        printf STDOUT "            <tr>\n";
        printf STDOUT "                <td class=\"message-option\">%s</td>\n",      ( $OptionList[$i]->{'option'}      ) ? $OptionList[$OptionHash{$key}]->{'option'}      : '&nbsp;';
        printf STDOUT "                <td class=\"message-default\">%s</td>\n",     ( $OptionList[$i]->{'default'}     ) ? $OptionList[$OptionHash{$key}]->{'default'}     : '&nbsp;';
        printf STDOUT "                <td class=\"message-description\">%s</td>\n", ( $OptionList[$i]->{'description'} ) ? $OptionList[$OptionHash{$key}]->{'description'} : '&nbsp;';
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
    my $i   = undef;

    foreach $key ( sort ( keys ( %OptionHash ) ) ) {
        $i = $OptionHash{$key};
        printf STDOUT "|-\n";
        printf STDOUT "|- | %s ||", ( $OptionList[$i]->{'option'}      ) ? $OptionList[$OptionHash{$key}]->{'option'}      : '&nbsp;';
        printf STDOUT " | %s ||",   ( $OptionList[$i]->{'default'}     ) ? $OptionList[$OptionHash{$key}]->{'default'}     : '&nbsp;';
        printf STDOUT " | %s ||\n", ( $OptionList[$i]->{'description'} ) ? $OptionList[$OptionHash{$key}]->{'description'} : '&nbsp;';

    }
    return;
}


#############################################################################################

sub get_time {

    my ($sec,$min,$hour,$day,$month,$year) = localtime();

    return sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $month+1, $day, $hour, $min, $sec );
}



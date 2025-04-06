#!/usr/bin/perl

use warnings;
use strict;

use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";


use Getopt::Long;

use MediaWiki::API;

use Data::Dumper;

use Encode;


my $WIKI_URL    = 'https://wiki.openstreetmap.org/w/api.php';
my $PAGE        = "Sandbox";
my $TEXT        = "Wiki page contents\n";
my $SUMMARY     = "update via wiki-page.pl";

#############################################################################################
#
#############################################################################################

my $debug                           = undef;
my $help                            = undef;
my $man_page                        = undef;
my $verbose                         = undef;
my $file                            = undef;                    # --file=input_or_output_filename
my $page                            = $PAGE;                    # --page=Sandbox
my $parse                           = undef;                    # --parse
my $pull                            = undef;                    # --pull
my $push                            = undef;                    # --push
my $username                        = undef;                    # --username=user           - alternatively use    $ENV{'WIKI_USERNAME'} instead
my $password                        = undef;                    # --password=secret         - alternatively use    $ENV{'WIKI_PASSWORD'} instead
my $summary                         = $SUMMARY;                 # --summary="summary for the push"
my $watch                           = undef;
my $wiki_url                        = $WIKI_URL;                # --wiki-url=https://wiki.openstreetmap.org/w/api.php
my $text                            = $TEXT;

GetOptions( 'help'                          =>  \$help,                         # -h or --help                      help
            'man'                           =>  \$man_page,                     # --man                             manual pages
            'verbose'                       =>  \$verbose,                      # --verbose
            'debug'                         =>  \$debug,                        # --debug
            'file=s'                        =>  \$file,                         # --file=input_filename
            'page=s'                        =>  \$page,                         # --page=München/Transportation/Analyse
            'parse'                         =>  \$parse,                        # --parse
            'pull'                          =>  \$pull,                         # --pull
            'push'                          =>  \$push,                         # --push
            'username=s'                    =>  \$username,                     # --username=user               - alternatively use    $ENV{'WIKI_USERNAME'} instead
            'password=s'                    =>  \$password,                     # --password=secret             - alternatively use    $ENV{'WIKI_PASSWORD'} instead
            'summary=s'                     =>  \$summary ,                     # --summary="summary for the push"
            'watch'                         =>  \$watch,                        # --watch
            'wiki-url=s'                    =>  \$wiki_url,                     # --wiki-url=https://wiki.openstreetmap.org/w/api.php
          );

$page       = decode('utf8', $page    ) if ( $page    );
$summary    = decode('utf8', $summary ) if ( $summary );

if ( !$page ) {
    printf STDERR "Please specify the Wiki page to parse, pull, push or watch\n";
    printf STDERR "usage: wiki-page.pl [--parse|--pull|--push|--watch] --page=<wikipage> ...\n";
    exit 1;
}

my $commands = 0;

if ( $parse ) { $commands++; }
if ( $pull  ) { $commands++; }
if ( $push  ) { $commands++; }
if ( $watch ) { $commands++; }

if ( $commands > 1 ) {
    printf STDERR "Please specify either --parse or --pull or --push or --watch\n";
    printf STDERR "usage: wiki-page.pl [--parse|--pull|--push|--watch] --page=<wikipage> ...\n";
    exit 2;
} elsif ( $push ) {
    if ( $username || $ENV{'WIKI_USERNAME'} ) {
        if ( !$username ) {
            $username = $ENV{'WIKI_USERNAME'};
        }
    } else {
        printf STDERR "Username for Wiki not specified\n";
        printf STDERR "usage: wiki-page.pl --push --page=<wikipage> --file=<filename> --username=<user> --password=<passwd> --summary=<summary> ...\n";
        printf STDERR "or\n";
        printf STDERR "WIKI_USER=<user>\nWIKI_PASSWORD=<passwd>\nwiki-page.pl --push --page=<wikipage> --file=<filename> --summary=<summary> ...\n";
        exit 3;
    }
    if ( $password || $ENV{'WIKI_PASSWORD'} ) {
        if ( !$password ) {
            $password = $ENV{'WIKI_PASSWORD'};
        }
    } else {
        printf STDERR "Password for User '%s' for Wiki not specified\n", $username;
        printf STDERR "usage: wiki-page.pl --push --page=<wikipage> --file=<filename> --username=<user> --password=<passwd> --summary=<summary> ...\n";
        printf STDERR "or\n";
        printf STDERR "WIKI_USER=<user>\nWIKI_PASSWORD=<passwd>\nwiki-page.pl --push --page=<wikipage> --file=<filename> --summary=<summary> ...\n";
        exit 4;
    }
    if ( $file && -f $file && -r $file ) {
        ;
    } else {
        if ( $file ) {
            printf STDERR "File '%s' is not a file or is not readable\n", $file;
        } else {
            printf STDERR "Filename not specified\n";
        }
        printf STDERR "usage: wiki-page.pl --push --page=<wikipage> --file=<filename> --username=<user> --password=<passwd> --summary=<summary> ...\n";
        printf STDERR "or\n";
        printf STDERR "WIKI_USER=<user>\nWIKI_PASSWORD=<passwd>\nwiki-page.pl --push --page=<wikipage> --file=<filename> --summary=<summary> ...\n";
        exit 5;
    }

} elsif ( $parse || $pull ) {
    ;
} elsif ( $watch ) {
    if ( $username || $ENV{'WIKI_USERNAME'} ) {
        if ( !$username ) {
            $username = $ENV{'WIKI_USERNAME'};
        }
    } else {
        printf STDERR "Username for Wiki not specified\n";
        printf STDERR "usage: wiki-page.pl --watch --page=<wikipage> --file=<filename> --username=<user> --password=<passwd> --summary=<summary> ...\n";
        printf STDERR "or\n";
        printf STDERR "WIKI_USER=<user>\nWIKI_PASSWORD=<passwd>\nwiki-page.pl --watch --page=<wikipage> --file=<filename> --summary=<summary> ...\n";
        exit 6;
    }
    if ( $password || $ENV{'WIKI_PASSWORD'} ) {
        if ( !$password ) {
            $password = $ENV{'WIKI_PASSWORD'};
        }
    } else {
        printf STDERR "Password for User '%s' for Wiki not specified\n", $username;
        printf STDERR "usage: wiki-page.pl --watch --page=<wikipage> --file=<filename> --username=<user> --password=<passwd> --summary=<summary> ...\n";
        printf STDERR "or\n";
        printf STDERR "WIKI_USER=<user>\nWIKI_PASSWORD=<passwd>\nwiki-page.pl --watch --page=<wikipage> --file=<filename> --summary=<summary> ...\n";
        exit 7;
    }
} else {
    printf STDERR "Please specify either --parse or --pull or --push or --watch\n\n", $username;
    printf STDERR "usage: wiki-page.pl [--parse|--pull|--push|--watch] --page=<wikipage> ...\n";
    exit 8;
}

#############################################################################################
#
#############################################################################################

my $mw = undef;


if ( $parse ) {

    $mw = MediaWiki::API->new();

    $mw->{config}->{api_url}    = $wiki_url;
    $mw->{config}->{on_error}   = \&on_error;

    printf STDERR "%s Parsing Wiki page '%s'\n", get_time(), $page;

    my $ref = $mw->api( { action => 'parse', page => $page } );

    if ( $ref && $ref->{'parse'} ) {
        printf STDERR "%s ref = %s\n",  get_time(), Dumper($ref)     if ( $verbose );
        if ( $ref->{'parse'}->{'text'} && $ref->{'parse'}->{'text'}->{'*'} ) {
            printf STDERR "%s timestamp = %s\n", get_time(), get_timestamp();
            if ( $file ) {
                if ( open(OUT,">$file") ) {
                    printf STDERR "%s writing parsed Wiki page '%s' to file '%s'\n", get_time(), $page, $file;
                    binmode OUT, ":utf8";
                    printf OUT "%s", $ref->{'parse'}->{'text'}->{'*'};
                    close( OUT );
                    printf STDERR "%s Done ... parsing Wiki page '%s' to file '%s'\n", get_time(), $page, $file;
                } else {
                    printf STDERR "%s Can't open file '%s' for writing parsed Wiki page\n", get_time(), $file;
                    exit 10;
                }
            } else {
                printf STDERR "%s writing parsed Wiki page '%s' to STDOUT\n", get_time(), $page;
                printf "%s", $ref->{'parse'}->{'text'}->{'*'};
                printf STDERR "%s Done ... writing parsed Wiki page '%s' to STDOUT\n", get_time(), $page;
            }
        } else {
            printf STDERR "%s Wiki page '%s' does not exist (no contents)\n", get_time(), $page;
            exit 11;
        }
    } else {
        printf STDERR "%s Parsing Wiki page '%s' failed\n", get_time(), $page;
        exit 12;
    }

} elsif ( $pull) {

    $mw = MediaWiki::API->new();

    $mw->{config}->{api_url}    = $wiki_url;
    $mw->{config}->{on_error}   = \&on_error;

    printf STDERR "%s Reading Wiki page '%s'\n", get_time(), $page;

    my $ref = $mw->get_page( { title => $page } );

    if ( $ref ) {
        if ( $ref->{'*'} ) {
            my $timestamp = $ref->{timestamp};
            printf STDERR "%s timestamp = %s\n", get_time(), ($timestamp ? $timestamp : '?');

            if ( $file ) {
                if ( open(OUT,">$file") ) {
                    printf STDERR "%s Writing Wiki page '%s' to file '%s'\n", get_time(), $page, $file;
                    binmode OUT, ":utf8";
                    printf OUT "%s", $ref->{'*'};
                    close( OUT );
                    printf STDERR "%s Done ... writing Wiki page '%s' to file '%s'\n", get_time(), $page, $file;
                } else {
                    printf STDERR "%s Can't open file '%s' for writing\n", get_time(), $file;
                    exit 10;
                }
            } else {
                printf STDERR "%s Writing Wiki page '%s' to STDOUT\n", get_time(), $page;
                printf "%s", $ref->{'*'};
                printf STDERR "%s Done ... writing Wiki page '%s' to STDOUT\n", get_time(), $page;
            }
        } else {
            printf STDERR "%s Wiki page '%s' does not exist (no contents)\n", get_time(), $page;
            exit 11;
        }
    } else {
        printf STDERR "%s Reading Wiki page '%s' failed\n", get_time(), $page;
        exit 12;
    }

} elsif ( $push ) {

    $mw = MediaWiki::API->new();

    $mw->{config}->{api_url}    = $wiki_url;
    $mw->{config}->{on_error}   = \&on_error;

    # log in to the wiki
    if ( $mw->login( { lgname => $username, lgpassword => $password } ) ) {

        printf STDERR "%s Reading Wiki page info '%s'\n", get_time(), $page;

        my $ref = $mw->get_page( { title => $page } );

        if ( $ref ) {
            if ( $ref->{'*'} ) {
                my $timestamp = $ref->{timestamp};
                printf STDERR "%s timestamp = %s\n", get_time(), ($timestamp ? $timestamp : '?');
                printf STDERR "%s Reading file '%s'\n", get_time(), $file;
                printf STDERR "%s\n", $text   if ( $debug );

                if ( open(IN,"<$file") ) {
                    $text = '';
                    binmode IN, ":utf8";
                    while ( <IN> ) {
                        $text .= $_;
                    }
                    close( IN );

                    printf STDERR "%s Pushing file '%s' to Wiki page '%s' with summary '%s'\n", get_time(), $file, $page, $summary;

                    if ( $mw->edit( {
                                action          => 'edit',
                                summary         => $summary,
                                title           => $page,
                                bot             => 'true',
                                basetimestamp   => $timestamp,          # to avoid edit conflicts
                                text            => $text
                                  } ) ) {
                        printf STDERR "%s Done ... pushing file '%s' to Wiki page '%s' with summary '%s'\n", get_time(), $file, $page, $summary;
                    } else {
                        printf STDERR "%s Edit Wiki page failed '%s'\n", get_time(), $page;
                        exit 20;
                    }

                } else {
                    printf STDERR "%s Can't open file '%s' for reading\n", get_time(), $file;
                    exit 21;
                }
            } else {
                printf STDERR "%s Wiki page '%s' does not exist (no contents), will not be created\n", get_time(), $page;
                exit 22;
            }
        } else {
            printf STDERR "%s Reading Wiki page information '%s' failed\n", get_time(), $page;
            exit 23;
        }
    } else {
        printf STDERR "%s Login to Wiki failed\n", get_time(), $file;
        exit 24;
    }

} elsif ( $watch ) {
    $mw = MediaWiki::API->new();

    $mw->{config}->{api_url}    = $wiki_url;
    $mw->{config}->{on_error}   = \&on_error;

    # log in to the wiki
    if ( $mw->login( { lgname => $username, lgpassword => $password } ) ) {

        printf STDERR "%s Setting 'watch' on Wiki page '%s'\n", get_time(), $page;

        if ( $mw->edit( { action => 'watch', title => $page } ) ) {
            printf STDERR "%s 'watch' set on Wiki page '%s'\n", get_time(), $page;
        } else {
            printf STDERR "%s Setting 'watch' on Wiki page '%s' failed\n", get_time(), $page;
            exit 30;
        }
    } else {
        printf STDERR "%s Login to Wiki failed\n", get_time(), $file;
        exit 31;
    }

}


#############################################################################################
#
#
#
#############################################################################################

sub on_error {
  printf STDERR "Error code: " . $mw->{error}->{code} . "\n";
  printf STDERR "Error details: " . $mw->{error}->{details} . "\n";
  printf STDERR "Error stacktrace: " . $mw->{error}->{stacktrace}."\n";
  die;
}


#############################################################################################
#
#
#
#############################################################################################

sub get_time {

    my ($sec,$min,$hour,$day,$month,$year) = localtime();

    return sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $month+1, $day, $hour, $min, $sec );
}


#############################################################################################
#
#
#
#############################################################################################

sub get_timestamp {

    my ($sec,$min,$hour,$day,$month,$year) = gmtime();

    # 2025-03-31T22:40:16Z
    return sprintf( "%04d-%02d-%02dZ%02d:%02d:%02dZ", $year+1900, $month+1, $day, $hour, $min, $sec );
}


1;

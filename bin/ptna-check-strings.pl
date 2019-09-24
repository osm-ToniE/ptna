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

use Getopt::Long;
use PtnaStrings     qw( InitMessageStrings GetMessageKeys GetMessageValue );


my $verbose                         = undef;
my $debug                           = undef;
my $from_file                      = "ptna-routes.pl";


GetOptions( 'verbose'                       =>  \$verbose,                      # --verbose
            'debug'                         =>  \$debug,                        # --debug
            'file=s'                        =>  \$from_file                     # --file=ptna-routes.pl 
          );

if ( $verbose ) {
    printf STDERR "ptna-check-strings.pl --verbose --file=%s\n", $from_file;
}

InitMessageStrings();

my $found_strings_ref = ReadStringsFromFile( $from_file );

if ( scalar keys %{$found_strings_ref} ) {
    
    my $new_strings_ref = FindNewMessageStrings( $found_strings_ref );
    
    if ( scalar keys %{$new_strings_ref} ) {
        ListNewMessageStringsStatements( $new_strings_ref );
    }
}

#############################################################################################
#
# search for:
#   $issues_string = gettext( "PTv2 route: empty 'role'" );
#   $issues_string = ngettext( "Route: unclear access (%s) to way", "Route: unclear access (%s) to ways", $num_of_errors );
#
#############################################################################################

sub ReadStringsFromFile {
    
    my $filename             = shift;
    
    my %strings_to_statement = ();
    
    if ( open(F,"< $filename") ) {
        
        while ( <F> ) {
            if ( m/\s*\$issues_string\s*=\s*(gettext\(\s*\")(.*)(\"\s*\)\s*;)/ ) {
                $strings_to_statement{$2} = $1 . $2 . $3;
                printf STDERR "--> \$strings_to_statement{%s} = %s\n", $2, $strings_to_statement{$2}    if ( $debug );
            } elsif ( m/\s*\$issues_string\s*=\s*(ngettext\(\s*\")(.*?)(\",\s*\".*\",\s*)(.*)(\s*\)\s*;)/ ) {
                $strings_to_statement{$2} = $1 . $2 . $3 . '1 ' . $5;
                printf STDERR "--> \$strings_to_statement{%s} = %s\n", $2, $strings_to_statement{$2}    if ( $debug );
            }
        }
        close( F );
    } else {
        printf STDERR "Could not read file '%s'\n", $filename;
    }

    return \%strings_to_statement;
}


#############################################################################################
#
#
#
#############################################################################################

sub FindNewMessageStrings {
    
    my $found_strings_ref = shift;
    
    my %new_strings       = ();
    
    my %existing_messages = ();
    
    map { $existing_messages{$_} = 1; } GetMessageKeys();
    
    foreach my $key ( keys (%{$found_strings_ref}) ) {
        printf STDERR "search for %s\n", $key    if ( $debug );
        if ( exists $existing_messages{$key} ) {
            printf STDERR "Found: %s\n", $key    if ( $debug );
        } else {
            printf STDERR "Not found: %s\n", $key    if ( $debug );
            $new_strings{$key} = ${$found_strings_ref}{$key};
        }
    }

    return \%new_strings;
}


#############################################################################################
#
#
#
#############################################################################################

sub ListNewMessageStringsStatements {

    my $new_strings_ref = shift;
    
    foreach my $key ( sort ( keys (%{$new_strings_ref}) ) ) {
        printf "    \$i++;\n";
        printf "    \$MessageList[\$i]->{'message'}                = %s\n", ${$new_strings_ref}{$key};
        printf "    \$MessageList[\$i]->{'option'}                 = \"\";\n";
        printf "    \$MessageList[\$i]->{'description'}            = \"\";\n";
        printf "    \$MessageList[\$i]->{'fix'}                    = \"\";\n";
        printf "    \$MessageList[\$i]->{'image'}                  = \"\";\n";
        printf "    \$MessageHash{\$MessageList[\$i]->{'message'}}  = \$i;\n";
        printf "\n";
    }
    
    return;
}




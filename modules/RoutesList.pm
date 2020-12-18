package RoutesList;

use strict;

use POSIX;
use Locale::gettext;

use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Encode;


####################################################################################################################
#
####################################################################################################################

my %routes_hash                     = ();
my @routes_list                     = ();
my $routes_list_index               = 0;

my %seen_ref                        = ();
my %seen_ref_type                   = ();
my %seen_ref_type_operator          = ();
my %seen_ref_type_operator_fromto   = ();

my $CSV_separator                   = ';';
my $OR_separator                    = '\|';
my $REF_separator                   = '\/';
my $Debug                           = undef;
my $Verbose                         = undef;

my $issues_string                   = '';   # to be used with ALL 'issues' and gettext/ngettext - a separate tool parses this code, extracts those statements and creates a list of all issues


#############################################################################################
#
# read the CSV Routes file information about 'ref', 'type', ...
#
#############################################################################################

sub ReadRoutes {
    my %hash                = @_;
    my $infile              = $hash{'file'};
    my $csv_separator       = $hash{'csv-separator'} || ';';
    my $or_separator        = $hash{'or-separator'}  || '\|';
    my $ref_separator       = $hash{'ref-separator'} || '\/';
    my $analyze             = $hash{'analyze'}   || 'analyze';
    my $debug               = $hash{'debug'};
    my $verbose             = $hash{'verbose'};
    my $ref_list_supported  = $hash{'supported_route_types'};

    my $NR                  = undef;
    my $hashref             = undef;
    my $last_type           = 'none';
    my $have_seen_pre       = 0;

    my %supported_routes_types = ();

    my ($ExpRef,$ExpRouteType,$ExpComment,$ExpFrom,$ExpTo,$ExpOperator,$ExpGtfsFeed,$ExpGtfsRouteId,$ExpGtfsReleaseDate);
    my @rest = ();

    $CSV_separator  = $csv_separator;
    $OR_separator   = $or_separator;
    $REF_separator  = $ref_separator;
    $Debug          = $debug;
    $Verbose        = $verbose;

    if ( $ref_list_supported ) {
        map { $supported_routes_types{$_} = 1; } @{$ref_list_supported};
    }

    if ( $infile ) {
        if ( -e $infile && -f $infile && -r $infile ) {

            if ( open(CSV,"< $infile") ) {
                binmode CSV, ":utf8";

                while ( <CSV> ) {
                    chomp();                                        # remove NewLine
                    s/\r$//;                                        # remove 'CR'
                    s/^\s*//;                                       # remove space at the beginning
                    s/\s*$//;                                       # remove space at the end

                    next    if ( !$_ );                             # ignore if line is empty

                    $NR                         = $.;
                    $routes_hash{$NR}->{'NR'}   = $NR;                 # store line number
                    $hashref                    = $routes_hash{$NR};
                    $hashref->{'contents'}      = $_;                  # store original contents

                    next    if ( !$_ );                                     # ignore if line is empty

                    if ( m/^[=#@+~\$\|-]/ ) {                                # headers, text, comment lines and reserved characters
                        if ( m/^(=+)([^=].*)/ ) {
                            $hashref->{'type'}          =  'header';        # store type
                            $hashref->{'level_string'}  =  $1;
                            $hashref->{'header'}        =  $2;
                            $hashref->{'level'}         =  0;
                            $hashref->{'header'}        =~ s/^\s*//;
                            $hashref->{'level'}++          while ( $hashref->{'level_string'} =~ m/=/g );
                            $hashref->{'level'}         =  6  if ( $hashref->{'level'} > 6 );
                            delete($hashref->{'level_string'});
                        } elsif ( m/^-(.*)/ ) {
                            $hashref->{'type'}          =  'text';          # store type
                            $hashref->{'text'}          =  $1;
                            $hashref->{'text'}          =~ s/^\s(\S)/\1/;   # delete only one and single trailing blank followed by a non-blank character
                        } elsif ( m/^#/ ) {
                            next;                                           # ignore 'comment' line
                        } elsif ( m/^([@+~\$\|])/ ) {
                            $issues_string          = gettext( "First character of line ('%s') is reserved. Please put the first CSV field into double quotes (\"...\"). Line %s of Routes-Data. Contents of line: '%s'" );
                            $hashref->{'type'}      = 'reserved';         # store type
                            $hashref->{'reserved'}  = sprintf( decode( 'utf8', $issues_string ), $1, $NR, $hashref->{'contents'} );   # this is an error
                        }
                    } elsif ( m/<pre>/ ) {                          # ignore lines with HTML <pre>
                        $have_seen_pre = 1;
                        next;
                    } elsif ( m|</pre>| ) {                         # ignore lines with HTML </pre>
                        last    if ( $have_seen_pre );              # terminate when this is aclosing </pre>
                        next;
                    } else {
                        $hashref->{'type'}       = 'route';          # store type

                        if ( m/^"/ || m/"$csv_separator/ || m/"$/ ) {
                            ($ExpRef,$ExpRouteType,$ExpComment,$ExpFrom,$ExpTo,$ExpOperator,$ExpGtfsFeed,$ExpGtfsRouteId,$ExpGtfsReleaseDate,@rest) = parse_csv( $csv_separator, $_ );
                        } else {
                            ($ExpRef,$ExpRouteType,$ExpComment,$ExpFrom,$ExpTo,$ExpOperator,$ExpGtfsFeed,$ExpGtfsRouteId,$ExpGtfsReleaseDate,@rest) = split( $csv_separator, $_ );
                        }

                        if ( $ExpRef ) {
                            $ExpRef =~ s/^\s*//;
                            $ExpRef =~ s/\s*$//;
                        }
                        if ( $ExpRouteType ) {
                            $ExpRouteType =~ s/^\s*//;
                            $ExpRouteType =~ s/\s*$//;
                        }
                        if ( $ExpComment ) {
                            $ExpComment =~ s/^\s*//;
                            $ExpComment =~ s/\s*$//;
                        }
                        if ( $ExpFrom ) {
                            $ExpFrom =~ s/^\s*//;
                            $ExpFrom =~ s/\s*$//;
                        }
                        if ( $ExpTo ) {
                            $ExpTo =~ s/^\s*//;
                            $ExpTo =~ s/\s*$//;
                        }
                        if ( $ExpOperator ) {
                            $ExpOperator =~ s/^\s*//;
                            $ExpOperator =~ s/\s*$//;
                        }
                        if ( $ExpGtfsFeed ) {
                            $ExpGtfsFeed =~ s/^\s*//;
                            $ExpGtfsFeed =~ s/\s*$//;
                        }
                        if ( $ExpGtfsRouteId ) {
                            $ExpGtfsRouteId =~ s/^\s*//;
                            $ExpGtfsRouteId =~ s/\s*$//;
                        }
                        if ( $ExpGtfsReleaseDate ) {
                            $ExpGtfsReleaseDate =~ s/^\s*//;
                            $ExpGtfsReleaseDate =~ s/\s*$//;
                            printf STDERR "ReadRoutes(): ExpReleaseDate = '%s' in line %d, contents: '%s'\n", $ExpGtfsReleaseDate, $NR, $hashref->{'contents'}      if ( $debug );
                        } else {
                            printf STDERR "ReadRoutes(): ExpReleaseDate = '' in line %d, contents: '%s'\n", $NR, $hashref->{'contents'}      if ( $debug );
                        }
                        $hashref->{'ref'}               = $ExpRef              || '';              # 'ref'=
                        $hashref->{'route'}             = $ExpRouteType        || '';              # 'route/route_master'=
                        $hashref->{'comment'}           = $ExpComment          || '';              # routes file comment
                        $hashref->{'from'}              = $ExpFrom             || '';              # 'from'
                        $hashref->{'to'}                = $ExpTo               || '';              # 'to'
                        $hashref->{'operator'}          = $ExpOperator         || '';              # 'operator'
                        $hashref->{'gtfs-feed'}         = $ExpGtfsFeed         || '';              # 'gtfs-feed
                        $hashref->{'gtfs-route-id'}     = $ExpGtfsRouteId      || '';              # 'gtfs-route-id'
                        $hashref->{'gtfs-release-date'} = $ExpGtfsReleaseDate  || '';              # 'gtfs-release-date'
                        if ( $ExpGtfsReleaseDate                                             &&
                             $ExpGtfsReleaseDate !~ m/^[\d][\d][\d][\d]-[01][\d]-[0-3][\d]$/ &&
                             $ExpGtfsReleaseDate ne 'previous'                               &&
                             $ExpGtfsReleaseDate ne 'latest'                                 &&
                             $ExpGtfsReleaseDate ne 'long-term'                                 ) {
                            $issues_string      = gettext( "CSV data: field 'release_date' (= '%s') is wrong. Should be a date (YYYY-MM-DD), 'latest', 'previous' or 'long-term'. Line %s of Routes-Data. Contents of line: '%s'" );
                            $hashref->{'type'}  = 'error';                                              # this is an error
                            $hashref->{'ref'}   = $ExpRef;                                              # this is an error
                            $hashref->{'error'} = sprintf( decode( 'utf8', $issues_string ), $ExpGtfsReleaseDate, $NR, $hashref->{'contents'} );   # this is an error
                        } elsif ( @rest ) {
                            $issues_string      = gettext( "CSV data includes too many ';'. Line %s of Routes-Data. Contents of line: '%s'" );
                            $hashref->{'type'}  = 'error';                                              # this is an error
                            $hashref->{'ref'}   = $ExpRef;                                              # this is an error
                            $hashref->{'error'} = sprintf( decode( 'utf8', $issues_string ), $NR, $hashref->{'contents'} );   # this is an error
                        } else {
                            if ( $ExpRef ) {
                                my @ref_or_list  = split( $or_separator,  $ExpRef );
                                my @ref_and_list = split( $ref_separator, $ExpRef );
                                $hashref->{'ref-or-list'}  = \@ref_or_list;
                                $hashref->{'ref-and-list'} = \@ref_and_list;

                                foreach my $reflistentry ( @ref_or_list ) {
                                    $seen_ref{$reflistentry} = 0  unless ( $seen_ref{$reflistentry} );
                                    $seen_ref{$reflistentry}++;
                                    #printf STDERR "seen_ref{%s} = %d\n", $reflistentry, $seen_ref{$reflistentry}      if ( $debug );

                                    if ( $ExpRouteType ) {
                                        if ( $supported_routes_types{$ExpRouteType} ) {
                                            $seen_ref_type{$reflistentry}->{$ExpRouteType} = 0    unless ( $seen_ref_type{$reflistentry}->{$ExpRouteType} );
                                            $seen_ref_type{$reflistentry}->{$ExpRouteType}++;
                                            #printf STDERR "seen_ref_type{%s}->{%s} = %d\n", $reflistentry, $ExpRouteType, $seen_ref_type{$reflistentry}->{$ExpRouteType}      if ( $debug );

                                            $seen_ref_type_operator{$reflistentry}->{$ExpRouteType}->{'ExpOperator='.$ExpOperator} = 0   unless ( $seen_ref_type_operator{$reflistentry}->{$ExpRouteType}->{'ExpOperator='.$ExpOperator} );
                                            $seen_ref_type_operator{$reflistentry}->{$ExpRouteType}->{'ExpOperator='.$ExpOperator}++;
                                            #printf STDERR "seen_ref_type_operator{%s}->{%s}->{%s} = %d\n", $reflistentry, $ExpRouteType, $ExpOperator, $seen_ref_type_operator{$reflistentry}->{$ExpRouteType}->{'ExpOperator='.$ExpOperator}      if ( $debug );

                                            $seen_ref_type_operator_fromto{$reflistentry}->{$ExpRouteType}->{'ExpOperator='.$ExpOperator}->{'['.$ExpFrom.'];['.$ExpTo.']'} = 1;

                                            if ( $ExpFrom ) {
                                                my @from_list = split( $or_separator, $ExpFrom );
                                                $hashref->{'from-list'} = \@from_list;
                                            }

                                            if ( $ExpTo ) {
                                                my @to_list = split( $or_separator, $ExpTo );
                                                $hashref->{'to-list'} = \@to_list;
                                            }
                                        } else {
                                            # this $ExpRouteType is not a valid one
                                            $issues_string      = gettext( "Route-Type is not supported: '%s'. Line %s of Routes-Data. Contents of line: '%s'" );
                                            $hashref->{'type'}  = 'error';                                              # this is an error
                                            $hashref->{'ref'}   = $ExpRef;                                              # this is an error
                                            $hashref->{'error'} = sprintf( decode( 'utf8', $issues_string ), $ExpRouteType, $NR, $hashref->{'contents'} );    # this is an error
                                        }
                                    } else {
                                        # if there is at least one separator, then $ExpRouteType as the second value must not be empty
                                        $issues_string      = gettext( "Route-Type is not set. Line %s of Routes-Data. Contents of line: '%s'" );
                                        $hashref->{'type'}  = 'error';                                              # this is an error
                                        $hashref->{'ref'}   = $ExpRef;                                              # this is an error
                                        $hashref->{'error'} = sprintf( decode( 'utf8', $issues_string ), $NR, $hashref->{'contents'} );   # this is an error
                                    }
                                }
                            }
                        }
                    }
                    #if ( $debug ) {
                    #    printf STDERR "NR = %d, type = %s, contents = '%s'\n", $routes_hash{$NR}->{'NR'}, $routes_hash{$NR}->{'type'}, $routes_hash{$NR}->{'contents'};
                    ##    foreach my $key ( sort ( keys ( %{$routes_hash{$NR}} ) ) ) {
                    #            printf STDERR "    %s = %s\n", $key, $routes_hash{$NR}->{$key}    if ( $key ne 'NR' && $key ne 'contents' && $key ne 'type' );
                    #    }
                    #}
                    $last_type = $routes_hash{$NR}->{'type'};
                    push( @routes_list, $hashref );
                }
                close( CSV );
                #printf STDERR "%s read\n", decode('utf8', $infile )                                     if ( $debug );
            } else {
                return sprintf( "Could not open file : '%s': %s", decode('utf8', $infile ), $! );
            }
        } else {
            return sprintf( "File does not exist: '%s'",    decode('utf8', $infile ) )  if ( !-e $infile );
            return sprintf( "Is not a file: '%s'",          decode('utf8', $infile ) )  if ( !-f $infile );
            return sprintf( "No read access for file '%s'", decode('utf8', $infile ) )  if ( !-r $infile );
        }
    } else {
           return sprintf( "File name not specified for 'Routes Data'" );
    }

    if ( $debug ) {
        if ( $analyze eq 'analyze' ) {
            foreach $ExpRef ( sort ( keys ( %seen_ref_type ) ) ) {
                foreach $ExpRouteType ( sort ( keys %{$seen_ref_type{$ExpRef}} ) ) {
                    if ( $seen_ref_type{$ExpRef}->{$ExpRouteType} > 1 ) {
                        printf STDERR "CSV-File %s: entry: ref=%s and type=%s found %d times\n", $infile, $ExpRef, $ExpRouteType, $seen_ref_type{$ExpRef}->{$ExpRouteType}           if ( $debug );
                        if ( $seen_ref_type_operator{$ExpRef}                  &&
                             $seen_ref_type_operator{$ExpRef}->{$ExpRouteType}    ) {
                            printf STDERR "CSV-File %s: entry: ref=%s and type=%s has %d different operator values\n", $infile, $ExpRef, $ExpRouteType, scalar(keys(%{$seen_ref_type_operator{$ExpRef}->{$ExpRouteType}}))        if ( $debug );

                            if ( scalar(keys(%{$seen_ref_type_operator{$ExpRef}->{$ExpRouteType}})) < $seen_ref_type{$ExpRef}->{$ExpRouteType} ) {
                                printf STDERR "CSV-File %s: potential problem with entry: ref=%s and type=%s\n", $infile, $ExpRef, $ExpRouteType          if ( $debug );

                                foreach $ExpOperator ( sort ( keys %{$seen_ref_type_operator{$ExpRef}->{$ExpRouteType}} ) ) {
                                    if ( $seen_ref_type_operator{$ExpRef}->{$ExpRouteType}->{$ExpOperator} > 1 ) {
                                        printf STDERR "CSV-File %s: problem with entry: ref=%s, type=%s and operator=%s ==> %d\n", $infile, $ExpRef, $ExpRouteType, $ExpOperator, $seen_ref_type_operator{$ExpRef}->{$ExpRouteType}->{$ExpOperator}           if ( $debug );

                                        foreach my $fromto ( sort ( keys %{$seen_ref_type_operator_fromto{$ExpRef}->{$ExpRouteType}->{$ExpOperator}} ) ) {
                                            if ( $seen_ref_type_operator_fromto{$ExpRef}->{$ExpRouteType}->{$ExpOperator}->{$fromto} > 1 ) {
                                                printf STDERR "CSV-File %s: big trouble with entry: ref=%s, type=%s, operator=%s, fromto=%s ==> %d\n", $infile, $ExpRef, $ExpRouteType, $ExpOperator, $fromto, $seen_ref_type_operator_fromto{$ExpRef}->{$ExpRouteType}->{$ExpOperator}->{$fromto}           if ( $debug );
                                            }
                                        }

                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return undef;
}


#############################################################################################
#
# return a list (array) fields of the CSV line
#
# https://stackoverflow.com/questions/3065095/how-do-i-efficiently-parse-a-csv-file-in-perl
#
#############################################################################################

sub parse_csv {
    my $separator = shift;
    my $text      = shift;
    my $value     = undef;
    my @cells     = ();
    my $regex     = qr/(?:^|$separator)(?:"([^"]*)"|([^$separator]*))/;

    return () unless $text;

    $text =~ s/\r?\n$//;

    while( $text =~ /$regex/g ) {
        $value = defined $1 ? $1 : $2;
        push( @cells, (defined $value ? $value : '') );
    }

    return @cells;
}


#############################################################################################
#
# return the list (array) of references to list
#
#############################################################################################

sub GetRoutesList {

    return @routes_list;

}


#############################################################################################
#
# return whether the combination of 'ref' is in the list
#
#############################################################################################

sub RefCount {
    my $ref         = shift;

    return $seen_ref{$ref}        if ( $ref && $seen_ref{$ref} );

    return 0;
}


#############################################################################################
#
# return whether the combination of 'ref' and 'type' is in the list
#
#############################################################################################

sub RefTypeCount {
    my $ref         = shift;
    my $route_type  = shift;

    return $seen_ref_type{$ref}->{$route_type}        if ( $ref && $route_type && $seen_ref{$ref} && $seen_ref_type{$ref} && $seen_ref_type{$ref}->{$route_type} );

    return 0;
}


#############################################################################################
#
# return how many combinations with identical 'ref' and 'type' and 'operator' are in the list
#
#############################################################################################

sub RefTypeOperatorCount {
    my $ref         = shift;
    my $route_type  = shift;
    my $operator    = shift;

    if ( $ref && $route_type                                                           &&
         $seen_ref{$ref}                                                               &&
         $seen_ref_type{$ref} && $seen_ref_type{$ref}->{$route_type}                   &&
         $seen_ref_type_operator{$ref} && $seen_ref_type_operator{$ref}->{$route_type} &&
         $seen_ref_type_operator{$ref}->{$route_type}->{'ExpOperator='.$operator}         ) {

            return $seen_ref_type_operator{$ref}->{$route_type}->{'ExpOperator='.$operator};

    }

    return 0;
}


#############################################################################################
#
# return combinations with identical 'ref' and 'type' and 'operator' from the list
#
#############################################################################################

sub GetRefTypeOperatorFromAndTo {
    my $RelRef              = shift;
    my $RelRouteType        = shift;
    my $RelOperator         = shift;
    my $RelFrom             = shift;
    my $RelTo               = shift;

    my @ret_list            = ();

    my $CombFrom            = undef;
    my $CombTo              = undef;
    my @CombFromArray       = ();
    my @CombToArray         = ();

    my $match               = undef;

    printf STDERR "%s GetRefTypeOperatorFromAndTo( %s, %s, %s, %s, %s );\n", get_time(), $RelRef, $RelRouteType, $RelOperator, $RelFrom, $RelTo  if ( $Debug );

    if ( $RelRef                                                                                 &&
         $RelRouteType                                                                           &&
         $seen_ref_type_operator_fromto{$RelRef}                                                 &&
         $seen_ref_type_operator_fromto{$RelRef}->{$RelRouteType}                                &&
         $seen_ref_type_operator_fromto{$RelRef}->{$RelRouteType}->{'ExpOperator='.$RelOperator}       ) {

        foreach my $combination ( sort ( keys ( %{$seen_ref_type_operator_fromto{$RelRef}->{$RelRouteType}->{'ExpOperator='.$RelOperator}} ) ) ) {

            printf STDERR "%s GetRefTypeOperatorFromAndTo(): checking combination '%s' with OR\n", get_time(), $combination  if ( $Debug );

            if ( $combination =~ m/^\[(.*?)\];\[(.*?)\]$/ ) {

                $CombFrom = $1;
                $CombTo   = $2;

                @CombFromArray  = split( $OR_separator, $CombFrom );
                @CombToArray    = split( $OR_separator, $CombTo );

                if ( ( scalar @CombFromArray || scalar @CombToArray ) &&
                     ( $RelFrom              || $RelTo )                 ) {
                    # minimum one of each pair must be defined

                    $match = undef;
                    foreach $CombFrom ( @CombFromArray ) {
                        if ( $CombFrom ) {
                            if ( $RelFrom ) {
                                if ( $CombFrom =~ m/\Q$RelFrom\E/ ) {
                                    $match = "$CombFrom =~ m/$RelFrom/";
                                    last;
                                } elsif ( $RelFrom =~ m/\Q$CombFrom\E/ ) {
                                    $match = "$RelFrom =~ m/$CombFrom/";
                                    last;
                                }
                            }
                            if ( $RelTo ) {
                                if ( $CombFrom =~ m/\Q$RelTo\E/ ) {
                                    $match = "$CombFrom =~ m/$RelTo/";
                                    last;
                                } elsif ( $RelTo =~ m/\Q$CombFrom\E/ ) {
                                    $match = "$RelTo =~ m/$CombFrom/";
                                    last;
                                }
                            }
                        }
                    }
                    if ( !defined($match) ) {
                        foreach $CombTo ( @CombToArray ) {
                            if ( $CombTo ) {
                                if ( $RelFrom ) {
                                    if ( $CombTo =~ m/\Q$RelFrom\E/ ) {
                                       $match = "$CombTo =~ m/$RelFrom/";
                                       last;
                                    } elsif ( $RelFrom =~ m/\Q$CombTo\E/ ) {
                                       $match = "$RelFrom =~ m/$CombTo/";
                                       last;
                                    }
                                }
                                if ( $RelTo ) {
                                    if ( $CombTo =~ m/\Q$RelTo\E/ ) {
                                       $match = "$CombTo =~ m/$RelTo/";
                                       last;
                                    } elsif ( $RelTo =~ m/\Q$CombTo\E/ ) {
                                       $match = "$RelTo =~ m/$CombTo/";
                                       last;
                                    }
                                }
                            }
                        }
                    }
                    if ( $match ) {
                        printf STDERR "%s GetRefTypeOperatorFromAndTo(): selecting combination 'ref' = '%s' and  'operator' = '%s': match = '%s'\n", get_time(), $RelRef, $RelOperator, $match     if ( $Debug );
                        push( @ret_list, $combination );
                    } else {
                        printf STDERR "%s GetRefTypeOperatorFromAndTo(): skipping combination 'ref' = '%s' and  'operator' = '%s': NO match\n", get_time(), $RelRef, $RelOperator     if ( $Debug );
                    }
                }
            }
        }

        # check whether we had a single match using 'from' OR 'to'

        if ( scalar(@ret_list) > 1 ) {
            #
            # no, there is more than one match, let's try 'from' AND 'to'

            my $from_match  = '';
            my $to_match    = '';
            my @second_list = @ret_list;
            @ret_list       = ();

            foreach my $combination ( @second_list ) {

                printf STDERR "%s GetRefTypeOperatorFromAndTo(): checking combination '%s' with AND\n", get_time(), $combination  if ( $Debug );

                if ( $combination =~ m/^\[.*$RelFrom.*\];\[.*$RelTo.*\]$/ ||
                     $combination =~ m/^\[.*$RelTo.*\];\[.*$RelFrom.*\]$/    ) {
                    printf STDERR "%s GetRefTypeOperatorFromAndTo(): selecting combination 'ref' = '%s' and  'operator' = '%s': from-match = '%s', to-match = '%s' with combination = '%s'\n", get_time(), $RelRef, $RelOperator, $from_match, $to_match, $combination     if ( $Debug );
                    push( @ret_list, $combination );
                } else {
                    printf STDERR "%s GetRefTypeOperatorFromAndTo(): skipping combination 'ref' = '%s' and  'operator' = '%s': NO match for 'from' = '%s' AND 'to' = '%s' with combination = '%s'\n", get_time(), $RelRef, $RelOperator, $from_match, $to_match, $combination     if ( $Debug );
                }
            }
        }

    }

    return @ret_list;
}


#############################################################################################
#
# return whether the combination of 'ref' and 'type' is in the list
#
#############################################################################################

sub RelationMatchesExpected {
    my %hash                        = ( @_ );

    my $RelRef                      = $hash{'rel-ref'}                          || '';
    my $RelRouteType                = $hash{'rel-route-type'}                   || '';
    my $RelOperator                 = $hash{'rel-operator'}                     || '';
    my $RelFrom                     = $hash{'rel-from'}                         || '';
    my $RelTo                       = $hash{'rel-to'}                           || '';
    my $RelID                       = $hash{'rel-id'}                           || '';
    my $EntryRef                    = $hash{'EntryRef'};
    my $handle_multiple             = $hash{'multiple_ref_type_entries'}        || 'analyze';

    return 0    unless ( $EntryRef );

    my $ExpOperator                 = $EntryRef->{'operator'}                   || '';
    my $ExpFrom                     = $EntryRef->{'from'}                       || '';
    my $ExpTo                       = $EntryRef->{'to'}                         || '';

    my $number_of_ref_type          = RefTypeCount( $RelRef, $RelRouteType );
    my $number_of_ref_type_operator = 0;

    my $match                       = undef;

    printf STDERR "%s Checking %s relation %s, 'ref' %s and  'operator' %s, ref-type-count %d\n", get_time(), $RelRouteType, $RelID, $RelRef, $RelOperator, $number_of_ref_type     if ( $Debug );

    if ( $number_of_ref_type > 1 && $handle_multiple eq 'analyze' ) {

        #
        # for this 'ref' and 'route_type' we have more than one entry in the CSV file
        # i.e. there are doubled lines (example: DE-HB-VBN: bus routes 256, 261, 266, ... appear twice in different areas of the network)
        # we should be able to distinguish them by their 'operator' values
        # this requires the operator to be stated in the CSV file as Expected Operator and the tag 'operator' being set in the relation
        #

        if ( $ExpOperator eq $RelOperator ) {

            $number_of_ref_type_operator = RefTypeOperatorCount( $RelRef, $RelRouteType, $RelOperator );

            if ( $number_of_ref_type_operator > 1 ) {

                my $ExpectedCombination              = '['.$ExpFrom.'];['.$ExpTo.']';

                printf STDERR "%s Checking %s relation %s, 'ref'= '%s' and  'operator'= '%s', ref-type-operator-count = '%d': expected combination: = '%s'\n", get_time(), $RelRouteType, $RelID, $RelRef, $RelOperator, $number_of_ref_type_operator, $ExpectedCombination     if ( $Debug );

                my @CombinationsWithMatchingFromAndTo = GetRefTypeOperatorFromAndTo( $RelRef, $RelRouteType, $RelOperator, $RelFrom, $RelTo, $ExpectedCombination );

                if ( scalar(@CombinationsWithMatchingFromAndTo) == 0 ) {

                    printf STDERR "%s Skipping relation %s, 'ref' = '%s' and  'operator' = '%s': NO match for from = '%s' and/or 'to' = '%s'\n", get_time(), $RelID, $RelRef, $RelOperator, $RelFrom, $RelTo     if ( $Debug );
                    return 0;

                } elsif ( scalar(@CombinationsWithMatchingFromAndTo) == 1 ) {

                    if ( $CombinationsWithMatchingFromAndTo[0] eq $ExpectedCombination ) {
                        printf STDERR "%s Selecting relation %s, 'ref' = '%s' and  'operator' = '%s': EXACT match for from = '%s' and/or 'to' = '%s'\n", get_time(), $RelID, $RelRef, $RelOperator, $RelFrom, $RelTo     if ( $Debug );
                        return 1;
                    } else {
                        printf STDERR "%s skipping relation %s, 'ref' = '%s' and  'operator' = '%s': match = '%s', not the expected one = '%s'\n", get_time(), $RelID, $RelRef, $RelOperator, $match, $ExpectedCombination     if ( $Debug );
                        return 0;
                    }

                } else {
                    printf STDERR "%s Skipping relation %s, 'ref' = '%s' and  'operator' = '%s': TOO MANY matches (%d) for from = '%s' and 'to' = '%s'\n", get_time(), $RelID, $RelRef, $RelOperator, scalar(@CombinationsWithMatchingFromAndTo), $RelFrom, $RelTo     if ( $Debug );
                    return 0;

                }
            } else {
                printf STDERR "%s Selecting relation %s, 'ref' %s 'operator' matches single expected operator (%s vs %s)\n", get_time(), $RelID, $RelRef, $RelOperator, $RelOperator     if ( $Debug );
                return 1;
            }
        } else {
            printf STDERR "%s Skipping relation %s, 'ref' %s: 'operator' does not match expected operator (%s vs %s)\n", get_time(), $RelID, $RelRef, $RelOperator, $RelOperator       if ( $Debug );
            return 0;
        }
    } else {
        # we do not have multiple entries or we are not interested to distinguish between them
        printf STDERR "%s Selecting relation %s, 'ref' %s and  'operator' %s: no multiple entries\n", get_time(), $RelID, $RelRef, $RelOperator     if ( $Debug );
        return 1;
    }

    return 0;
}


#############################################################################################

sub get_time {

    my ($sec,$min,$hour,$day,$month,$year) = localtime();

    return sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $month+1, $day, $hour, $min, $sec );
}




1;

package RoutesList;

use strict;

use POSIX;
use Locale::gettext;
use Text::ParseWords;

use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

#use Exporter;
#use base qw (Exporter);
#use Data::Dumper;
use Encode;

#our @EXPORT_OK  = qw( ReadRoutes );


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
    
    my %supported_routes_types = ();

    my ($ExpRef,$ExpRouteType,$ExpComment,$ExpFrom,$ExpTo,$ExpOperator);
    my @rest = ();
    
    if ( $ref_list_supported ) {
        map { $supported_routes_types{$_} = 1; } @{$ref_list_supported};
    }
    
    if ( $infile ) {
        if ( -e $infile && -f $infile && -r $infile ) {
            
            if ( open(CSV,"< $infile") ) {
                binmode CSV, ":utf8";
                
                while ( <CSV> ) {
                    chomp();                                        # remove NewLine
                    s/\r$//;                                        # remoce 'CR'
                    s/^\s*//;                                       # remove space at the beginning
                    s/\s*$//;                                       # remove space at the end
                    s/<pre>//;                                      # remove HTML tag if this is a copy from the Wiki-Page
                    s|</pre>||;                                     # remove HTML tag if this is a copy from the Wiki-Page
                    next    if ( !$_ );                             # ignore if line is empty
                    
                    $NR                         = $.;
                    $routes_hash{$NR}->{'NR'}   = $NR;                 # store line number
                    $hashref                    = $routes_hash{$NR};
                    $hashref->{'contents'}      = $_;                  # store original contents

                    if ( m/^[=#-]/ ) {                              # headers, text and comment lines
                        if ( m/^(=+)([^=].*)/ ) {
                            $hashref->{'type'}           =  'header';     # store type
                            $hashref->{'level_string'}   =  $1;
                            $hashref->{'header'}         =  $2;
                            $hashref->{'level'}          =  0;
                            $hashref->{'header'}         =~ s/^\s*//;
                            $hashref->{'level'}++           while ( $hashref->{'level_string'} =~ m/=/g );
                            $hashref->{'level'}          =  6  if ( $hashref->{'level'} > 6 );
                            delete($hashref->{'level_string'});
                        } elsif ( m/^-(.*)/ ) {
                            $hashref->{'type'}       =  'text';       # store type
                            $hashref->{'text'}       =  $1;
                            $hashref->{'text'}       =~ s/^\s*//;
                        } else {
                            next;   # ignore 'comment' line
                        }
                    } else {
                        $hashref->{'type'}       = 'route';          # store type
                        
                        if ( m/^"/ || m/"$csv_separator/ || m/"$/ ) {
                            ($ExpRef,$ExpRouteType,$ExpComment,$ExpFrom,$ExpTo,@rest) = parse_csv( $csv_separator, $_ );
                        } else {
                            ($ExpRef,$ExpRouteType,$ExpComment,$ExpFrom,$ExpTo,@rest) = split( $csv_separator, $_ );
                        }

                        $hashref->{'ref'}            = $ExpRef       || '';              # 'ref'
                        $hashref->{'route'}          = $ExpRouteType || '';              # 'route/route_master'
                        $hashref->{'comment'}        = $ExpComment   || '';              # routes file comment
                        $hashref->{'from'}           = $ExpFrom      || '';              # 'from'
                        $hashref->{'to'}             = $ExpTo        || '';              # 'to'
                        if ( @rest ) {
                            # 'operator' may include ';' (the separator)
                            $ExpOperator           = join( ';', @rest );
                            $hashref->{'operator'} = $ExpOperator;
                        } else {
                            $ExpOperator           = '';
                            $hashref->{'operator'} = '';              # no 'operator'
                        }

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
                                        
                                        if ( $ExpOperator ) {
                                            $seen_ref_type_operator{$reflistentry}->{$ExpRouteType}->{$ExpOperator} = 0   unless ( $seen_ref_type_operator{$reflistentry}->{$ExpRouteType}->{$ExpOperator} );
                                            $seen_ref_type_operator{$reflistentry}->{$ExpRouteType}->{$ExpOperator}++;
                                            #printf STDERR "seen_ref_type_operator{%s}->{%s}->{%s} = %d\n", $reflistentry, $ExpRouteType, $ExpOperator, $seen_ref_type_operator{$reflistentry}->{$ExpRouteType}->{$ExpOperator}      if ( $debug );
                                        
                                            $seen_ref_type_operator_fromto{$reflistentry}->{$ExpRouteType}->{$ExpOperator}->{$ExpFrom.';'.$ExpTo} = 0   unless ( $seen_ref_type_operator_fromto{$reflistentry}->{$ExpRouteType}->{$ExpOperator}->{$ExpFrom.';'.$ExpTo} );
                                            $seen_ref_type_operator_fromto{$reflistentry}->{$ExpRouteType}->{$ExpOperator}->{$ExpFrom.';'.$ExpTo}++;
                                        }
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
                                        $hashref->{'type'}  = 'error';                                              # this is an error
                                        $hashref->{'ref'}   = $ExpRef;                                              # this is an error
                                        $hashref->{'error'} = sprintf( gettext("Route-Type is not supported: '%s'. Line %s of Routes-Data. Contents of line: '%s'"), $ExpRouteType, $NR, $hashref->{'contents'} );    # this is an error
                                    }
                                } else {
                                    # if there is at least one separator, then $ExpRouteType as the second value must not be empty
                                    $hashref->{'type'}  = 'error';                                              # this is an error
                                    $hashref->{'ref'}   = $ExpRef;                                              # this is an error
                                    $hashref->{'error'} = sprintf( gettext("Route-Type is not set. Line %s of Routes-Data. Contents of line: '%s'"), $NR, $hashref->{'contents'} );   # this is an error
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
# return a list (array) fileds of the CSV line

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
# return whether the combination of 'ref' and 'type' is in the list
#
#############################################################################################

sub RefTypeOperatorCount {
    my $ref         = shift;
    my $route_type  = shift;
    my $operator    = shift;
    
    if ( $ref && $route_type && $operator                               && 
         $seen_ref{$ref}                                                && 
         $seen_ref_type{$ref} && $seen_ref_type{$ref}->{$route_type}    &&
         $seen_ref_type_operator{$ref} && $seen_ref_type_operator{$ref}->{$route_type} && $seen_ref_type_operator{$ref}->{$route_type}->{$operator} ) {
        
        return $seen_ref_type_operator{$ref}->{$route_type}->{$operator};
    }
    
    return 0;
}



1;

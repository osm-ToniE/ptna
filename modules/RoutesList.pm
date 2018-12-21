package RoutesList;

use strict;

use POSIX;
use Locale::gettext;

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
    my $separator           = $hash{'separator'} || ';';
    my $analyze             = $hash{'analyze'}   || 'analyze';
    my $debug               = $hash{'debug'};
    my $verbose             = $hash{'verbose'};
    my $ref_list_supported  = $hash{'supported_route_types'};
    
    my $NR                  = undef;
    my $hashref             = undef;
    my $last_type           = 'none';
    
    my %supported_routes_types = ();

    my ($ExpRef,$ExpRouteType,$ExpComment,$ExpFrom,$ExpTo,$ExpOperator);
    
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
                            if ( $last_type eq 'header' || $last_type eq 'text' ) {
                                $hashref->{'type'}       =  'text';       # store type
                                $hashref->{'text'}       =  $1;
                                $hashref->{'text'}       =~ s/^\s*//;
                            } elsif ( $last_type ne 'none' ) {
                                $hashref->{'type'}  = 'error';                                                                                  # this is an error
                                $hashref->{'ref'}   = gettext('ERROR');                                                                                  # this is an error
                                $hashref->{'error'} = sprintf( gettext("Simple text inside or directly after table is not supported. Line %s of Routes-Data. Contents of line: '%s'"), $NR, $hashref->{'contents'} );    # this is an error
                            }

                        } else {
                            next;   # ignore 'comment' line
                        }
                    } else {
                        $hashref->{'type'}       = 'route';          # store type
                         
                        #if ( m/$separator/ ) {
                            ($ExpRef,$ExpRouteType,$ExpComment,$ExpFrom,$ExpTo,$ExpOperator) = split( $separator );

                            $hashref->{'ref'}            = $ExpRef       || '';              # 'ref'
                            $hashref->{'route'}          = $ExpRouteType || '';              # 'route/route_master'
                            $hashref->{'comment'}        = $ExpComment   || '';              # routes file comment
                            $hashref->{'from'}           = $ExpFrom      || '';              # 'from'
                            $hashref->{'to'}             = $ExpTo        || '';              # 'to'
                            $hashref->{'operator'}       = $ExpOperator  || '';              # 'operator'

                            if ( $ExpRef ) {
                                $seen_ref{$ExpRef} = 0  unless ( $seen_ref{$ExpRef} );
                                $seen_ref{$ExpRef}++;
                                #printf STDERR "seen_ref{%s} = %d\n", $ExpRef, $seen_ref{$ExpRef}      if ( $debug );
                                
                                if ( $ExpRouteType ) {
                                    if ( $supported_routes_types{$ExpRouteType} ) {
                                        $seen_ref_type{$ExpRef}->{$ExpRouteType} = 0    unless ( $seen_ref_type{$ExpRef}->{$ExpRouteType} );
                                        $seen_ref_type{$ExpRef}->{$ExpRouteType}++;
                                        #printf STDERR "seen_ref_type{%s}->{%s} = %d\n", $ExpRef, $ExpRouteType, $seen_ref_type{$ExpRef}->{$ExpRouteType}      if ( $debug );
                                        
                                        if ( $ExpOperator ) {
                                            $seen_ref_type_operator{$ExpRef}->{$ExpRouteType}->{$ExpOperator} = 0   unless ( $seen_ref_type_operator{$ExpRef}->{$ExpRouteType}->{$ExpOperator} );
                                            $seen_ref_type_operator{$ExpRef}->{$ExpRouteType}->{$ExpOperator}++;
                                            #printf STDERR "seen_ref_type_operator{%s}->{%s}->{%s} = %d\n", $ExpRef, $ExpRouteType, $ExpOperator, $seen_ref_type_operator{$ExpRef}->{$ExpRouteType}->{$ExpOperator}      if ( $debug );
                                        
                                            $seen_ref_type_operator_fromto{$ExpRef}->{$ExpRouteType}->{$ExpOperator}->{$ExpFrom.';'.$ExpTo} = 0   unless ( $seen_ref_type_operator_fromto{$ExpRef}->{$ExpRouteType}->{$ExpOperator}->{$ExpFrom.';'.$ExpTo} );
                                            $seen_ref_type_operator_fromto{$ExpRef}->{$ExpRouteType}->{$ExpOperator}->{$ExpFrom.';'.$ExpTo}++;
                                        }
                                    } else {
                                        # this $ExpRouteType is not a valid one
                                        $hashref->{'type'}  = 'error';                                                                      # this is an error
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
                        #} elsif ( m/(\S)/ ) {
                        #    $hashref->{'ref'}  = $_;         # 'ref'
                        #    $seen_ref{$_} = $seen_ref{$_} ? $seen_ref{$_}++ : 1;
                        #    printf STDERR "seen_ref{%s} = %d\n", $_, $seen_ref{$_}      if ( $debug );
                        #    $seen_ref_type{$_}->{'__any__'} = 0     unless ($seen_ref_type{$_}->{'__any__'} );
                        #    $seen_ref_type{$_}->{'__any__'}++;
                        #    printf STDERR "seen_ref_type{%s}->{%s} = %d\n", $_, '__any__', $seen_ref_type{$_}->{'__any__'}      if ( $debug );
                        #}
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

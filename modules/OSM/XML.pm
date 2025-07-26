package OSM::XML;

use strict;

use Exporter;
use base qw (Exporter);
use Data::Dumper;

use Geo::Parse::OSM;
use OSM::Data     qw( %META %NODES %WAYS %RELATIONS );

our @EXPORT_OK  = qw( parse );

my $debug       = undef;
my $verbose     = undef;


####################################################################################################################
#
####################################################################################################################

#############################################################################################
#
# read the XML file with the OSM information
#
#############################################################################################

sub parse {
    my %hash   = @_;
    my $infile = $hash{'data'};
    $debug     = $hash{'debug'};
    $verbose   = $hash{'verbose'};

    if ( $infile ) {
        if ( -f $infile && -r $infile ) {
            #
            # this is a hack, because Goe::Parse::OSM does not find 'meta' information
            if ( open(DATA,"< $infile") ) {
                my ($sec,$min,$hour,$day,$month,$year) = localtime();
                my $date_and_time = sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $month+1, $day, $hour, $min, $sec );
                my $count = 0;
                my $ line = undef;
                while ( <DATA> ) {
                    $count++;
                    $line = $_;
                    if ( $line =~ m{<meta }xo ) {
                        # META attributes
                        # <meta osm_base="2018-01-08T18:48:02Z" areas="2018-01-08T18:26:02Z"/>

                        my @res = $line =~ m{ (?<attr>\w+) = (?<q>['"]) (?<val>.*?) \k<q> }gx;
                        while (@res) {
                            my ( $attr, undef, $val ) = ( shift @res, shift @res, shift @res );
                            $META{$attr} = $val;
                            #printf STDERR "META{%s} = %s\n", $attr, $val;
                            printf STDERR "%s META : %s = '%s'\n", $date_and_time, $attr, $val      if ( $verbose );
                        }
                    } elsif ( $line =~ m{osmosis_replication_timestamp=([0-9TZ:-]*)}xo ) {
                        # META attributes
                        # <osm version="0.6" generator="https://ptna.openstreetmap.de osmosis_replication_timestamp=2024-07-10T20:21:22Z">

                        $META{'osm_base'} = $1;
                    }
                    last if ( $count > 5 );
                }
                close( DATA );
                my $GPO = Geo::Parse::OSM->new( $infile );

                if ( $GPO ) {
                    $GPO->parse( \&_parse_CB );
                    return 1;
                }
            }
        }
    }

    return undef;
}

####################################################################################################################
#
####################################################################################################################

sub _parse_CB {
    my $obj_type = $_[0]->{'type'};
    my $obj_id   = $_[0]->{'id'};

    if ( $obj_type ) {
        if ( $obj_type eq 'node' ) {
            if ( $obj_id ) {
                _readDataInto( \%{$NODES{$obj_id}}, $_[0] );
            } else {
                printf STDERR "id not set for type: %s\n",$obj_type;
            }
        } elsif ( $obj_type eq 'way' ) {
            if ( $obj_id ) {
                _readDataInto( \%{$WAYS{$obj_id}}, $_[0] );
            } else {
                printf STDERR "id not set for type: %s\n",$obj_type;
            }
        } elsif ( $obj_type eq 'relation' ) {
            if ( $obj_id ) {
                _readDataInto( \%{$RELATIONS{$obj_id}}, $_[0] );
            } else {
                printf STDERR "id not set for type: %s\n",$obj_type;
            }
        } elsif ( $obj_type eq 'bound' || $obj_type eq 'bounds' ) {
            ; # ignore
        } else {
            printf STDERR "unknown type '%s'\n", $obj_type;
        }
    } else {
        printf STDERR "type not set\n"      unless ( $obj_type );
    }

}


####################################################################################################################
#
####################################################################################################################

sub _readDataInto {
    my $target_ref  = shift;
    my $data_ref    = shift;

    #printf STDERR "target_ref = %s, data_ref = %s\n", $target_ref, $data_ref;
    while ( my ($key,$value) = each(%{$data_ref}) ) {
        #printf STDERR "%s = %s, ", $key, $value;
        if ( ref($value) eq 'HASH' ) {                      # this covers 'tag'
             foreach my $tag (keys(%{$value})) {
                $target_ref->{$key}->{$tag} = $value->{$tag};
                #printf STDERR "target_ref->{%s}->{%s} = %s, ", $key, $tag, $value->{$tag};
            }
        } elsif ( ref($value) eq 'ARRAY' ) {                # this covers 'chain' (way) and 'members' (relation)
            my $index = 0;
            @{$target_ref->{$key}} = ();
            foreach my $element (@{$value}) {
                if ( ref($element) eq 'HASH' ) {            # this covers 'members' (relation)
                    foreach my $element_tag (keys(%{$element})) {
                        $target_ref->{$key}[$index]->{$element_tag} = $element->{$element_tag};
                        #printf STDERR "target_ref->{%s}[%d]->{%s} = %s, ", $key, $index, $element_tag, $element->{$element_tag};
                    }
                } else {                                    # this covers 'chain' (way)
                    push( @{$target_ref->{$key}}, $element );
                    #printf STDERR "target_ref->{%s}[%d] = %s, ", $key, $index, $element;
                }
                $index++;
            }
        } else {                                            # this covers 'id', 'lat', 'lon', 'type', ... (meta information of objects)
            $target_ref->{$key} = $value;
            #printf STDERR "target_ref->{%s}= %s, ", $key, $value;
        }
    }
    #printf STDERR "\n";
}

1;

package OSM::Geo;

use strict;

use Exporter;
use base qw (Exporter);
use Data::Dumper;

use OSM::Data     qw( %META %NODES %WAYS %RELATIONS );

use GIS::Distance;
use Math::Trig;
use Math::Units;

our @EXPORT_OK  = qw( Init PlatformToNodeDistance ConvertMetersToFeet Summary );

my $debug       = undef;
my $verbose     = undef;

my $gis         = undef;

my @distance_measurements           = ();
my $duration_distance_measurements  = 0;



sub Init {
    my %hash   = @_;

    $debug     = $hash{'debug'};
    $verbose   = $hash{'verbose'};
    $gis       = GIS::Distance->new();
}


sub Summary {
    printf STDERR "%s total duration of distance measurements = %.9f seconds\n", , get_time(),  $duration_distance_measurements;
    if ( $debug ) {
        foreach my $item ( @distance_measurements ) {
            printf STDERR "%s function = '%s', param1 = '%s', param2 = '%s', param3 = '%s', param4 = '%s', param5 = '%s', returns = '%s'\n",
                           get_time(),
                              $item->{'function'},
                                               $item->{'param1'} || '',
                                                              $item->{'param2'} || '',
                                                                             $item->{'param3'} || '',
                                                                                            $item->{'param4'} || '',
                                                                                                           $item->{'param5'},
                                                                                                                          $item->{'returns'} || '';
        }
    }
}

#############################################################################################
#
# functions for GEO handling using lat/lon of objects
#
#############################################################################################

#sub ObjectToObjectDistance {
#    my $type1           = shift || '';
#    my $id1             = shift || 0;
#    my $type2           = shift || '';
#    my $id2             = shift || 0;
#    my $distance        = 0;
#    my $min_distance    = 100000000;
#
#    printf STDERR "%s ObjectToObjectDistance( '%s', '%s', '%s', '%s' )\n", get_time(), $type1, $id1, $type2, $id2        if ( $debug );
#
#    if ( $type1 eq 'node' ) {
#        if ( $type2 eq 'node' ) {
#            $distance = $gis->distance_metal( $NODES{$id1}->{'lat'}, $NODES{$id1}->{'lon'}, $NODES{$id2}->{'lat'},$NODES{$id2}->{'lon'} ) * 1000;
#            printf STDERR "%s ObjectToObjectDistance( '%s', ['%s','%s'], '%s', ['%s','%s'], %d) = %f\n", get_time(), $type1, $NODES{$id1}->{'lat'}, $NODES{$id1}->{'lon'}, $type2, $NODES{$id2}->{'lat'},$NODES{$id2}->{'lon'}, $distance        if ( $debug );
#            return $distance;
#        } elsif ( $type2 eq 'way' ) {
#            for ( my $i = 0; $i <= $#{$WAYS{$id2}->{'chain'}}; $i++ ) {
#                $distance = ObjectToObjectDistance( 'node', $id1, 'node', ${$WAYS{$id2}->{'chain'}}[$i] );
#                $min_distance = ($min_distance > $distance) ? $distance : $min_distance;
#            }
#            printf STDERR "%s ObjectToObjectDistance( '%s', ['%s','%s'], '%s', '%s') = %f\n", get_time(), $type1, $NODES{$id1}->{'lat'}, $NODES{$id1}->{'lon'}, $type2, $id2, $min_distance        if ( $debug );
#            return $min_distance;
#        } elsif ( $type2 eq 'relation' ) {
#            printf STDERR "%s ObjectToObjectDistance( '%s', ['%s','%s'], '%s', '%s') = %f\n", get_time(), $type1, $NODES{$id1}->{'lat'}, $NODES{$id1}->{'lon'}, $type2, $id2, $min_distance        if ( $debug );
#            ;
#        } else {
#            printf STDERR "%s Internal error in ObjectToObjectDistance( '%s', '%s', '%s', '%s')\n", get_time(), $type1, $id1, $type2, $id2;
#        }
#    } elsif ( $type1 eq 'way' ) {
#        if ( $type2 eq 'node' ) {
#            printf STDERR "%s ObjectToObjectDistance( '%s', '%s', '%s', ['%s','%s'] ) = %f\n", get_time(), $type1, $id1, $type2, $NODES{$id2}->{'lat'},$NODES{$id2}->{'lat'}, $min_distance        if ( $debug );
#            ;
#        } elsif ( $type2 eq 'way' ) {
#            printf STDERR "%s ObjectToObjectDistance( '%s', '%s', '%s', %s ) = %f\n", get_time(), $type1, $id1, $type2, $id2, $min_distance        if ( $debug );
#        } elsif ( $type2 eq 'relation' ) {
#            printf STDERR "%s ObjectToObjectDistance( '%s', '%s', '%s', %s ) = %f\n", get_time(), $type1, $id1, $type2, $id2, $min_distance        if ( $debug );
#        } else {
#            printf STDERR "%s Internal error in ObjectToObjectDistance( '%s', '%s', '%s', '%s' )\n", get_time(), $type1, $id1, $type2, $id2;
#        }
#    } elsif ( $type1 eq 'relation' ) {
#        if ( $type2 eq 'node' ) {
#            printf STDERR "%s ObjectToObjectDistance( '%s', '%s', '%s', ['%s','%s'] ) = %f\n", get_time(), $type1, $id1, $type2, $NODES{$id2}->{'lat'},$NODES{$id2}->{'lat'}, $min_distance        if ( $debug );
#        } elsif ( $type2 eq 'way' ) {
#            printf STDERR "%s ObjectToObjectDistance( '%s', '%s', '%s', %s ) = %f\n", get_time(), $type1, $id1, $type2, $id2, $min_distance        if ( $debug );
#        } elsif ( $type2 eq 'relation' ) {
#            printf STDERR "%s ObjectToObjectDistance( '%s', '%s', '%s', %s ) = %f\n", get_time(), $type1, $id1, $type2, $id2, $min_distance        if ( $debug );
#        } else {
#            printf STDERR "%s Internal error in ObjectToObjectDistance( '%s', '%s', '%s', '%s' )\n", get_time(), $type1, $id1, $type2, $id2;
#        }
#    } else {
#        printf STDERR "%s Internal error in ObjectToObjectDistance( '%s', '%s', '%s', '%s' )\n", get_time(), $type1, $id1, $type2, $id2;
#    }
#
#    return 0;  # in meters
#}


#############################################################################################

sub PlatformToNodeDistance {
    my $platform_type   = shift || '';
    my $platform_id     = shift || 0;
    my $node_id         = shift || 0;
    my $ok_if_le_than   = shift || 0;       # don't evaluate further if the distance is less or equal than xx meters
    my $recursion_depth = shift || 0;
    my $distance      = 0;
    my $min_distance  = 100000000;

    my $start_time    = Time::HiRes::time();
    $recursion_depth++;

    printf STDERR "%s PlatformToNodeDistance( '%s', '%s', '%s', %d, %d )\n", get_time(), $platform_type, $platform_id, $node_id, $ok_if_le_than, $recursion_depth        if ( $debug );

    if ( $platform_type eq 'node' ) {
        if ( exists($NODES{$platform_id}) && exists($NODES{$platform_id}->{'lat'}) && exists($NODES{$platform_id}->{'lon'}) &&
             exists($NODES{$node_id})     && exists($NODES{$node_id}->{'lat'})     && exists($NODES{$node_id}->{'lon'})         ) {
            $min_distance = $gis->distance_metal( $NODES{$platform_id}->{'lat'}, $NODES{$platform_id}->{'lon'}, $NODES{$node_id}->{'lat'}, $NODES{$node_id}->{'lon'} ) * 1000;
        } else {
            ;
        }
        printf STDERR "%s PlatformToNodeDistance( '%s', ['%s','%s'], ['%s','%s'], %d, %d ) = %f\n", get_time(), $platform_type, $NODES{$platform_id}->{'lat'}, $NODES{$platform_id}->{'lon'}, $NODES{$node_id}->{'lat'}, $NODES{$node_id}->{'lon'}, $ok_if_le_than, $recursion_depth, $min_distance        if ( $debug );
    } elsif ( $platform_type eq 'way' ) {
        my $current_platform_node_id  = 0;
        my $previous_platform_node_id = 0;
        for ( my $i = 0; $i <= $#{$WAYS{$platform_id}->{'chain'}}; $i++ ) {
            $previous_platform_node_id = $current_platform_node_id  unless ( $i == 0 );
            $current_platform_node_id  = ${$WAYS{$platform_id}->{'chain'}}[$i];
            $distance = PlatformToNodeDistance( 'node', $current_platform_node_id, $node_id, $ok_if_le_than, $recursion_depth );
            $min_distance = ($min_distance > $distance) ? $distance : $min_distance;
            last if ( $min_distance <= $ok_if_le_than );
            if (  $i > 0 && $previous_platform_node_id != $current_platform_node_id ) {
                $distance = PointToSegmentDistance($node_id,$previous_platform_node_id,$current_platform_node_id );
                $min_distance = ($min_distance > $distance) ? $distance : $min_distance;
                last if ( $min_distance <= $ok_if_le_than );
            }
        }
        printf STDERR "%s PlatformToNodeDistance( '%s', '%s', ['%s','%s'], %d, %d ) = %f\n", get_time(), $platform_type, $platform_id, $NODES{$node_id}->{'lat'}, $NODES{$node_id}->{'lon'}, $ok_if_le_than, $recursion_depth, $min_distance        if ( $debug );
    } elsif ( $platform_type eq 'relation' ) {
        # $debug = 1 if ( $platform_id == 6771456 ); # Bahnsteig der RB10 in Nauen DE-Bahnverkehr
        foreach my $platform_member_ref ( @{$RELATIONS{$platform_id}->{'members'}} ) {
            if ( $platform_member_ref->{'type'} eq 'node' || $platform_member_ref->{'type'} eq 'way' ) {
                printf STDERR "%s PlatformToNodeDistance( '%s', '%s', '%s', %d, %d ); handling '%s' member of this relation: 'role' = %s, 'ref' = %s\n", get_time(), $platform_type, $platform_id, $node_id, $ok_if_le_than, $recursion_depth, $platform_member_ref->{'type'}, $platform_member_ref->{'role'}, $platform_member_ref->{'ref'}   if ( $debug  );
                $distance = PlatformToNodeDistance( $platform_member_ref->{'type'}, $platform_member_ref->{'ref'}, $node_id, $ok_if_le_than, $recursion_depth );
                $min_distance = ($min_distance > $distance) ? $distance : $min_distance;
                last if ( $min_distance <= $ok_if_le_than );
            } else {
                printf STDERR "%s PlatformToNodeDistance( '%s', '%s', '%s', %d, %d ); skipping '%s' member of this relation: 'role' = %s, 'ref' = %s\n", get_time(), $platform_type, $platform_id, $node_id, $ok_if_le_than, $recursion_depth, $platform_member_ref->{'type'}, $platform_member_ref->{'role'}, $platform_member_ref->{'ref'};
            }
        }
        printf STDERR "%s PlatformToNodeDistance( '%s', '%s', ['%s','%s'], %d, %d ) = %f\n", get_time(), $platform_type, $platform_id, $NODES{$node_id}->{'lat'}, $NODES{$node_id}->{'lon'}, $ok_if_le_than, $recursion_depth, $min_distance        if ( $debug );
        # $debug = 0 if ( $platform_id == 6771456 ); # Bahnsteig der RB10 in Nauen DE-Bahnverkehr
    } else {
        printf STDERR "%s Internal error in PlatformToNodeDistance( '%s', '%s', '%s', %d, %d )\n", get_time(), $platform_type, $platform_id, $node_id, $ok_if_le_than, $recursion_depth;
        $min_distance = 0;
    }

    push( @distance_measurements, { 'function' => 'PlatformToNodeDistance', 'param1' => $platform_type, 'param2' => $platform_id, 'param3' => $node_id, 'param4' => $ok_if_le_than, 'param5' => $recursion_depth, 'returns' => $min_distance } );

    $duration_distance_measurements += (Time::HiRes::time() - $start_time)      if ( $recursion_depth == 1 ) ;

    return $min_distance;
}


#############################################################################################
#
# find the shortest distance from a point to a line
#
# ideally, the height of the triangle formed by the line as the hypotenuse and the point as the common point of the ankathets
#
# otherwise, the shortest distance of the point to one of the two points of the line
#
# or zero if the point is on the line
#
# adapted from https://www.sitepoint.com/community/t/distance-between-long-lat-point-and-line-segment/50583
#
#############################################################################################

sub PointToSegmentDistance {
    my $point_id          = shift || 0;
    my $segment_nodeA_id  = shift || 0;
    my $segment_nodeB_id  = shift || 0;
    my $distance          = 0;
    my $Px = $NODES{$point_id}->{'lat'};
    my $Py = $NODES{$point_id}->{'lon'};
    my $Ax = $NODES{$segment_nodeA_id}->{'lat'};
    my $Ay = $NODES{$segment_nodeA_id}->{'lon'};
    my $Bx = $NODES{$segment_nodeB_id}->{'lat'};
    my $By = $NODES{$segment_nodeB_id}->{'lon'};

    printf STDERR "%s PointToSegmentDistance( ['%s','%s'], ['%s','%s'], ['%s','%s'] )\n", get_time(), $Px, $Py, $Ax, $Ay, $Bx, $By        if ( $debug );

    if ( $Ax == $Bx && $Ay == $By ) {
        $distance = $gis->distance_metal( $Px, $Py, $Ax, $Ay ); # in kilo meters
    } else {
     	my $distAB = $gis->distance_metal( $Ax, $Ay, $Bx, $By ); # base or line segment (hypothenuse?)
     	my $distAP = $gis->distance_metal( $Ax, $Ay, $Px, $Py );
     	my $distBP = $gis->distance_metal( $Bx, $By, $Px, $Py );

     	my $angle_a = rad2deg( acos( ($distAP**2 + $distAB**2 - $distBP**2) / (2 * $distAP * $distAB) ) );
     	my $angle_b = rad2deg( acos( ($distAB**2 + $distBP**2 - $distAP**2) / (2 * $distAB * $distBP) ) );
     	my $angle_c = rad2deg( acos( ($distBP**2 + $distAP**2 - $distAB**2) / (2 * $distBP * $distAP) ) );

     	if ( $distAB + $distAP == $distBP ) {                       # then points are collinear                                                             - point is on the line segment
     		$distance = 0;
     	} elsif ( $angle_a <= 90 && $angle_b <= 90 ) {              # A or B are not obtuse, the segment is the longest side of the triangle (hypothenuse)  - return height as distance
            # find $s (semiperimeter) for Heron's formula
            my $s = ($distAB + $distAP + $distBP) / 2;

            # Heron's formula - area of a triangle
            my $area = sqrt($s * ($s - $distAB) * ($s - $distAP) * ($s - $distBP));

            # find the height of a triangle - ie - distance from point to line segment
            $distance = $area / (.5 * $distAB);
     	} else {                                                    # A or B are obtuse, the segment is not the longest side (hypothenuse) of triangle      - return smallest side as distance
     		$distance = ($distAP > $distBP) ? $distBP : $distAP;
     	}
    }

    $distance *= 1000; # from kilo-meters to meters

    printf STDERR "%s PointToSegmentDistance( ['%s','%s'], ['%s','%s'], ['%s','%s'] ) = %f\n", get_time(), $Px, $Py, $Ax, $Ay, $Bx, $By, $distance        if ( $debug );

    return $distance; # in meters
}


#############################################################################################

sub ConvertMetersToFeet {
    my $meters = shift || 0;
    return Math::Units::convert( $meters, 'm', 'ft' );
}


#############################################################################################

sub get_time {

    my ($sec,$min,$hour,$day,$month,$year) = localtime();

    return sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $month+1, $day, $hour, $min, $sec );
}


1;

package GTFS::GTFSvsOSM;

use strict;

use Exporter;
use base qw (Exporter);
use Data::Dumper;
use Unicode::Normalize;

use OSM::Data     qw( %META %NODES %WAYS %RELATIONS );
use OSM::Geo;
use GTFS::PtnaSQLite;

our @EXPORT_OK  = qw( Init Summary );

my $debug       = undef;
my $verbose     = undef;

my @check_against_gtfs_tasks                   = ();
my $duration_check_against_gtfs_tasks          = 0;


sub Init {
    my %hash   = @_;

    $debug     = $hash{'debug'};
    $verbose   = $hash{'verbose'};
}


sub Summary {
    printf STDERR "%s total duration of --check-against-gtfs tasks = %.9f seconds\n", get_time(), $duration_check_against_gtfs_tasks;
    if ( $debug ) {
        foreach my $item ( @check_against_gtfs_tasks ) {
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

sub get_time {

    my ($sec,$min,$hour,$day,$month,$year) = localtime();

    return sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $month+1, $day, $hour, $min, $sec );
}

1;

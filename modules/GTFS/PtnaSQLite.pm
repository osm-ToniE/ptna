package GTFS::PtnaSQLite;

use strict;

use POSIX;
use Locale::gettext qw();       # 'gettext()' will be overwritten in this file (at the end), so don't import from module into our name space

use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Encode;

use Exporter;
use base qw (Exporter);

our @EXPORT_OK  = qw( getGtfsRouteIdHtmlTag getGtfsTripIdHtmlTag getGtfsShapeIdHtmlTag );

use DBI;


#############################################################################################
#
#
#
#############################################################################################

my %config               = ();
my %db_handles           = ();
my %feed_of_open_db_file = ();

$config{'path-to-work'} = '/osm/ptna/work';                 # location where to start looking for the SQLite
$config{'name-suffix'}  = '-ptna-gtfs-sqlite.db';           # name suffix of current SQLite db


#############################################################################################
#
#
#
#############################################################################################

sub getGtfsLinkToRoutes {
    my $gtfs_feed      = shift;
    my $release_date   = shift || '';

    my $gtfs_html_tag  = html_escape($gtfs_feed);

    if ( _AttachToGtfsSqliteDb($gtfs_feed,$release_date) ) {

        my $gtfs_country =  $gtfs_feed;
           $gtfs_country =~ s/-.*$//;

            $gtfs_html_tag = sprintf( "<a href=\"/gtfs/%s/routes.php?feed=%s&release_date=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s\">%s</a>",
                                        uri_escape($gtfs_country),
                                        uri_escape($gtfs_feed), uri_escape($release_date),
                                        html_escape($gtfs_feed), html_escape($release_date),
                                        html_escape($gtfs_feed) );
    }

    return $gtfs_html_tag;
}


#############################################################################################
#
#
#
#############################################################################################

sub getGtfsRouteIdHtmlTag {
    my $gtfs_feed      = shift;
    my $release_date   = shift || '';
    my $route_id       = shift;

    my $gtfs_html_tag  = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"'GTFS feed' %s. %s\">GTFS!</a>",
                                  html_escape(gettext("is not set")),
                                  html_escape(gettext("GTFS database not found")) );

    if ( _AttachToGtfsSqliteDb($gtfs_feed,$release_date) ) {

        my $gtfs_country =  $gtfs_feed;
           $gtfs_country =~ s/-.*$//;

        if ( $route_id ) {

            my $RouteIdStatus = _getRouteIdStatus( $gtfs_feed, $release_date, $route_id );

            if ( $RouteIdStatus eq 'valid' ) {
                $gtfs_html_tag = sprintf( "<a class=\"gtfs-datevalid\" href=\"/gtfs/%s/trips.php?feed=%s&release_date=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Route-Id: %s\">GTFS</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed), uri_escape($release_date),
                                          uri_escape($route_id),
                                          html_escape($gtfs_feed), html_escape($release_date),
                                          html_escape($route_id) );
            } elsif ( $RouteIdStatus eq 'past' ) {
                $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateold\" href=\"/gtfs/%s/trips.php?feed=%s&release_date=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Route-Id: %s: 'route_id' %s.\">GTFS?</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed), uri_escape($release_date),
                                          uri_escape($route_id),
                                          html_escape($gtfs_feed), html_escape($release_date),
                                          html_escape($route_id),
                                          html_escape(gettext("is no longer valid (in the past)")) );
            } elsif ( $RouteIdStatus eq 'future' ) {
                $gtfs_html_tag = sprintf( "<a class=\"gtfs-datenew\" href=\"/gtfs/%s/trips.php?feed=%s&release_date=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Route-Id: %s: 'route_id' %s.\">GTFS?</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed), uri_escape($release_date),
                                          uri_escape($route_id),
                                          html_escape($gtfs_feed), html_escape($release_date),
                                          html_escape($route_id),
                                          html_escape(gettext("is not yet valid (in the future)")) );
            } else {
                my $found_in_previous_version = 0;

                if ( _AttachToGtfsSqliteDb($gtfs_feed,'previous') ) {
                    $RouteIdStatus = _getRouteIdStatus( $gtfs_feed, 'previous', $route_id );
                    if ( $RouteIdStatus eq 'valid' || $RouteIdStatus eq 'past' || $RouteIdStatus eq 'future' ) {
                        $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateprevious\" href=\"/gtfs/%s/trips.php?feed=%s&release_date=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Route-Id: %s: 'route_id' %s.\">GTFS??</a>",
                                                  uri_escape($gtfs_country),
                                                  uri_escape($gtfs_feed) , 'previous',
                                                  uri_escape($route_id),
                                                  html_escape($gtfs_feed), 'previous',
                                                  html_escape($route_id),
                                                  html_escape(gettext("outdated, fits to older GTFS version only")) );
                        $found_in_previous_version = 1;
                    }
                }

                if ( !$found_in_previous_version ) {
                    $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/trips.php?feed=%s&release_date=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Route-Id: %s: 'route_id' %s.\">GTFS!</a>",
                                              uri_escape($gtfs_country),
                                              uri_escape($gtfs_feed), uri_escape($release_date),
                                              uri_escape($route_id),
                                              html_escape($gtfs_feed), html_escape($release_date),
                                              html_escape($route_id),
                                              html_escape(gettext("does not exist")) );
                }
            }
        } else {
            $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/routes.php?feed=%s&release_date=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s - 'route_id' %s.\">GTFS!</a>",
                                      uri_escape($gtfs_country),
                                      uri_escape($gtfs_feed), uri_escape($release_date),
                                      html_escape($gtfs_feed), html_escape($release_date),
                                      html_escape(gettext("is not set")) );
        }

    } else {
        $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s: %s.\">GTFS!</a>",
                                  html_escape($gtfs_feed), html_escape($release_date),
                                  html_escape(gettext("GTFS database not found")) );
    }

    return $gtfs_html_tag;
}


#############################################################################################
#
#
#
#############################################################################################

sub getGtfsTripIdHtmlTag {
    my $gtfs_feed      = shift;
    my $release_date   = shift || '';
    my $trip_id        = shift;

    my $gtfs_html_tag  = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"'GTFS feed' %s. %s\">GTFS!</a>",
                                  html_escape(gettext("is not set")),
                                  html_escape(gettext("GTFS database not found")) );

    if ( _AttachToGtfsSqliteDb($gtfs_feed,$release_date) ) {

        my $gtfs_country =  $gtfs_feed;
           $gtfs_country =~ s/-.*$//;

        if ( $trip_id ) {

            my $TripIdStatus = _getTripIdStatus( $gtfs_feed, $release_date, $trip_id );

            if ( $TripIdStatus eq 'valid' ) {
                $gtfs_html_tag = sprintf( "<a class=\"gtfs-datevalid\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Trip-Id: %s\">GTFS</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed), uri_escape($release_date),
                                          uri_escape($trip_id),
                                          html_escape($gtfs_feed), html_escape($release_date),
                                          html_escape($trip_id) );
            } elsif ( $TripIdStatus eq 'past' ) {
                $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateold\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Trip-Id: %s: 'trip_id' %s.\">GTFS?</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed), uri_escape($release_date),
                                          uri_escape($trip_id),
                                          html_escape($gtfs_feed), html_escape($release_date),
                                          html_escape($trip_id),
                                          html_escape(gettext("is no longer valid (in the past)")) );
            } elsif ( $TripIdStatus eq 'future' ) {
                $gtfs_html_tag = sprintf( "<a class=\"gtfs-datenew\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Trip-Id: %s: 'trip_id' %s.\">GTFS?</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed), uri_escape($release_date),
                                          uri_escape($trip_id),
                                          html_escape($gtfs_feed), html_escape($release_date),
                                          html_escape($trip_id),
                                          html_escape(gettext("is not yet valid (in the future)")) );
            } else {
                my $found_in_previous_version = 0;

                if ( _AttachToGtfsSqliteDb($gtfs_feed,'previous') ) {
                    $TripIdStatus = _getTripIdStatus( $gtfs_feed, 'previous', $trip_id );
                    if ( $TripIdStatus eq 'valid' || $TripIdStatus eq 'past' || $TripIdStatus eq 'future' ) {
                        $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateprevious\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Trip-Id: %s: 'trip_id' %s.\">GTFS??</a>",
                                                  uri_escape($gtfs_country),
                                                  uri_escape($gtfs_feed), 'previous',
                                                  uri_escape($trip_id),
                                                  html_escape($gtfs_feed), 'previous',
                                                  html_escape($trip_id),
                                                  html_escape(gettext("outdated, fits to older GTFS version only")) );
                        $found_in_previous_version = 1;
                    }
                }

                if ( !$found_in_previous_version ) {
                    $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Trip-Id: %s: 'trip_id' %s.\">GTFS!</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed), uri_escape($release_date),
                                          uri_escape($trip_id),
                                          html_escape($gtfs_feed), html_escape($release_date),
                                          html_escape($trip_id),
                                          html_escape(gettext("does not exist")) );
                }
            }
        } else {
            $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/routes.php?feed=%s&release_date=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s - 'trip_id' %s.\">GTFS!</a>",
                                      uri_escape($gtfs_country),
                                      uri_escape($gtfs_feed), uri_escape($release_date),
                                      html_escape($gtfs_feed), html_escape($release_date),
                                      html_escape(gettext("is not set")) );
        }

    } else {
        $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s: %s.\">GTFS!</a>",
                                  html_escape($gtfs_feed), html_escape($release_date),
                                  html_escape(gettext("GTFS database not found")) );
    }

    return $gtfs_html_tag;
}


#############################################################################################
#
#
#
#############################################################################################

sub getGtfsShapeIdHtmlTag {
    my $gtfs_feed      = shift;
    my $release_date   = shift || '';
    my $shape_id       = shift;

    my $gtfs_html_tag  = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"'GTFS feed' %s. %s\">GTFS!</a>",
                                  html_escape(gettext("is not set")),
                                  html_escape(gettext("GTFS database not found")) );

    if ( _AttachToGtfsSqliteDb($gtfs_feed,$release_date) ) {

        my $gtfs_country =  $gtfs_feed;
           $gtfs_country =~ s/-.*$//;

        if ( $shape_id ) {

            my $ShapeIdStatus = _getShapeIdStatus( $gtfs_feed, $release_date, $shape_id );

            if ( $ShapeIdStatus eq 'valid' ) {
                $gtfs_html_tag = sprintf( "<a class=\"gtfs-datevalid\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Shape-Id: %s\">GTFS</a>",
                                           uri_escape($gtfs_country),
                                           uri_escape($gtfs_feed), uri_escape($release_date),
                                           uri_escape($shape_id),
                                           html_escape($gtfs_feed), html_escape($release_date),
                                           html_escape($shape_id) );
            } elsif ( $ShapeIdStatus eq 'past' ) {
                $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateold\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Shape-Id: %s: 'shape_id' %s.\">GTFS?</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed), uri_escape($release_date),
                                          uri_escape($shape_id),
                                          html_escape($gtfs_feed), html_escape($release_date),
                                          html_escape($shape_id),
                                          html_escape(gettext("is no longer valid (in the past)")) );
            } elsif ( $ShapeIdStatus eq 'future' ) {
                $gtfs_html_tag = sprintf( "<a class=\"gtfs-datenew\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Shape-Id: %s: 'shape_id' %s.\">GTFS?</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed), uri_escape($release_date),
                                          uri_escape($shape_id),
                                          html_escape($gtfs_feed), html_escape($release_date),
                                          html_escape($shape_id),
                                          html_escape(gettext("is not yet valid (in the future)")) );
            } elsif ( $ShapeIdStatus eq 'no shapes' ) {
                $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Shape-Id: %s: %s.\">GTFS!</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed), uri_escape($release_date),
                                          uri_escape($shape_id),
                                          html_escape($gtfs_feed), html_escape($release_date),
                                          html_escape($shape_id),
                                          html_escape(gettext("does not provide any 'shape' data")) );
            } else {
                my $found_in_previous_version = 0;

                if ( _AttachToGtfsSqliteDb($gtfs_feed,'previous') ) {
                    $ShapeIdStatus = _getShapeIdStatus( $gtfs_feed, 'previous', $shape_id );
                    if ( $ShapeIdStatus eq 'valid' || $ShapeIdStatus eq 'past' || $ShapeIdStatus eq 'future' ) {
                        $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateprevious\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Shape-Id: %s: 'shape_id' %s.\">GTFS??</a>",
                                                  uri_escape($gtfs_country),
                                                  uri_escape($gtfs_feed), 'previous',
                                                  uri_escape($shape_id),
                                                  html_escape($gtfs_feed), 'previous',
                                                  html_escape($shape_id),
                                                  html_escape(gettext("outdated, fits to older GTFS version only")) );
                        $found_in_previous_version = 1;
                    }
                }

                if ( !$found_in_previous_version ) {
                    $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, GTFS-Shape-Id: %s: 'shape_id' %s.\">GTFS!</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed), uri_escape($release_date),
                                          uri_escape($shape_id),
                                          html_escape($gtfs_feed), html_escape($release_date),
                                          html_escape($shape_id),
                                          html_escape(gettext("does not exist")) );
                }
            }
        } else {
            $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/routes.php?feed=%s&release_date=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s - 'shape_id' %s.\">GTFS!</a>",
                                      uri_escape($gtfs_country),
                                      uri_escape($gtfs_feed), uri_escape($release_date),
                                      html_escape($gtfs_feed), html_escape($release_date),
                                      html_escape(gettext("is not set")) );
        }

    } else {
        $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s: %s.\">GTFS!</a>",
                                  html_escape($gtfs_feed), html_escape($release_date),
                                  html_escape(gettext("GTFS database not found")) );
    }

    return $gtfs_html_tag;
}


#############################################################################################
#
#
#
#############################################################################################

sub _AttachToGtfsSqliteDb {
    my $feed           = shift;
    my $release_date   = shift || '';

    my $name_prefix    = ( $release_date ) ? $feed . '-' . $release_date : $feed;

    my $db_file    = '';

    #printf STDERR "_AttachToGtfsSqliteDb( %s, %s )\n", $feed, $release_date;
    if ( $feed && $feed =~ m/^[a-zA-Z0-9_.-]+$/ ) {
        my @prefixparts = split( /-/, $feed );
        my $countrydir  = shift( @prefixparts );

        $db_file = $config{'path-to-work'} . '/' . $countrydir . '/' . $name_prefix . $config{'name-suffix'};

        if ( -f $db_file ) {
            if ( -l $db_file ) {
                $db_file = $config{'path-to-work'} . '/' . $countrydir . '/' . readlink( $db_file );
            }
        } else {
            my $subdir = shift( @prefixparts );

            $db_file = $config{'path-to-work'} . '/' . $countrydir . '/' . $subdir . '/' . $name_prefix . $config{'name-suffix'};

            if ( -l $db_file ) {
                $db_file = $config{'path-to-work'} . '/' . $countrydir . '/' . $subdir . '/' . readlink( $db_file );
            }
        }

        if ( -f $db_file ) {
            #printf STDERR "_AttachToGtfsSqliteDb( %s, %s ) attaches to %s\n", $feed, $release_date, $db_file;

            if ( !$db_handles{$name_prefix} ) {
                if ( $feed_of_open_db_file{$db_file} ) {
                    my $existing_feed = $feed_of_open_db_file{$db_file};

                    if ( $db_handles{$existing_feed} ) {
                        $db_handles{$name_prefix} = $db_handles{$existing_feed};
                        #printf STDERR "_AttachToGtfsSqliteDb( %s, %s ) linked to %s\n", $feed, $release_date, $existing_feed;
                    }
                } else {
                    $db_handles{$name_prefix} = DBI->connect( "DBI:SQLite:dbname=$db_file", "", "", { AutoCommit => 0, RaiseError => 1 } );

                    $feed_of_open_db_file{$db_file} = $name_prefix;
                }
            }

            if ( $db_handles{$name_prefix} ) {
                return 1;
            } else {
                printf STDERR "%s DBI->connect(%s) failed: %s\n", get_time(), $db_file, $DBI::errstr;
            }
        }

    }

    return 0;
}


#############################################################################################
#
#
#
#############################################################################################

sub _getRouteIdStatus {
    my $feed           = shift;
    my $release_date   = shift || '';
    my $route_id       = shift;

    my $name_prefix    = ( $release_date ) ? $feed . '-' . $release_date : $feed;

    my @row         = ();
    my $today       = get_date();

    if ( $name_prefix && $route_id && $db_handles{$name_prefix} ) {

        my $sth = $db_handles{$name_prefix}->prepare( "SELECT DISTINCT trip_id
                                                       FROM            trips
                                                       WHERE           trips.route_id=?;" );
            $sth->execute( $route_id );

        my $min_start = 20500101;
        my $max_end   = 19700101;
        my $tms       = 0;
        my $tme       = 0;

        while ( @row = $sth->fetchrow_array() ) {
            if ( $row[0] ) {
                ( $tms, $tme ) = _getStartEndDateOfIdenticalTrips( $feed, $release_date, $row[0] );

                $min_start = ($tms < $min_start) ? $tms : $min_start;
                $max_end   = ($tme > $max_end)   ? $tme : $max_end;
            }
        }
        if ( $min_start != 20500101 && $max_end != 19700101 ) {
            if  ( $today > $max_end ) {
                return 'past';
            } elsif ( $today < $min_start ) {
                return 'future';
            } else {
                return 'valid';
            }
        }
    }

    return '';
}


#############################################################################################
#
#
#
#############################################################################################

sub _getTripIdStatus {
    my $feed           = shift;
    my $release_date   = shift || '';
    my $trip_id        = shift;

    my $name_prefix    = ( $release_date ) ? $feed . '-' . $release_date : $feed;

    my @row         = ();
    my $today       = get_date();

    if ( $name_prefix && $trip_id && $db_handles{$name_prefix} ) {

        my ( $min_start, $max_end ) = _getStartEndDateOfIdenticalTrips( $feed, $release_date, $trip_id );

        if ( $min_start != 20500101 && $max_end != 19700101 ) {
            if  ( $today > $max_end ) {
                return 'past';
            } elsif ( $today < $min_start ) {
                return 'future';
            } else {
                return 'valid';
            }
        }
    }

    return '';
}


#############################################################################################
#
#
#
#############################################################################################

sub _getShapeIdStatus {
    my $feed           = shift;
    my $release_date   = shift || '';
    my $shape_id       = shift;

    my $name_prefix    = ( $release_date ) ? $feed . '-' . $release_date : $feed;

    my @row                 = ();
    my $today               = get_date();
    my $trips_has_shape_id  = 0;

    if ( $name_prefix && $shape_id && $db_handles{$name_prefix} ) {

        my $sth =  $db_handles{$name_prefix}->prepare( "PRAGMA table_info(trips);" );
           $sth->execute();

        while ( @row = $sth->fetchrow_array() ) {
            if ( $row[1] && $row[1] eq 'shape_id' ) {
                $trips_has_shape_id = 1;
                last;
            }
        }

        if ( $trips_has_shape_id ) {
            $sth = $db_handles{$name_prefix}->prepare( "SELECT DISTINCT trip_id
                                                        FROM            trips
                                                        WHERE           shape_id=?;" );
            $sth->execute( $shape_id );

            my $min_start = 20500101;
            my $max_end   = 19700101;
            my $tms       = 0;
            my $tme       = 0;
            while ( @row = $sth->fetchrow_array() ) {
                if ( $row[0] ) {
                    ( $tms, $tme ) = _getStartEndDateOfIdenticalTrips( $feed, $release_date, $row[0] );

                    $min_start = ($tms < $min_start) ? $tms : $min_start;
                    $max_end   = ($tme > $max_end)   ? $tme : $max_end;
                }
            }
            if ( $min_start != 20500101 && $max_end != 19700101 ) {
                if  ( $today > $max_end ) {
                    return 'past';
                } elsif ( $today < $min_start ) {
                    return 'future';
                } else {
                    return 'valid';
                }
            }
        } else {
            return 'no shapes';
        }
    }

    return '';
}


#############################################################################################

sub _getStartEndDateOfIdenticalTrips {
    my $feed           = shift;
    my $release_date   = shift || '';
    my $trip_id        = shift;

    my $name_prefix    = ( $release_date ) ? $feed . '-' . $release_date : $feed;

    my $min_start_date = 20500101;
    my $max_end_date   = 19700101;

    my @row                     = ();
    my $hash_ref                = undef;
    my $db_has_ptna_trips       = 0;
    my %service_ids             = ();
    my $where_clause            = '';
    my $has_list_service_ids    = 0;

    if ( $name_prefix && $trip_id && $db_handles{$name_prefix} ) {

        my $sth =  $db_handles{$name_prefix}->prepare( "SELECT name FROM sqlite_master WHERE type='table' AND name='ptna_trips';" );
           $sth->execute();

        while ( @row = $sth->fetchrow_array() ) {
            if ( $row[0] && $row[0] eq 'ptna_trips' ) {
                $db_has_ptna_trips = 1;
                last;
            }
        }

        if ( $db_has_ptna_trips ) {

            $sth = $db_handles{$name_prefix}->prepare( "SELECT DISTINCT *
                                                        FROM            ptna_trips
                                                        WHERE           trip_id=?" );
            $sth->execute( $trip_id );

            while ( $hash_ref = $sth->fetchrow_hashref() ) {
                if ( $hash_ref->{'list_service_ids'} ) {
                    $has_list_service_ids  = 1;
                    map { $service_ids{$_} = 1; } split( '\|', $hash_ref->{'list_service_ids'} );

                    $where_clause = 'service_id=' . join( '', map{ '? OR service_id=' } keys ( %service_ids ) );
                    $where_clause =~ s/ OR service_id=$//;

                    my $sql = sprintf( "SELECT start_date,end_date
                                        FROM   calendar
                                        WHERE  %s;", $where_clause );

                    $sth = $db_handles{$name_prefix}->prepare( $sql );
                    $sth->execute( keys ( %service_ids ) );

                    while ( @row=$sth->fetchrow_array() ) {
                        if ( $row[0] < $min_start_date ) {
                            $min_start_date = $row[0];
                        }
                        if ( $row[1] > $max_end_date ) {
                            $max_end_date   = $row[1];
                        }
                    }
                }
            }
        }

        if ( $has_list_service_ids == 0 ) {
            $sth = $db_handles{$name_prefix}->prepare( "SELECT start_date,end_date
                                                        FROM   calendar
                                                        JOIN   trips ON trips.service_id = calendar.service_id
                                                        WHERE  trip_id=?;" );
            $sth->execute( $trip_id );

            while ( @row=$sth->fetchrow_array() ) {
                if ( $row[0] < $min_start_date ) {
                    $min_start_date = $row[0];
                }
                if ( $row[1] > $max_end_date ) {
                    $max_end_date   = $row[1];
                }
            }
        }
    }

    return ( $min_start_date, $max_end_date );
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


#############################################################################################

sub uri_escape {
    my $text = shift;
    if ( $text ) {
        $text =~ s/([^^A-Za-z0-9\-_.!~*()])/ sprintf "%%%02x", ord $1 /eg;
    }
    return $text;
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

sub get_time {

    my ($sec,$min,$hour,$day,$month,$year) = localtime();

    return sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $month+1, $day, $hour, $min, $sec );
}


#############################################################################################

sub get_date {

    my ($sec,$min,$hour,$day,$month,$year) = localtime();

    return sprintf( "%04d%02d%02d", $year+1900, $month+1, $day );
}


1;

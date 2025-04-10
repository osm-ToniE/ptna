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

our @EXPORT_OK  = qw( getRouteIdStatus getTripIdStatus getShapeIdStatus getGtfsRouteIdHtmlTag getGtfsRouteIdIconTag getGtfsTripIdHtmlTag getGtfsShapeIdHtmlTag getGtfsLinkToRoutes );

use DBI;


#############################################################################################
#
#
#
#############################################################################################

my %config               = ();
my %db_handle            = ();
my %list_separator       = ();
my %feed_of_open_db_file = ();

# install a cache for query results
# e.g. $gtfs_query_cache{'DE-BY-MVV-2024-03-27'}{'route_id'}{$route_id}[0] = 'valid' / [1] = '2023-12-14' / [2] = '2024-05-31' / [3] = ''
# e.g. $gtfs_query_cache{'DE-BY-MVV-2024-03-27'}{'route_id'}{$route_id}[0] = 'past'  / [1] = '2023-12-14' / [2] = '2024-01-31' / [3] = gettext("is no longer valid (in the past)"
# e.g. $gtfs_query_cache{'DE-BY-MVV-2024-03-27'}{'route_id'}{$route_id}[0] = ''      / [1] = ''           / [2] = ''           / [3] = gettext("does not exist")
# e.g. $gtfs_query_cache{'DE-BY-MVV'}{'trip_id'}{$trip_id}[0] = 'valid' / [1] = '2023-12-14' / [2] = '2024-05-31' / [3] = ''
my %gtfs_query_cache     = ();

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

    eval {
        if ( _AttachToGtfsSqliteDb($gtfs_feed,$release_date) ) {

            my $gtfs_country =  $gtfs_feed;
            $gtfs_country =~ s/-.*$//;

            $gtfs_html_tag = sprintf( "<a href=\"/gtfs/%s/routes.php?feed=%s&release_date=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s\">%s</a>",
                                        uri_escape($gtfs_country),
                                        uri_escape($gtfs_feed), uri_escape($release_date),
                                        html_escape($gtfs_feed), html_escape($release_date),
                                        html_escape($gtfs_feed) );
        }

    };
    warn sprintf( "getGtfsLinkToRoutes(%s,%s): %s",$gtfs_feed,$release_date,$@ ) if ( $@ );

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
    my $relation_id    = shift;
    my $tag_name       = shift || 'route_id';

    my $gtfs_html_tag  = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"'GTFS feed' %s. %s\">GTFS!</a>",
                                  html_escape(gettext("is not set")),
                                  html_escape(gettext("GTFS database not found")) );

    eval {
        if ( _AttachToGtfsSqliteDb($gtfs_feed,$release_date) ) {

            my $gtfs_country =  $gtfs_feed;
            $gtfs_country =~ s/-.*$//;

            if ( defined($route_id) && $route_id ne '' ) {

                my @RouteIdStatus = getRouteIdStatus( $gtfs_feed, $release_date, $route_id );

                if ( $RouteIdStatus[0] eq 'valid' ) {
                    $gtfs_html_tag = sprintf( "<a class=\"gtfs-datevalid\" href=\"/gtfs/%s/trips.php?feed=%s&release_date=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s\">GTFS</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$route_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($route_id),
                                            $RouteIdStatus[1] . ' - ' . $RouteIdStatus[2] );
                } elsif ( $RouteIdStatus[0] eq 'past' ) {
                    $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateold\" href=\"/gtfs/%s/trips.php?feed=%s&release_date=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS?</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$route_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($route_id),
                                            html_escape(gettext("is no longer valid (in the past)") . ': ' . $RouteIdStatus[1] . ' - ' . $RouteIdStatus[2]) );
                } elsif ( $RouteIdStatus[0] eq 'future' ) {
                    $gtfs_html_tag = sprintf( "<a class=\"gtfs-datenew\" href=\"/gtfs/%s/trips.php?feed=%s&release_date=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS?</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$route_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($route_id),
                                            html_escape(gettext("is not yet valid (in the future)") . ': ' . $RouteIdStatus[1] . ' - ' . $RouteIdStatus[2]) );
                } else {
                    my $found_in_previous_version = 0;

                    if ( _AttachToGtfsSqliteDb($gtfs_feed,'previous') ) {
                        @RouteIdStatus = getRouteIdStatus( $gtfs_feed, 'previous', $route_id );
                        if ( $RouteIdStatus[0] eq 'valid' || $RouteIdStatus[0] eq 'past' || $RouteIdStatus[0] eq 'future' ) {
                            $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateprevious\" href=\"/gtfs/%s/trips.php?feed=%s&release_date=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS??</a>",
                                                    uri_escape($gtfs_country),
                                                    uri_escape($gtfs_feed) , 'previous',
                                                    uri_escape(encode('utf8',$route_id)),
                                                    html_escape($gtfs_feed), 'previous',
                                                    html_escape($tag_name), html_escape($route_id),
                                                    html_escape(gettext("is outdated, fits to older GTFS version only")) );
                            $found_in_previous_version = 1;
                        }
                    }

                    if ( !$found_in_previous_version ) {
                        $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/trips.php?feed=%s&release_date=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS!</a>",
                                                uri_escape($gtfs_country),
                                                uri_escape($gtfs_feed), uri_escape($release_date),
                                                uri_escape(encode('utf8',$route_id)),
                                                html_escape($gtfs_feed), html_escape($release_date),
                                                html_escape($tag_name), html_escape($route_id),
                                                html_escape(gettext("does not exist")) );
                    }
                }
            } else {
                $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/routes.php?feed=%s&release_date=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' %s.\">GTFS!</a>",
                                        uri_escape($gtfs_country),
                                        uri_escape($gtfs_feed), uri_escape($release_date),
                                        html_escape($gtfs_feed), html_escape($release_date),
                                        html_escape($tag_name), html_escape(gettext("is not set")) );
            }

        } else {
            $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s : %s.\">GTFS!</a>",
                                    html_escape($gtfs_feed), html_escape($release_date),
                                    html_escape(gettext("GTFS database not found")) );
        }
    };
    warn sprintf( "getGtfsRouteIdHtmlTag(%s,%s,%s): %s",$gtfs_feed,$release_date,$route_id,$@ ) if ( $@ );

    return $gtfs_html_tag;
}


#############################################################################################
#
#
#
#############################################################################################

sub getGtfsRouteIdIconTag {
    my $gtfs_feed      = shift;
    my $release_date   = shift || '';
    my $route_id       = shift;
    my $relation_id    = shift;
    my $tag_name       = shift || 'route_id';
    my $gtfs_icon_tag  = '';

    if ( defined($route_id) && $route_id ne '' && $relation_id ) {
        $gtfs_icon_tag .= sprintf( ", <a href=\"/gtfs/compare-routes.php?feed=%s&release_date=%s&route_id=%s&relation=%s\" target=\"_blank\"><img src=\"/img/compare19.png\" title=\"%s\" style=\"height: 15px;width: 15px;vertical-align: middle;\"></a>",
                                uri_escape($gtfs_feed), uri_escape($release_date),
                                uri_escape(encode('utf8',$route_id)),
                                uri_escape($relation_id),
                                html_escape(gettext("Compare GTFS route with OSM route_master/route")) );
    }

    return $gtfs_icon_tag;
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
    my $relation_id    = shift;
    my $tag_name       = shift || 'trip_id';

    my $gtfs_html_tag  = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"'GTFS feed' %s. %s\">GTFS!</a>",
                                  html_escape(gettext("is not set")),
                                  html_escape(gettext("GTFS database not found")) );

    eval {
        if ( _AttachToGtfsSqliteDb($gtfs_feed,$release_date) ) {

            my $gtfs_country =  $gtfs_feed;
            $gtfs_country =~ s/-.*$//;

            if ( $trip_id ) {

                my @TripIdStatus = getTripIdStatus( $gtfs_feed, $release_date, $trip_id );

                #if ( $trip_id =~ m/1-U1-G-013-1/ ) {
                #    printf STDERR "getGtfsTripIdHtmlTag(%s,%s,%s) status : '%s'\n", $gtfs_feed, $release_date, $trip_id, join(' - ',@TripIdStatus);
                #}

                if ( $TripIdStatus[0] eq 'valid' ) {
                    $gtfs_html_tag = sprintf( "<a class=\"gtfs-datevalid\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s\">GTFS</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$trip_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($trip_id),
                                            $TripIdStatus[1] . ' - ' . $TripIdStatus[2] );
                    if ( $relation_id ) {
                        $gtfs_html_tag .=  sprintf( ", <a href=\"/gtfs/compare-trips.php?feed=%s&release_date=%s&trip_id=%s&relation=%s\" target=\"_blank\"><img src=\"/img/compare19.png\" title=\"%s\" style=\"height: 15px;width: 15px;vertical-align: middle;\"></a>",
                                                uri_escape($gtfs_feed), uri_escape($release_date),
                                                uri_escape(encode('utf8',$trip_id)),
                                                uri_escape($relation_id),
                                                html_escape(gettext("Compare GTFS trip with OSM route")) );
                    }
                } elsif ( $TripIdStatus[0] eq 'past' ) {
                    $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateold\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS?</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$trip_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($trip_id),
                                            html_escape(gettext("is no longer valid (in the past)") . ': ' . $TripIdStatus[1] . ' - ' . $TripIdStatus[2]) );
                    if ( $relation_id ) {
                        $gtfs_html_tag .=  sprintf( ", <a href=\"/gtfs/compare-trips.php?feed=%s&release_date=%s&trip_id=%s&relation=%s\" target=\"_blank\"><img src=\"/img/compare19.png\" title=\"%s\" style=\"height: 15px;width: 15px;vertical-align: middle;\"></a>",
                                                uri_escape($gtfs_feed), uri_escape($release_date),
                                                uri_escape(encode('utf8',$trip_id)),
                                                uri_escape($relation_id),
                                                html_escape(gettext("Compare GTFS trip with OSM route")) );
                    }
                } elsif ( $TripIdStatus[0] eq 'future' ) {
                    $gtfs_html_tag = sprintf( ", <a class=\"gtfs-datenew\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS?</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$trip_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($trip_id),
                                            html_escape(gettext("is not yet valid (in the future)") . ': ' . $TripIdStatus[1] . ' - ' . $TripIdStatus[2]) );
                    if ( $relation_id ) {
                        $gtfs_html_tag .=  sprintf( ", <a href=\"/gtfs/compare-trips.php?feed=%s&release_date=%s&trip_id=%s&relation=%s\" target=\"_blank\"><img src=\"/img/compare19.png\" title=\"%s\" style=\"height: 15px;width: 15px;vertical-align: middle;\"></a>",
                                                uri_escape($gtfs_feed), uri_escape($release_date),
                                                uri_escape(encode('utf8',$trip_id)),
                                                uri_escape($relation_id),
                                                html_escape(gettext("Compare GTFS trip with OSM route")) );
                        }
                } else {
                    my $found_in_previous_version = 0;

                    if ( _AttachToGtfsSqliteDb($gtfs_feed,'previous') ) {
                        @TripIdStatus = getTripIdStatus( $gtfs_feed, 'previous', $trip_id );
                        if ( $TripIdStatus[0] eq 'valid' || $TripIdStatus[0] eq 'past' || $TripIdStatus[0] eq 'future' ) {
                            $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateprevious\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS??</a>",
                                                    uri_escape($gtfs_country),
                                                    uri_escape($gtfs_feed), 'previous',
                                                    uri_escape(encode('utf8',$trip_id)),
                                                    html_escape($gtfs_feed), 'previous',
                                                    html_escape($tag_name), html_escape($trip_id),
                                                    html_escape(gettext("is outdated, fits to older GTFS version only")) );
                            if ( $relation_id ) {
                                $gtfs_html_tag .=  sprintf( ", <a href=\"/gtfs/compare-trips.php?feed=%s&release_date=%s&trip_id=%s&relation=%s\" target=\"_blank\"><img src=\"/img/compare19.png\" title=\"%s\" style=\"height: 15px;width: 15px;vertical-align: middle;\"></a>",
                                                        uri_escape($gtfs_feed), 'previous',
                                                        uri_escape(encode('utf8',$trip_id)),
                                                        uri_escape($relation_id),
                                                        html_escape(gettext("Compare GTFS trip with OSM route")) );
                            }
                            $found_in_previous_version = 1;
                        }
                    }

                    if ( !$found_in_previous_version ) {
                        $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/single-trip.php?feed=%s&release_date=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS!</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$trip_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($trip_id),
                                            html_escape(gettext("does not exist")) );
                    }
                }
            } else {
                $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/routes.php?feed=%s&release_date=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' %s.\">GTFS!</a>",
                                        uri_escape($gtfs_country),
                                        uri_escape($gtfs_feed), uri_escape($release_date),
                                        html_escape($gtfs_feed), html_escape($release_date),
                                        html_escape($tag_name), html_escape(gettext("is not set")) );
            }

        } else {
            $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s : %s.\">GTFS!</a>",
                                    html_escape($gtfs_feed), html_escape($release_date),
                                    html_escape(gettext("GTFS database not found")) );
        }
    };
    warn sprintf( "getGtfsTripIdHtmlTag(%s,%s,%s): %s",$gtfs_feed,$release_date,$trip_id,$@ ) . $@ if ( $@ );

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
    my $relation_id    = shift;
    my $tag_name       = shift || 'shape_id';

    my $gtfs_html_tag  = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"'GTFS feed' %s. %s\">GTFS!</a>",
                                  html_escape(gettext("is not set")),
                                  html_escape(gettext("GTFS database not found")) );

    eval {
        if ( _AttachToGtfsSqliteDb($gtfs_feed,$release_date) ) {

            my $gtfs_country =  $gtfs_feed;
            $gtfs_country =~ s/-.*$//;

            if ( $shape_id ) {

                my @ShapeIdStatus = getShapeIdStatus( $gtfs_feed, $release_date, $shape_id );
                if ( $ShapeIdStatus[0] eq 'valid' ) {
                    $gtfs_html_tag = sprintf( "<a class=\"gtfs-datevalid\" href=\"/gtfs/%s/shape.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s\">GTFS</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$shape_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($shape_id),
                                            $ShapeIdStatus[1] . ' - ' . $ShapeIdStatus[2]);
                } elsif ( $ShapeIdStatus[0] eq 'past' ) {
                    $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateold\" href=\"/gtfs/%s/shape.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS?</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$shape_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($shape_id),
                                            html_escape(gettext("is no longer valid (in the past)") . ': ' . $ShapeIdStatus[1] . ' - ' . $ShapeIdStatus[2]) );
                } elsif ( $ShapeIdStatus[0] eq 'future' ) {
                    $gtfs_html_tag = sprintf( "<a class=\"gtfs-datenew\" href=\"/gtfs/%s/shape.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS?</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$shape_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($shape_id),
                                            html_escape(gettext("is not yet valid (in the future)") . ': ' . $ShapeIdStatus[1] . ' - ' . $ShapeIdStatus[2]) );
                } elsif ( $ShapeIdStatus[0] eq 'no shapes' ) {
                    $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/shape.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS!</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$shape_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($shape_id),
                                            html_escape(gettext("does not provide any 'shape' data")) );
                } else {
                    my $found_in_previous_version = 0;

                    if ( _AttachToGtfsSqliteDb($gtfs_feed,'previous') ) {
                        @ShapeIdStatus = getShapeIdStatus( $gtfs_feed, 'previous', $shape_id );
                        if ( $ShapeIdStatus[0] eq 'valid' || $ShapeIdStatus[0] eq 'past' || $ShapeIdStatus[0] eq 'future' ) {
                            $gtfs_html_tag = sprintf( "<a class=\"gtfs-dateprevious\" href=\"/gtfs/%s/shape.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS??</a>",
                                                    uri_escape($gtfs_country),
                                                    uri_escape($gtfs_feed), 'previous',
                                                    uri_escape(encode('utf8',$shape_id)),
                                                    html_escape($gtfs_feed), 'previous',
                                                    html_escape($tag_name), html_escape($shape_id),
                                                    html_escape(gettext("is outdated, fits to older GTFS version only")) );
                            $found_in_previous_version = 1;
                        }
                    }

                    if ( !$found_in_previous_version ) {
                        $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/shape.php?feed=%s&release_date=%s&shape_id=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' = '%s' %s.\">GTFS!</a>",
                                            uri_escape($gtfs_country),
                                            uri_escape($gtfs_feed), uri_escape($release_date),
                                            uri_escape(encode('utf8',$shape_id)),
                                            html_escape($gtfs_feed), html_escape($release_date),
                                            html_escape($tag_name), html_escape($shape_id),
                                            html_escape(gettext("does not exist")) );
                    }
                }
            } else {
                $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/routes.php?feed=%s&release_date=%s\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s, '%s' %s.\">GTFS!</a>",
                                        uri_escape($gtfs_country),
                                        uri_escape($gtfs_feed), uri_escape($release_date),
                                        html_escape($gtfs_feed), html_escape($release_date),
                                        html_escape($tag_name), html_escape(gettext("is not set")) );
            }

        } else {
            $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"GTFS-Feed: %s, GTFS-Release-Date: %s : %s.\">GTFS!</a>",
                                    html_escape($gtfs_feed), html_escape($release_date),
                                    html_escape(gettext("GTFS database not found")) );
        }
    };
    warn sprintf( "getGtfsShapeIdHtmlTag(%s,%s,%s): %s",$gtfs_feed,$release_date,$shape_id,$@ ) if ( $@ );

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

        if ( -f $db_file && -s $db_file ) {
            if ( !$db_handle{$name_prefix} ) {
                if ( $feed_of_open_db_file{$db_file} ) {
                    my $existing_feed = $feed_of_open_db_file{$db_file};

                    if ( $db_handle{$existing_feed} ) {
                        $db_handle{$name_prefix} = $db_handle{$existing_feed};
                        $list_separator{$name_prefix} = $list_separator{$existing_feed};
                    }
                } else {
                    $db_handle{$name_prefix} = DBI->connect( "DBI:SQLite:dbname=$db_file", "", "", { AutoCommit => 0, RaiseError => 1, ReadOnly => 1 } );

                    $feed_of_open_db_file{$db_file} = $name_prefix;

                    $list_separator{$name_prefix} = '|';
                    my $sth = $db_handle{$name_prefix}->prepare( "SELECT * FROM ptna LIMIT 1;" );
                    $sth->execute();
                    my $hash_ref = $sth->fetchrow_hashref();
                    if ( exists($hash_ref->{'list_separator'}) && $hash_ref->{'list_separator'} ) {
                        $list_separator{$name_prefix} = $hash_ref->{'list_separator'};
                    }
                }
            }

            if ( $db_handle{$name_prefix} && $list_separator{$name_prefix} ) {
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

sub getRouteIdStatus {
    my $feed           = shift;
    my $release_date   = shift || '';
    my $route_id       = shift;

    my @ret_array = ( '', '', '', gettext("does not exist") );

    my $name_prefix    = ( $release_date ) ? $feed . '-' . $release_date : $feed;

    if ( $name_prefix && defined($route_id) && $route_id ne '' ) {
        eval {
            if ( _AttachToGtfsSqliteDb($feed,$release_date) ) {

                my @row         = ();
                my $today       = get_date();

                my $sth = $db_handle{$name_prefix}->prepare( "SELECT DISTINCT trip_id
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
                        @ret_array = ( 'past', expand_date($min_start), expand_date($max_end), gettext("is no longer valid (in the past)") );
                    } elsif ( $today < $min_start ) {
                        @ret_array = ( 'future', expand_date($min_start), expand_date($max_end), gettext("is not yet valid (in the future)") );
                    } else {
                        @ret_array = ( 'valid', expand_date($min_start), expand_date($max_end), '' );
                    }
                }
            } else {
                @ret_array = ( '', '', '', gettext("GTFS database not found") );
            }
        };
        warn sprintf( "getRouteIdStatus(%s,%s,%s): %s",$feed,$release_date,$route_id,$@ ) if ( $@ );
    } else {
        if ( defined($route_id) && $route_id ne '' ) {
            @ret_array = ( '', '', '', gettext("internal error") + ": \$feed " + gettext("is not set") );
        } else {
            @ret_array = ( '', '', '', gettext("is not set") );
        }
    }

    return @ret_array;
}


#############################################################################################
#
#
#
#############################################################################################

sub getTripIdStatus {
    my $feed           = shift;
    my $release_date   = shift || '';
    my $trip_id        = shift;
    my $route_id       = shift || '';       # if set, also check if trip_id belongs to route_id

    my @ret_array = ( '', '', '', gettext("does not exist") );

    my $name_prefix    = ( $release_date ) ? $feed . '-' . $release_date : $feed;

    if ( $name_prefix && $trip_id ) {
        eval {
            if ( _AttachToGtfsSqliteDb($feed,$release_date) ) {

                my @row         = ();
                my $today       = get_date();

                my ( $min_start, $max_end ) = _getStartEndDateOfIdenticalTrips( $feed, $release_date, $trip_id );

                if ( $min_start != 20500101 && $max_end != 19700101 ) {
                    if  ( $today > $max_end ) {
                        @ret_array = ( 'past', expand_date($min_start), expand_date($max_end), gettext("is no longer valid (in the past)") );
                    } elsif ( $today < $min_start ) {
                        @ret_array = ( 'future', expand_date($min_start), expand_date($max_end), gettext("is not yet valid (in the future)") );
                    } else {
                        @ret_array = ( 'valid', expand_date($min_start), expand_date($max_end), '' );
                    }
                }
            } else {
                @ret_array = ( '', '', '', gettext("GTFS database not found") );
            }
         };
        warn sprintf( "getTripIdStatus(%s,%s,%s): %s",$feed,$release_date,$trip_id,$@ ) if ( $@ );
    } else {
        if ( $trip_id ) {
            @ret_array = ( '', '', '', gettext("internal error") + ": \$feed " + gettext("is not set") );
        } else {
            @ret_array = ( '', '', '', gettext("is not set") );
        }
    }

    return @ret_array;
}


#############################################################################################
#
#
#
#############################################################################################

sub getShapeIdStatus {
    my $feed           = shift;
    my $release_date   = shift || '';
    my $shape_id       = shift;
    my $route_id       = shift || '';       # if set, also check if shape_id belongs to route_id
    my $trip_id        = shift || '';       # if set, also check if shape_id belongs to trip_id

    my @ret_array = ( '', '', '', gettext("does not exist") );

    my $name_prefix    = ( $release_date ) ? $feed . '-' . $release_date : $feed;

    if ( $name_prefix && $shape_id ) {
        eval {
            if ( _AttachToGtfsSqliteDb($feed,$release_date) ) {

                my @row                 = ();
                my $today               = get_date();
                my $trips_has_shape_id  = 0;


                my $sth =  $db_handle{$name_prefix}->prepare( "PRAGMA table_info(trips);" );
                $sth->execute();

                while ( @row = $sth->fetchrow_array() ) {
                    if ( $row[1] && $row[1] eq 'shape_id' ) {
                        $trips_has_shape_id = 1;
                        last;
                    }
                }

                if ( $trips_has_shape_id ) {
                    $sth = $db_handle{$name_prefix}->prepare( "SELECT DISTINCT trip_id
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
                            @ret_array = ( 'past', expand_date($min_start), expand_date($max_end), gettext("is no longer valid (in the past)") );
                        } elsif ( $today < $min_start ) {
                            @ret_array = ( 'future', expand_date($min_start), expand_date($max_end), gettext("is not yet valid (in the future)") );
                        } else {
                            @ret_array = ( 'valid', expand_date($min_start), expand_date($max_end), '' );
                        }
                    }
                } else {
                    @ret_array = ( 'no shapes', '', '', gettext("does not provide any 'shape' data") );
                }
            } else {
                @ret_array = ( '', '', '', gettext("GTFS database not found") );
            }
        };
        warn sprintf( "getShapeIdStatus(%s,%s,%s): %s",$feed,$release_date,$shape_id,$@ ) if ( $@ );
    } else {
        if ( $shape_id ) {
            @ret_array = ( '', '', '', gettext("internal error") + ": \$feed " + gettext("is not set") );
        } else {
            @ret_array = ( '', '', '', gettext("is not set") );
        }
    }

    return @ret_array;
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

    if ( $name_prefix && $trip_id && $db_handle{$name_prefix} ) {

        my $representative_trip_id = '';

        my $sth =  $db_handle{$name_prefix}->prepare( "SELECT name FROM sqlite_master WHERE type='table' AND name='ptna_trips';" );
           $sth->execute();

        while ( @row = $sth->fetchrow_array() ) {
            if ( $row[0] && $row[0] eq 'ptna_trips' ) {
                $db_has_ptna_trips = 1;
                last;
            }
        }

        if ( $db_has_ptna_trips ) {

            for ( my $i = 0; $i < 2 && $representative_trip_id eq ''; $i++ ) {
                if ( $i == 0 ) {
                    $sth = $db_handle{$name_prefix}->prepare( "SELECT DISTINCT *
                                                               FROM            ptna_trips
                                                               WHERE           trip_id=?"   );
                    $sth->execute( $trip_id );
                } else {
                    $sth = $db_handle{$name_prefix}->prepare( "SELECT DISTINCT *
                                                               FROM            ptna_trips
                                                               WHERE           list_trip_ids LIKE ? OR
                                                                               list_trip_ids LIKE ? OR
                                                                               list_trip_ids LIKE ?"   );
                    $sth->execute( $trip_id.$list_separator{$name_prefix}.'%', '%'.$list_separator{$name_prefix}.$trip_id.$list_separator{$name_prefix}.'%', '%'.$list_separator{$name_prefix}.$trip_id );
                }

                while ( $hash_ref = $sth->fetchrow_hashref() ) {
                    if ( $hash_ref->{'trip_id'} )  {
                        $representative_trip_id =$hash_ref->{'trip_id'};
                    }
                    if ( $hash_ref->{'list_service_ids'} ) {
                        $has_list_service_ids  = 1;
                        my $this_list_separator = $list_separator{$name_prefix} eq '|' ? '\\'.$list_separator{$name_prefix} : $list_separator{$name_prefix};
                        my @array_service_ids = split( $this_list_separator, $hash_ref->{'list_service_ids'} );

                        if ( scalar( @array_service_ids ) > 990 ) {
                            printf STDERR "_getStartEndDateOfIdenticalTrips(%s,%s,%s) number of service ids = %d\n", $feed, $release_date, $trip_id, scalar( @array_service_ids );
                            splice( @array_service_ids, 990 );
                        }

                        map { $service_ids{$_} = 1; } @array_service_ids;

                        $where_clause = 'service_id=' . join( '', map{ '? OR service_id=' } keys ( %service_ids ) );
                        $where_clause =~ s/ OR service_id=$//;

                        my $sql = sprintf( "SELECT start_date,end_date
                                            FROM   calendar
                                            WHERE  %s;", $where_clause );

                        $sth = $db_handle{$name_prefix}->prepare( $sql );
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
        }

        if ( $representative_trip_id && $has_list_service_ids == 0 ) {
            $sth = $db_handle{$name_prefix}->prepare( "SELECT start_date,end_date
                                                       FROM   calendar
                                                       JOIN   trips ON trips.service_id = calendar.service_id
                                                       WHERE  trip_id=?;" );
            $sth->execute( $representative_trip_id );

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
        $text =~ s/([^^A-Za-z0-9\-_.!~*()])/ sprintf "%%%0x", ord $1 /eg;
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


#############################################################################################

sub expand_date {

    my $date = shift;

    $date =~ s/^(\d\d\d\d)(\d\d)(\d\d)$/\1-\2-\3/;

    return $date;
}


1;

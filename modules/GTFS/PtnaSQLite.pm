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

my %config      = ();
my %db_handles  = ();

$config{'path-to-work'} = '/osm/ptna/work';
$config{'name-suffix'}  = '-ptna-gtfs-sqlite.db';

sub Init {
    my $hashref = shift;

    if ( $hashref ) {
        ;
    }

}


#############################################################################################
#
#
#
#############################################################################################

sub AttachToGtfsSqliteDb {
    my $feed       = shift;

    my $db_file    = '';

    if ( $feed && $feed =~ m/^[a-zA-Z0-9_.-]+$/ ) {
        my @prefixparts = split( /-/, $feed );
        my $countrydir  = shift( @prefixparts );

        $db_file = $config{'path-to-work'} . '/' . $countrydir . '/' . $feed . $config{'name-suffix'};

        #printf STDERR "db_file = %s\n", $db_file;

        if ( !-f $db_file ) {
            my $subdir = shift( @prefixparts );

            $db_file = $config{'path-to-work'} . '/' . $countrydir . '/' . $subdir . '/' . $feed . $config{'name-suffix'};
            #printf STDERR "db_file = %s\n", $db_file;
        }

        if ( -f $db_file ) {
            #printf STDERR "db_file found = %s\n", $db_file;
            return 1;
        }

    }

    return 0;
}


#############################################################################################
#
#
#
#############################################################################################

sub getGtfsRouteIdHtmlTag {
    my $gtfs_feed      = shift;
    my $route_id       = shift;

    my $gtfs_html_tag  = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"'GTFS feed' %s. %s\">GTFS</a>",
                                  html_escape(gettext("is not set")),
                                  html_escape(gettext("GTFS database not found")) );

    if ( AttachToGtfsSqliteDb($gtfs_feed) ) {
        my $gtfs_country =  $gtfs_feed;
           $gtfs_country =~ s/-.*$//;

        if ( $route_id ) {
            if ( ExistsRouteId($gtfs_feed,$route_id) ) {
                $gtfs_html_tag = sprintf( "<a href=\"/gtfs/%s/trips.php?network=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Route-Id: %s\">GTFS</a>", uri_escape($gtfs_country), uri_escape($gtfs_feed), uri_escape($route_id), html_escape($gtfs_feed), html_escape($route_id) );
            } else {
                $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/trips.php?network=%s&route_id=%s\" title=\"GTFS-Feed: %s, GTFS-Route-Id: %s: 'route_id' %s.\">GTFS</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed),
                                          uri_escape($route_id),
                                          html_escape($gtfs_feed),
                                          html_escape($route_id),
                                          html_escape(gettext("does not exist")) );
            }
        } else {
            $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/routes.php?network=%s\" title=\"GTFS-Feed: %s - 'route_id' %s.\">GTFS</a>",
                                      uri_escape($gtfs_country),
                                      uri_escape($gtfs_feed),
                                      html_escape($gtfs_feed),
                                      html_escape(gettext("is not set")) );
        }

    } else {
        $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"GTFS-Feed: %s: %s.\">GTFS</a>",
                                  html_escape($gtfs_feed),
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
    my $trip_id        = shift;

    my $gtfs_html_tag  = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"'GTFS feed' %s. %s\">GTFS</a>",
                                  html_escape(gettext("is not set")),
                                  html_escape(gettext("GTFS database not found")) );

    if ( AttachToGtfsSqliteDb($gtfs_feed) ) {
        my $gtfs_country =  $gtfs_feed;
           $gtfs_country =~ s/-.*$//;

        if ( $trip_id ) {
            if ( ExistsTripId($gtfs_feed,$trip_id) ) {
                $gtfs_html_tag = sprintf( "<a href=\"/gtfs/%s//single-trip.php?network=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Trip-Id: %s\">GTFS</a>", uri_escape($gtfs_country), uri_escape($gtfs_feed), uri_escape($trip_id), html_escape($gtfs_feed), html_escape($trip_id) );
            } else {
                $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/single-trip.php?network=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Trip-Id: %s: 'trip_id' %s.\">GTFS</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed),
                                          uri_escape($trip_id),
                                          html_escape($gtfs_feed),
                                          html_escape($trip_id),
                                          html_escape(gettext("does not exist")) );
            }
        } else {
            $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/routes.php?network=%s\" title=\"GTFS-Feed: %s - 'trip_id' %s.\">GTFS</a>",
                                      uri_escape($gtfs_country),
                                      uri_escape($gtfs_feed),
                                      html_escape($gtfs_feed),
                                      html_escape(gettext("is not set")) );
        }

    } else {
        $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"GTFS-Feed: %s: %s.\">GTFS</a>",
                                  html_escape($gtfs_feed),
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
    my $shape_id       = shift;

    my $gtfs_html_tag  = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"'GTFS feed' %s. %s\">GTFS</a>",
                                  html_escape(gettext("is not set")),
                                  html_escape(gettext("GTFS database not found")) );

    if ( AttachToGtfsSqliteDb($gtfs_feed) ) {
        my $gtfs_country =  $gtfs_feed;
           $gtfs_country =~ s/-.*$//;

        if ( $shape_id ) {
            if ( ExistsShapeId($gtfs_feed,$shape_id) ) {
                $gtfs_html_tag = sprintf( "<a href=\"/gtfs/%s//single-trip.php?network=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Shape-Id: %s\">GTFS</a>", uri_escape($gtfs_country), uri_escape($gtfs_feed), uri_escape($shape_id), html_escape($gtfs_feed), html_escape($shape_id) );
            } else {
                $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/single-trip.php?network=%s&trip_id=%s\" title=\"GTFS-Feed: %s, GTFS-Shape-Id: %s: 'shape_id' %s.\">GTFS</a>",
                                          uri_escape($gtfs_country),
                                          uri_escape($gtfs_feed),
                                          uri_escape($shape_id),
                                          html_escape($gtfs_feed),
                                          html_escape($shape_id),
                                          html_escape(gettext("does not exist")) );
            }
        } else {
            $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/%s/routes.php?network=%s\" title=\"GTFS-Feed: %s - 'shape_id' %s.\">GTFS</a>",
                                      uri_escape($gtfs_country),
                                      uri_escape($gtfs_feed),
                                      html_escape($gtfs_feed),
                                      html_escape(gettext("is not set")) );
        }

    } else {
        $gtfs_html_tag = sprintf( "<a class=\"bad-link\" href=\"/gtfs/\" title=\"GTFS-Feed: %s: %s.\">GTFS</a>",
                                  html_escape($gtfs_feed),
                                  html_escape(gettext("GTFS database not found")) );
    }

    return $gtfs_html_tag;
}


#############################################################################################
#
#
#
#############################################################################################

sub ExistsRouteId {
    my $feed        = shift;
    my $route_id    = shift;

    return 1;
}


#############################################################################################
#
#
#
#############################################################################################

sub ExistsTripId {
    my $feed        = shift;
    my $trip_id     = shift;

    return 1;
}


#############################################################################################
#
#
#
#############################################################################################

sub ExistsShapeId {
    my $feed        = shift;
    my $trip_id     = shift;

    return 1;
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



1;

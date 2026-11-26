#!/usr/bin/perl

use warnings;
use strict;

####################################################################################################################
#
#
#
####################################################################################################################

use POSIX;

use utf8;
binmode STDIN,  ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";


#############################################################################################

use Getopt::Long;

my $verbose                         = undef;
my $debug                           = undef;

GetOptions( 'debug'                             =>  \$debug,                        # --debug
            'verbose'                           =>  \$verbose,                      # --verbose
          );


#############################################################################################
#
# convert data from PTNA's created HTML page, section 'others' into a CSV list
#
#  <tr data-info="8788134" data-ref="BKB" class="line"><td class="ref">BKB</td><td class="relation"><img src="/img/Relation.svg" alt="Relation" /> <a href="https://osm.org/relation/8788134" title="Browse on map">8788134</a> <small>(<a href="https://osm.org/edit?editor=id&amp;relation=8788134" title="Edit in iD">iD</a>, <a href="https://localhost:8112/import?url=https://api.openstreetmap.org/api/0.6/relation/8788134/full" title="Edit in JOSM">JOSM</a>)</small></td><td class="type">route_master</td><td class="route_type">train</td><td class="name">BKB: Buckow (M&auml;rkische Schweiz) &lt;=&gt; M&uuml;ncheberg (Mark) - Kleinbahn</td><td class="network"></td><td class="operator">Museumsbahn Buckower Kleinbahn e.V.</td><td class="from"></td><td class="via"></td><td class="to"></td><td class="PTv">2</td><td class="issues">'network' ist nicht gesetzt</td><td class="notes">'operator' = 'Museumsbahn Buckower Kleinbahn e.V.'</td></tr>
#
# start when having seen:   <h1 id="otherlines">
# select from line      :   <td class="ref">(.*?)</td>          and
#                           <td class="route_type">(.*?)</td>   and
#                           <td class="operator">(.*?)</td>
# output as             :   $1;$2;;;;$3
# mark output as being seen
# don't output twice or more time

my $seen_otherslines_header  = undef;
my %seen_csv_entry           = ();
my $csv_entry                = undef;
my $header                   = undef;
my $route_type               = undef;
my $seen                     = undef;

while ( <> ) {

    if ( m|^\s*<h1 id="(.*?)">| ) {
        $seen = $1;
        if ( $verbose ) {
            printf STDERR "Seen: '%s'\n", $seen;
        }
        if ( $seen eq "otherslines" ) {
            $seen_otherslines_header = 1;
            #printf STDERR "Set: otherslines = 1\n";
        } else {
            $seen_otherslines_header = undef;
            #printf STDERR "Unset: otherslines = 0\n";
        }
    } else {
        if ( $seen_otherslines_header ) {
            if ( m/data-ref="([^"]*)"/ ) {
                $seen = $1;
                if ($verbose ) {
                    printf STDERR "Seen: %s;%s;;;;\n", $seen, $route_type;
                }
                $csv_entry = $seen . ';' . $route_type . ';;;;';
                if ( !defined($seen_csv_entry{$csv_entry}) ) {
                    printf "%s\n", $csv_entry;
                    $seen_csv_entry{$csv_entry} = 1;
                }
            } elsif ( m/<h2.*\((.*?)\)<\/h2>/ ) {
                $route_type = $1;
                printf STDERR "Seen: route_type = $route_type\n";
            }
        }
    }
}

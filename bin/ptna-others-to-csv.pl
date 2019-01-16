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
binmode STDIN,  ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";


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

my $seen_otherlines_header  = undef;
my %seen_csv_entry          = ();
my $csv_entry               = undef;
my $header                  = undef;

while ( <> ) {
    
    if ( m|^\s*<h1 id="(.*?)">| ) {
        if ($verbose ) {
            printf STDERR "Seen: %s\n", $1;
        }
        if ( $1 eq 'otherlines' ) {
            $seen_otherlines_header = 1;
        } else {
            $seen_otherlines_header = undef;
        }
    } else {
        if ( $seen_otherlines_header ) {
            if ( m|<td class="ref">(.*?)</td><td class="relation">.*<td class="route_type">(.*?)</td>.*<td class="operator">(.*?)</td>| ) {
                if ($verbose ) {
                    printf STDERR "Seen: %s;$2;;;;$3\n", $1, $2, $3;
                }
                $csv_entry = $1 . ';' . $2 . ';;;;' . $3;
                $csv_entry =~ s/&uuml;/ü/g;
                $csv_entry =~ s/&Uuml;/Ü/g;
                $csv_entry =~ s/&auml;/ä/g;
                $csv_entry =~ s/&Auml;/Ä/g;
                $csv_entry =~ s/&ouml;/ö/g;
                $csv_entry =~ s/&Ouml;/Ö/g;
                $csv_entry =~ s/&szlig;/ß/g;
                if ( !defined($seen_csv_entry{$csv_entry}) ) {
                    printf "%s\n", $csv_entry;
                    $seen_csv_entry{$csv_entry} = 1;
                }
            } elsif ( m|<h2 id=".*?">[0-9\.]+\s(.*?)</h2>| ) {
                $header = $1;
                $header =~ s/&uuml;/ü/g;
                $header =~ s/&Uuml;/Ü/g;
                $header =~ s/&auml;/ä/g;
                $header =~ s/&Auml;/Ä/g;
                $header =~ s/&ouml;/ö/g;
                $header =~ s/&Ouml;/Ö/g;
                $header =~ s/&szlig;/ß/g;
                printf "\n== %s\n\n", $header;
            }
        }
    }
}    


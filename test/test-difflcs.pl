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
use Data::Dumper;

binmode STDIN,  ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Algorithm::DiffOld;

my @left_array  = split('',"hello world, and so on!");
my @right_array = split('',"Wow, Hell Woryld!");

my $callback_compare = sub {
    my $a = shift || '';
    my $b = shift || '';
    my $source_right = shift || 'OSM';
    my $ddif         = defined($_[0]) ? shift : 100;
    my $toLower      = defined($_[0]) ? shift : 0;

    return $toLower ? lc($a) eq lc($b) : $a eq $b;
};

Algorithm::DiffOld::traverse_sequences( \@left_array,
                                        \@right_array,
                                        { MATCH     => sub { my $li = shift; my $ri = shift; printf "%s %s\n", $left_array[$li], $right_array[$ri]; },
                                          DISCARD_A => sub { my $li = shift; my $ri = shift; printf "%s %s\n", $left_array[$li], ' ';               },
                                          DISCARD_B => sub { my $li = shift; my $ri = shift; printf "%s %s\n", ' ',              $right_array[$ri]; }
                                        },
                                        $callback_compare,
                                        'OSM',
                                        100,
                                        1
                                      );

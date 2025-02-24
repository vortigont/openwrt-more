#!/usr/bin/perl

use strict;
use warnings;


#my $infile = 'hosts.ad';
my $threshold = 25;

my %stat;
my $element;

my $infile = $ARGV[0] or die "usage: $0 <file>";

open(FP, $infile) or die "Could not open file for reading: $!";

while (<FP>) {
    my $logstring = $_;

    $logstring =~ m/(\w+\.\w+\.\w+)$/ or next;

    $stat{$1}++;

    #print "$1\n";
    #my @entry = ( $logstring =~ /\w+\.\w+$/ );
}

foreach $element (keys %stat) {
    print "$element $stat{$element}\n" unless $stat{$element} < $threshold;
    #print "$element\n" unless $stat{$element} < $threshold;
}
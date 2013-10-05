#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

if (@ARGV == 1) {
   open (my $fh, "<", $ARGV[0]) or die "Can't open $ARGV[0]\n";
   my @file = <$fh>;
   my @python = conversion(@file);
} elsif (@ARGV == 0) {
   my @stdin = <>;
} else {
   die "Either 0 or 1 arguments";
}

# We have our array holding a Perl file and we want to turn it into a Python file
sub conversion {
   my @convert = @_;
   my @python;
   
   return @python;
}

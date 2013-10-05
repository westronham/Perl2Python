#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

if (@ARGV == 1) {
   open (my $fh, "<", $ARGV[0]) or die "Can't open $ARGV[0]\n";
   my @file = <$fh>;
   my @python = conversion(@file);
   foreach my $i (@python) {
      print $i;
   }
} elsif (@ARGV == 0) {
   my @stdin = <>;
} else {
   die "Either 0 or 1 arguments";
}

# We have our array holding a Perl file and we want to turn it into a Python file
sub conversion {
   my @convert = @_;
   my @python;
   foreach my $line (@convert) {
      if ($line =~ /^#!/ && $. == 1) {
	
		   # translate #! line 
		
		   push(@python, "#!/usr/bin/python2.7 -u\n");
	   } elsif ($line =~ /^\s*#/ || $line =~ /^\s*$/) {
	
		   # Blank & comment lines can be passed unchanged
		
		   push(@python, $line);
	   } elsif ($line =~ /^\s*print\s*"(.*)\\n"[\s;]*$/) {
		   # Python's print adds a new-line character by default
		   # so we need to delete it from the Perl print statement
		
		   push(@python,"print \"$1\"\n");
	   } else {
	
		   # Lines we can't translate are turned into comments
		
		   push(@python,"#$line\n");
      }
   }
   return @python;
}

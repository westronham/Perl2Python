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
   my @python = conversion(@stdin);
   foreach my $i (@python) {
      print $i;
   }
} else {
   die "Either 0 or 1 arguments";
}

# We have our array holding a Perl file and we want to turn it into a Python file
sub conversion {
   my @convert = @_;
   my @python;
   foreach my $line (@convert) {
      if ($line =~ /^#!\//) {
		   # translate #! line 
		   push(@python, "#!/usr/bin/python2.7 -u\n");
	   
	   } elsif ($line =~ /^\s*#/ || $line =~ /^\s*$/) {
		   # Blank & comment lines can be passed unchanged
		   push(@python, $line);
	   
	   # We check if something is a variable which means it starts with my (optional) ($|%|@)[text]
	   } elsif ($line =~ /^(my )?[@\$\%](.*) = (.*);$/) {
	      my $varName = $2;
	      my $value = $3;
	      
	      # Removes $ from variables in another variable 
	      # 2 concerns: do we do this for arrays and hashes too and are we able to have $ signs in a variable string perhaps because this would delete those
	      $value =~ tr/$//d;
	      
	      push(@python, "$varName = $value\n");
	   
	   } elsif ($line =~ /^\s*print/x) {
         
         # If we're just printing a single variable
	      if ($line =~ /\s*print\s*"\$([\w\d_]*)(\\n)?/i) {
	         push(@python, "print $1\n");
	     
	     # When we want to print operations on variables 
	     # Might need to modify to allow for more than 2 variables and 1 operation
      } elsif (my @matches = $line =~ /\s*print\s*"?\$([\w\d_]*)\s*([\+\-\*\/\%])\s*\$([\w\d_]*).*/) {
	      push(@python, "print $1 $2 $3\n");
	     
	     # Placeholder for when we want to print a string with variables
	     
	     # Printing plain string
	      } elsif ($line =~ /^\s*print\s*['"](.*)\\n['"][\s;]*$/) {
		      push(@python,"print \"$1\"\n");
	      }
	  
	   } else {
	
		   # Lines we can't translate are turned into comments
		
		   push(@python,"# $line\n");
      }
   }
   return @python;
}

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

sub conversion {
   my @convert = @_;
   my @python;
   foreach my $line (@convert) {
      
      # #! line
      if ($line =~ /^#!\//) {
		   push(@python, "#!/usr/bin/python2.7 -u\n");
	   
	   # Blank lines & Comments
	   } elsif ($line =~ /^\s*#/ || $line =~ /^\s*$/) {
		   push(@python, $line);
		   
		# Variables
	   } elsif ($line =~ /^\s*(my )?[\$](.*) = (.*);$/) {
	      
	      my $varName = $2;
         my $value = $3;
	      
	      if ($value =~ /STDIN/i) {
	         $value =~ s/$value/sys.stdin.readline()/
	         
	      } else {
	         $value =~ tr/$//d;
	      }
	      
	      push(@python, "$varName = $value\n");
      
      # Print
      } elsif ($line =~ /^\s*print/) {
         
         # Remove semi-colon
         $line =~ tr/;//d;
         
         # Remove \n
         if ($line =~ /\n/) {
            
            # Remove lines that only print newline
            if ($line =~ /^\s*print\s*"\\n"$/) {
               next;
            
            # Remove newline that is appended after scalars
            } elsif ($line =~ /, "\\n"/) {
               $line =~ s/, "\\n"//g;
            
            # Remove newline from end of a string
            } elsif ($line =~ /\\n"$/) {
               $line =~ s/\\n"/"/g;
            }
         }
         
         # We don't need quotations if there is only one scalar
         if ($line =~ /"\$([\w\d_]*)\s*"$/) {
            $line =~ s/"//g;
         }
         
         # Print with many variables
         
         # Remove $ from scalars
         $line =~ tr/$//d;
         
         push(@python, "$line");
      
      # Loops   
      } elsif ($line =~ /^\s*(if|while|for|foreach|elsif|else|unless)/) {
         
         # If/while statement
         if ($line =~ /^\s*(if|while)/) {
            $line =~ tr/$()//d;
            $line =~ s/\s*{/:/;
         }
         
         # Elsif/else statements
         
         # For loop
         if ($line =~ /^\s*for/) {
         
         }
         
         # Foreach loop
         
         push(@python, $line);
         
         # Now we want to put the rest of the block into an array
         my $indent_count = 1;
         my @block;
         while ($indent_count != 0) {
            $line = shift @convert;
            push(@block,$line);
            if ($line =~ /{/) {
               $indent_count += 1;
            } elsif ($line =~ /}/) {
               $indent_count -= 1;
            }
         }
         foreach my $i (@block) {
               print "BLOCK: $i";
            }
      
      } else {
	
		   # Lines we can't translate are turned into comments
		
		   push(@python,"# $line");
      }
   }
   return @python;
}

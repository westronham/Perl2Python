#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

if (@ARGV == 1) {
   open (my $fh, "<", $ARGV[0]) or die "Can't open $ARGV[0]\n";
   my @file = <$fh>;
   my @python = conversion(0, @file);
   foreach my $i (@python) {
      print $i;
   }
} elsif (@ARGV == 0) {
   my @stdin = <>;
   my @python = conversion(0, @stdin);
   foreach my $i (@python) {
      print $i;
   }
} else {
   die "Either 0 or 1 arguments";
}

my @python;

sub conversion {
   my ($indent_count, @convert) = @_;
   
   for (my $i = 0; $i <= $#convert; $i++) {
      
      # #! line
      if ($convert[$i] =~ /^#!\//) {
         $convert[$i] =~ s/^\s+//;
		   push(@python, "\t" x $indent_count . "#!/usr/bin/python2.7 -u\n");
	   
	   # Blank lines & Comments
	   } elsif ($convert[$i] =~ /^\s*#/ || $convert[$i] =~ /^\s*$/) {
		   push(@python, "\t" x $indent_count . $convert[$i]);
		   
		# Constants
		} elsif ($convert[$i] =~ /^\s*use constant (.*) => (.*);$/i) {
         my $constant = uc $1;
		   push(@python, "\t" x $indent_count . "$constant = $2\n");
		
		# Variables
	   } elsif ($convert[$i] =~ /^\s*(my )?[\$](.*) = (.*);$/) {
	      
	      my $varName = $2;
         my $value = $3;
	      
	      if ($value =~ /STDIN/i) {
	         $value =~ s/$value/sys.stdin.readline()/;
	         splice(@python, 1, 0, "import sys\n");
	         
	      } else {
	         $value =~ tr/$//d;
	      }
	      
	      $convert[$i] =~ s/^\s+//;
	      push(@python, "\t" x $indent_count . "$varName = $value\n");
      
      # Print
      } elsif ($convert[$i] =~ /^\s*print/) {
         # Remove semi-colon
         $convert[$i] =~ tr/;//d;
         
         # Remove \n
         if ($convert[$i] =~ /\n/) {
            
            # Remove lines that only print newline
            if ($convert[$i] =~ /^\s*print\s*"\\n"$/) {
               next;
            
            # Remove newline that is appended after scalars
            } elsif ($convert[$i] =~ /, "\\n"/) {
               $convert[$i] =~ s/, "\\n"//g;
            
            # Remove newline from end of a string
            } elsif ($convert[$i] =~ /\\n"$/) {
               $convert[$i] =~ s/\\n"/"/g;
            }
         }
         
         # We don't need quotations if there is only one scalar
         if ($convert[$i] =~ /"\$([\w\d_]*)\s*"$/) {
            $convert[$i] =~ s/"//g;
         }
         
         # Print with many variables
         
         # Remove $ from scalars
         $convert[$i] =~ tr/$//d;
         
         $convert[$i] =~ s/^\s+//;
         push(@python, "\t" x $indent_count . "$convert[$i]");
      
      # Loops   
      } elsif ($convert[$i] =~ /^\s*(if|while|for|foreach|elsif|else|unless)/) {
         
         # If/while statement
         if ($convert[$i] =~ /^\s*(if|while)/) {
            $convert[$i] =~ tr/$()//d;
            $convert[$i] =~ s/\s*{/:/;
         }
         
         # Elsif/else statements
         
         # For loop
         if ($convert[$i] =~ /^\s*for/) {
         
         }
         
         # Foreach loop
         
         # Change string comparison operators to make them compatible with Python
         $convert[$i] =~ s/ eq / == /;
         $convert[$i] =~ s/ ne / != /;
         $convert[$i] =~ s/ gt / > /;
         $convert[$i] =~ s/ lt / < /;
         $convert[$i] =~ s/ ge / >= /;
         $convert[$i] =~ s/ le / <= /;
         
         $convert[$i] =~ s/^\s+//;
         push(@python, "\t" x $indent_count . $convert[$i]);
         
         # Now we want to put the rest of the block into an array
         my $block_count = 1;
         my @block;
         while ($block_count > 0) {
            $i++;
            push(@block, $convert[$i]);
            if ($convert[$i] =~ /{/) {
               $block_count++;
            } elsif ($convert[$i] =~ /}/) {
               $block_count--;
            }
         }
         
         $indent_count++;
         $convert[$i] =~ s/^\s+//;
         push(@python, conversion($indent_count, @block));
         $indent_count--;
         
      # last
      } elsif ($convert[$i] =~ /^\s*last/) {
         $convert[$i] =~ s/last/break/;
         $convert[$i] =~ tr/;//d;
         $convert[$i] =~ s/^\s+//;
         push(@python, "\t" x $indent_count . "$convert[$i]");
      
      # next
      } elsif ($convert[$i] =~ /^\s*break/) {
         $convert[$i] =~ s/next/continue/;
         $convert[$i] =~ tr/;//d;
         $convert[$i] =~ s/^\s+//;
         push(@python, "\t" x $indent_count . "$convert[$i]");
         
      # Chomp
      } elsif ($convert[$i] =~ /^\s*chomp (.*);$/) {
         my $chomp_var = $1;
         $chomp_var =~ tr/$//d;
         push(@python, "\t" x $indent_count . "$chomp_var = $chomp_var.rstrip()\n");
      
      } else {
	
		   # Lines we can't translate are turned into comments
		   if ($convert[$i] !~ /}/) {
		      $convert[$i] =~ s/^\s+//;
		      push(@python,"\t" x $indent_count . "# $convert[$i]");
	      }
      }
   }
   return @python;
}

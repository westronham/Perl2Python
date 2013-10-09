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
my $sys_flag = 0;

sub conversion {
   my ($indent_count, @convert) = @_;
   
   for (my $i = 0; $i <= $#convert; $i++) {
      
      # #! line
      if ($convert[$i] =~ /^#!\//) {
		   $convert[$i] = "#!/usr/bin/python2.7 -u\n";
	   
	   # Blank lines & Comments
	   } elsif ($convert[$i] =~ /^\s*#/ || $convert[$i] =~ /^\s*$/) {
		   
		# Constants
		} elsif ($convert[$i] =~ /^\s*use constant (.*) => (.*);$/i) {
         my $constant = uc $1;
		   $convert[$i] = "$constant = $2\n";
		
		# Variables
	   } elsif ($convert[$i] =~ /^\s*(my )?[\$](.*) = (.*);$/) {
	      
	      my $varName = $2;
         my $value = $3;
	      
	      if ($value =~ /STDIN/i) {
	         $value =~ s/$value/sys.stdin.readline()/;
	         if (!$sys_flag) {
	            splice(@python, 1, 0, "import sys\n");
	            $sys_flag = 1;
            }
	         
	      } else {
	         $value =~ tr/$//d;
	      }
	      
         $convert[$i] = "$varName = $value\n";
      
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
      
      # Loops   
      } elsif ($convert[$i] =~ /^\s*(if|while|for|foreach|elsif|else|unless)/) {
         
         # If the statement begins with a }, push everything after to the next line and continue on
         #if ($convert[$i] =~ /^\s*}\s*(elsif.*)$/ || $convert[$i] =~ /^\s*}\s*(else.*)$/) {
         #   print "$1\n";
          #  splice(@convert, $i, 1, "}\n");
          #  splice(@convert, $i + 1, 0, "$1\n");
         #}
         # If/while statement
         if ($convert[$i] =~ /^\s*(if|while|elsif|else)/) {
            $convert[$i] =~ tr/$()//d;
            $convert[$i] =~ s/\s*{/:/;
         
         } elsif ($convert[$i] =~ /^\s*\}?\s*(elsif|else)/) {
            $convert[$i] =~ tr/$()//d;
            $convert[$i] =~ s/\s*{/:/;
            $convert[$i] =~ s/elsif/elif/;
         }
         
         # For loop
         if ($convert[$i] =~ /^\s*for/) {
         
         }
         
         # Foreach loop
         if ($convert[$i] =~ /^\s*foreach\s*\$(.*?)\s*\((.*?)\)/) {
            my $foreach_variable = $1;
            my $foreach_range = $2;
            if ($foreach_range =~ /\@ARGV/) {
               $foreach_range = 'sys.argv[1:]';
            } elsif ($foreach_range =~ /^(\d)\.\.(\d)$/) {
               my $xrange_end = $2 + 1;
               $foreach_range = "xrange($1, $xrange_end)";
            } elsif ($foreach_range =~ /^(0)\.\.\$\#(.*)$/) {
               my $looped_array = $2;
               if ($looped_array =~ /^ARGV$/) {
                  $looped_array = "sys.argv";
                  if (!$sys_flag) {
                     splice(@python, 1, 0, "import sys\n");
                     $sys_flag = 1;
                  }
               }
               $foreach_range = "xrange(len($looped_array) - 1)"
            }
            
            $convert[$i] = "for $foreach_variable in $foreach_range:\n";
         }
         
         # Change string comparison operators to make them compatible with Python
         $convert[$i] =~ s/ eq / == /;
         $convert[$i] =~ s/ ne / != /;
         $convert[$i] =~ s/ gt / > /;
         $convert[$i] =~ s/ lt / < /;
         $convert[$i] =~ s/ ge / >= /;
         $convert[$i] =~ s/ le / <= /;
         
         $convert[$i] =~ s/^\s+//;
         push(@python, "\t" x $indent_count . "$convert[$i]");
         
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
         conversion($indent_count, @block);
         $indent_count--;
         
      # last
      } elsif ($convert[$i] =~ /^\s*last/) {
         $convert[$i] =~ s/last/break/;
         $convert[$i] =~ tr/;//d;
         $convert[$i] =~ s/^\s+//;
      
      # next
      } elsif ($convert[$i] =~ /^\s*break/) {
         $convert[$i] =~ s/next/continue/;
         $convert[$i] =~ tr/;//d;
         $convert[$i] =~ s/^\s+//;
         
      # Chomp
      } elsif ($convert[$i] =~ /^\s*chomp (.*);$/) {
         my $chomp_var = $1;
         $chomp_var =~ tr/$//d;
         $convert[$i] = "$chomp_var = $chomp_var.rstrip()\n";
      
      # Lines we can't translate are turned into comments
      } else {
         $convert[$i] = "# $convert[$i]";
      }
      
      # Other stuff that applies to any kind of line
      if ($convert[$i] =~ /\@ARGV/) {
         $convert[$i] =~ s/\@ARGV/sys\.argv\[1\:\]/;
         if ($sys_flag == 0) {
            splice(@python, 1, 0, "import sys\n");
            $sys_flag = 1;
         }
      }
      
      if ($convert[$i] =~ /ARGV/) {
         if ($convert[$i] =~ /\@ARGV/) {
            $convert[$i] =~ s/\@ARGV/sys\.argv\[1\:\]/;
         } elsif ($convert[$i] =~ /ARGV\[(.*?)\]/) {
            my $variable = $1;
            $convert[$i] =~ s/ARGV\[.*?\]/sys.argv\[$variable + 1\]/;
            $convert[$i] =~ tr/"//d;
         }
         
         if (!$sys_flag) {
            splice(@python, 1, 0, "import sys\n");
            $sys_flag = 1;
         }
      }
      
      # Check for a join (To-DO)
      if ($convert[$i] =~ /print join\((.*?),\s*(.*?)\)/) {
         $convert[$i] =~ s/join\((.*?),\s*(.*?)\)/$1.join\($2\)/;
      }
      
      # Writing the transformed line to our Python array
      if ($convert[$i] =~ /^\s*#?\s*}\s*/) {
         next;
      }
      if ($convert[$i] !~ /^\s*$/) {
         $convert[$i] =~ s/^\s+//;
      }
      push(@python, "\t" x $indent_count . "$convert[$i]");
   }
   return @python;
}

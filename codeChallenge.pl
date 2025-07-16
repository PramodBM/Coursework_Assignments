#!/usr/bin/perl 

# Author   : Pramod Mayigowda
# Function : This perl script is used to get the  
#	     overlaps in the bed files.
#	     Only 100% overlaps are reported in 
#	     result file. This was a task in 
#	     Programming for Bioinformatics course
#            at Georgia Tech which was supposed to
# 	     be optimised to run in as less time as
#            possible. Time to beat was 11s.
#	     Time set by Dr.Andrew Conley TA of this 
#	     course (FALL 2012)

# Output   : An overlap is printed only once.
#	     My code taked 16s to run in the cluster
#            ~19s on my laptop.
#            The winner was one of my classmates whose
#            code ran in 7s

use strict;
use warnings;

@ARGV or die "No input file specified ==> <usage> perl codeChallenge.pl TE.bed Intron.bed ";

my %intronHashRef;
my $intronHashRef;
my $intronChromosomes;  
my $intronStart;
my $intronEnd;
my $i=0;
my $loop=0;
my $prevEnd=0;
my $prevChr="C" ; # Random initialization


# Opening and reading the Intron file line by line 
open my $intronFile, '<',$ARGV[1] or die "Unable to open input file: $!";
while (<$intronFile>) { 
	chomp $_; # remove whitespaces
	my @intronLine = split "\t", $_;
	$intronChromosomes = $intronLine[0];  
	$intronStart = $intronLine[1];
	$intronEnd = $intronLine[2];
		 
	#push the Chromosome,Start and End to a Hash reference
	push @{ $intronHashRef{$intronChromosomes} },[$intronChromosomes, $intronStart, $intronEnd]; 
	 	
 }
close $intronFile; # Close the file after reading all the lines


open my $teFile,'<', $ARGV[0] or die "Unable to open input file: $!";
while (my $line = <$teFile>) 
{
	#chomp($line);   
	my @teLine = split(/\t/,$line);   
   	my $teChromosomes = $teLine[0];
    	my $teStart = $teLine[1];
    	my $teEnd = $teLine[2];
	
	if ($teChromosomes ne $prevChr)
	{
		$loop =0; # start the loop from 0 is there is change in chromosome
	}
	
	$prevChr = $teChromosomes;	
	Chromosome: for($i=$loop; $i<=$#{$intronHashRef{$teChromosomes}}; $i++ )
	{
		if ($intronHashRef{$teChromosomes}[$i][2] > $prevEnd)
		{
			$loop = $i; # Start the comparison from $i if the current end is greater than previous		
		}
 		$prevEnd = $intronHashRef{$teChromosomes}[$i][2];
		
		if ($intronHashRef{$teChromosomes}[$i][1] > $teStart)
		{
			last Chromosome; #start from loop if the intron Chromosome start is greater than intron
		}
		
		
		if (($intronHashRef{$teChromosomes}[$i][2] >= $teEnd) && ($intronHashRef{$teChromosomes}[$i][1] <= $teStart))
		{
        		print join("\t",@teLine); #print if there is a overlap
			last Chromosome; # start loop because it is enough if the overlap is printed once				
		}	
		
	}
} 

close $teFile;



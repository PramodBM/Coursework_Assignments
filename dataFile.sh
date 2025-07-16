#!/bin/bash

# Author   : Pramod Mayigowda
# Function : This bash script is used to as to run the
#	     assemblyPipeline.sh shell script. This 
# 	     script is a prototype of my work. Necessary 
#	     modifications are made not to include all 
#	     the details. 
#	     This script needs assemblyPipeline.sh to be
#	     in the same directory or necessary changes
# 	     can be made in the command variable in the
#  	     end of this script

# Output   : All the outputs are generated from main script

referenceFasta="/Path_to_reference_fasta_file"; # used to run ABACAS
emblFolder="/tmp"; # folder of embl annotations
iterationEnd=10; # Default is 10 it can be changed

# These values were fixed after running trials on few of our strains
kmerStart=35;
kmerEnd=95;
kmerIncrements=5; 

# The values for strainName,readOne and readTwo were set from another file which had a list of 
# 40 read files using a for loop which I have not included here,
strainName="strain1"; #Used as the name for working sirectory, also contigs , scaffolds and annotations
readOne="read1_1.fastq";
readTwo="read1_2.fastq";
command="bash assemblyPipeline.sh $strainName $readOne $readTwo $referenceFasta $emblFolder $iterationEnd $kmerStart $kmerEnd $kmerIncrements";
eval $command;

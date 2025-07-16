#!/bin/bash

# Author   : Pramod Mayigowda
# Function : This bash script is used to as to 
#	     Assemble Illumina paired end reads
#	     using velvet(veletoptimiser).
# 	     I have used Runs IMAGE for gap filling, 
#	     ABACAS for ordering the scaffolds and
#	     RATT for annotating the ordered scaffolds 
#	     Necessary modifications are made not 
#	     to include all the details.

# Output   : There are folders created using each 
#	     strain name, which has outputs from
#	     Velvet optimiser  IMAGE ABACAS and RATT 
#            StrainName_OrderedScaffolds.fa is the 
#	     final assembled set of contigs

#Usage and other checks 
if [ "$#" -ne 9 ]; then
  echo "Usage: $0 sampleName> <Read File1 in fastq format> <Read File2 in fastq format> <Reference Fasta File for Abacas> <EMBL folder with annotations for RATT> <Image_iterationEnd> <Vel Optimiser Kmer Start> <Vel Optimiser Kmer End> <Vel Optimiser Kmer increments>" >&2
  echo "Strain Name is used to create a working directory, name contigs, scaffolds and annotation results" >&2
  exit 1
fi

exec &> $1.StdOp.Err.txt; #Redirect the stdout and stderror to a text file

if ! [ -d "$5" ]; then
  echo "$5 is not a directory" >&2
  exit 1
fi


# Assign arguments to variables, 
strainName=$1; #Used as the name for working sirectory, also contigs , scaffolds and annotations
readOne=$2;
readTwo=$3;
referenceFasta=$4;
workingDirectory=`pwd`;
emblFolder=$5;
iterationEnd=$6; 
kmerStart=$7;
kmerEnd=$8;
kmerIncrements=$9;


#make working directories for running V.O, Image, Abacas, Ratt
mkdir $workingDirectory/$strainName;
mkdir $workingDirectory/$strainName/velvetOptimiser;
mkdir $workingDirectory/$strainName/image;
mkdir $workingDirectory/$strainName/abacas;
mkdir $workingDirectory/$strainName/ratt;


# Velvet optimiser begins here

cd $workingDirectory/$strainName/velvetOptimiser;

# Run Velvetoptimiser to assemble the Illumina MiSeq Paired end reads
# Takes Paired  end Reads, Kmer start and end as the input, 
# Needs velvet( velveth and velvetg ) to be installed and in path
echo "Running Velvet-optimiser..."
runVelvetOpt="perl /path_to_velvetoptimiser_script/VelvetOptimiser.pl -s $kmerStart -e $kmerEnd -x $kmerIncrements -f '-fastq -shortPaired $readOne $readTwo' > $strainName.txt";
eval $runVelvetOpt;

mkdir auto_data_79; #for testing.. #
touch $workingDirectory/$strainName/velvetOptimiser/auto_data_79/contigs.fa; #for testing...#

# velvet creates a directory with name of optimal kmer and creates all file in the same
# here i am checking if the contigs.fa file exists or not 

# NOTE : actual checks were made to see if there is some data in file using "-s"
if [ ! -f "$workingDirectory/$strainName/velvetOptimiser/auto_data_79/contigs.fa" ]; then
  echo "Velvet optimiser did not run correctly. The contifs.fa file does not exist" >&2
  exit 1
fi

echo "Velvet-optimiser ran successfully!!!";

#Copy the resulting contigs file to image directory
cp $workingDirectory/$strainName/velvetOptimiser/auto_data*/contigs.fa /$workingDirectory/$strainName/image;




#image begins here
cd $workingDirectory/$strainName/image;

# soft link to the read files, image needs them to be in Name_1.fastq and Name_2.fastq format here Name is the 
ln -s $2 $1_1.fastq;
ln -s $3 $1_2.fastq;

# selecting the kmer size from the directory created for use in image run
kmerDirectory=$workingDirectory/$strainName/velvetOptimiser/auto_data*;
kmerNum=`find $kmerDirectory -type d -printf '%f'`;
kmerSize=`echo ${kmerNum##*_}`;


# All the input files should be in $workingDirectory/$strainName/image for image to run successfully
echo "Running image...";
runImage="perl /Path_to_image_script/image.pl -scaffolds $workingDirectory/$strainName/image/contigs.fa -prefix $strainName -iteration 1 -all_iteration $iterationEnd -dir_prefix itr -kmer $kmerSize -smalt_minscore 141 -vel_ins_len 500 2> $strainName.StdOut";
eval $runImage;


mkdir itr$iterationEnd; #for testing...
touch $workingDirectory/$strainName/image/itr$iterationEnd/new.fa $workingDirectory/$strainName/image/itr$iterationEnd/new.read.placed; #for testing...

# NOTE : actual checks were made to see if there is some data in file using "-s"
if [ ! -f "$workingDirectory/$strainName/image/itr$iterationEnd/new.fa" ]; then
  echo "Image did not run correctly" >&2
  exit 1
fi

echo "Image ran successfully!!!";

# Convert the contigs in final run to bigger scaffolds
convertContigs2Scaffolds="perl /Path_to_script/contigs2scaffolds.pl $workingDirectory/$strainName/image/itr$iterationEnd/new.fa $workingDirectory/$strainName/image/itr$iterationEnd/new.read.placed 300 500 $1_scaffolds";
eval $convertContigs2Scaffolds;

touch $workingDirectory/$strainName/image/$1_scaffolds.fa #for testing...

# NOTE : actual checks were made to see if there is some data in file using "-s"
if [ ! -f "$workingDirectory/$strainName/image/$1_scaffolds.fa" ]; then
  echo "Error when creating the scaffolds file" >&2
  exit 1
fi

echo "Scaffolds file created !!!";

#Copy the resulting scaffolds to abacas directory
cp $workingDirectory/$strainName/image/$1_scaffolds.fa $workingDirectory/$strainName/abacas;




#Abacas run begins here
cd $workingDirectory/$strainName/abacas;
echo "Running abacas...";
runAbacas="perl /Path_to_Scrit/abacas.pl -b -m -r $referenceFasta -q /$workingDirectory/$strainName/abacas/$1_scaffolds.fa -p nucmer -o $1mapped";
eval $runAbacas;

touch "$workingDirectory/$strainName/abacas/$1mapped.contigsInbin.fas"; #for testing...

# NOTE : actual checks were made to see if there is some data in file using "-s"
if [ ! -f "$workingDirectory/$strainName/abacas/$1mapped.contigsInbin.fas" ]; then
  echo "Abacas did not run correctly" >&2
  exit 1
fi

cat $1mapped.contigsInbin.fas $1mapped.MULTIFASTA.fa > $1_OrderedScaffolds.fa;

echo "Abacas ran successfully!!!";


cp $workingDirectory/$strainName/abacas/$1_OrderedScaffolds.fa $workingDirectory/$strainName/ratt;

#RATT run begins here
cd $workingDirectory/$strainName/ratt;
echo "Running RATT...";
runRatt="bash /Path_to_Script/start.ratt.sh $emblFolder $workingDirectory/$strainName/ratt/$1_OrderedScaffolds.fa $1_Annotations Strain > $1_ratt.output.txt";
eval $runRatt;

# cannot check the successful run of RATT need to check it manually because it creates 
# a lot of files and it can be verified only manually




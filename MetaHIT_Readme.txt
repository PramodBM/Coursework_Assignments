~~~~~~~~~~~~~~~~~AIM~~~~~~~~~~~~~~~~~

MetaHIT download
The goal is to create a workflow that will:
create a folder hierachy such as:
 MetaHIT/
 spanish/
 healthy/
 UC/
 CD/
 danish/
 healthy/

download the MetaHIT cohort
Viome take-home challenge
Dataset description
Accessing the data
Project instructions
Include the following capabilites:
dryrun mode
all samples can be downloaded from file (i.e., nbt.2939-S2.csv or whatever you
like)
single sample download
email a log file to a specified email



~~~~~~~~~~~~~~~~~Run Instructions~~~~~~~~~~~~~~~~~
The assignment.py script was created using python3 and we should be able to execute it with version 3.6.4 and up.
It is tested on both 3.6.4 and 3.8.10

[Python script argument description]
To run the script, we need the following arguments if not it will fail and does not log or send email.
'python3 assignment.py -m <Full_path_to/nbt.2939-S2.csv> -d <Full_path_to/ERP002061.csv> -b <base_directory> -r <run_mode>'
 -m is the metadata file which has list of sample ids and metadata related to health status and nationality
 -d has a bunch of metadata related in Eurpean National Archive related to study and FTP to the fastq files 
 -b is the base directory where we want to download the samples. If does not exist, the script will create this.Inside this we will find the following directories and sub-directories.
 	MetaHIT/
 		spanish/
 			healthy/
 			UC/
 			CD/
            healthy_relative/
 		danish/
 			healthy/
-r is the run mode with options of dry_run, user_run, single_run as options

[Assumptions or Requirements]
1. The "Sample ID" column in nbt.2939-S2.csv file has some IDs which have O2.UC36.2 in ID whereas the files are named "O2.UC36-2_20100106.rmhost.pair.1.fq.gz". The last "period" symbol was replaced with "-" to enable string matching.So, searching with O2.UC36.2 will fail to grep this file. Instead I am searching with "O2.UC36-2"
2. I am using the "submitted_ftp" contains part of the "Individal ID" in file name. These 2 fields are used for matching and corresponding "fastq_ftp" is passed to the download function.
3. The complete path of both input files({full_path}/nbt.2939-S2.csv and {full_path}/ERP002061.csv) should be provided, this is to avoid copying them to work directory and duplicating. I change working diectory while downloading fastq files, just giving the input filenames will result in error.
4. There is at least 1 Sample Id and it has at least 1 fastq file entry in ERP002061.csv


[Dry run mode]
1. In dry run mode, first 3 Sample IDs and all their fastqs are downloaded and then deleted at the end
2. These events will be logged

[Single run mode]
1. In a single run mode, first  Sample ID and all its fastq files are downloaded

[User run mode]
1. In User run mode, by default 10 Sample IDs and all their fastq files are downloaded
2. This is done to save space on local machine. This can be simply changed to 397 in python script for current input file since it has 396 Sample IDs or total rows

[Dry run mode]
1. This is created to check all features of code.
2. It runs every feature including downloading files to relevant directory.
3. At the end of download, the files are deleted.
4. All these are logged into a log file.

[Input argument Validation]
1. This script has stringent argument validation where we need exactly 6 arguments to run the script from command line. This can be relaxed with minor modifications if need be.
2. It validates the path and if the filesize is more than 0 for nbt.2939-S2.csv and ERP002061.csv files
3. The working or base directory will be created if it already doesn't exist

[Logging Feature]
1. Logging feature uses Logging python library and it currently logs the info after critical milestones
2. Logs are timestamped
2. This can be expanded to add stderr and stdout (Not added to make it more readable)

[Email Feature]
1. I created a gmail account() to send mails to any users. The password is in the python script.
2. The access setting was changed to allow less secure apps setting to send mails using SMTP.
3. There are other servers which help us perform similar functionality but, this is the easier and faster method to send emails via gmail SMTP.
4. Emails can be sent to more than one account by creating a list of emails shown in a commented section.
5. There is an attachment limit of 25 Mb from google servers.
6. Email is sent only on a successful run, if there is any error in process it is printed on command line.
7. Please change the "to_address" to include desired email id(s), refer to Line 15 and Line 16 of assignment.py script.

[Download Feature]
1. The download function uses wget, here the input needs to be modified a bit to add "ftp://" in order to download from the FTP server.
2. The samples are downloaded to corresponding nationality and health status directories.
3. In Dry run mode, the downloaded files are deleted.

[Library requirements]
1. Most of the libraries are standard and were installed by default.
2. In case any library is missing, we can do pip3 install {library_name} in most cases.
3. I had to pip3 install wget on my Virtual Machine.

[Example commands]
1. python3 assignment.py -m /home/genomics/Pramod/run/nbt.2939-S2.csv -d /home/genomics/Pramod/run/ERP002061.csv -b /home/genomics/Pramod/run -r dry_run
2. python3 assignment.py -m /home/genomics/Pramod/run/nbt.2939-S2.csv -d /home/genomics/Pramod/run/ERP002061.csv -b /home/genomics/Pramod/run -r single_run
3. python3 assignment.py -m /home/genomics/Pramod/run/nbt.2939-S2_10samples.csv -d /home/genomics/Pramod/run/ERP002061.csv -b /home/genomics/Pramod/run -r user_run

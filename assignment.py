#!/usr/bin/env python3

import sys, getopt, os
import logging
import smtplib
import csv
import wget
from os.path import basename
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication

from_address = 'example@gmail.com'
from_password = 'randomPwd'
to_address = ['example@gmail.com'] # List of recipients
log_file_name = "Logs.txt"
log_file = os.path.join(os.getcwd(), log_file_name) # Log file is created in the directory where the script is run from or current working directory

# Creating and configuring logger
logging.basicConfig(filename=log_file, format='%(asctime)s %(message)s', filemode='w')
# Object creation
logger = logging.getLogger()
# Set the threshold of logger to INFO
logger.setLevel(logging.INFO)
logger.info("Starting to Log")


# function to download requested files from FTP server
def download_fastq(fq_ftp_url, download_dir, download_mode):
    fq_ftp = fq_ftp_url
    download_directory = download_dir
    mode_of_download = download_mode
    del_download = ""
    if mode_of_download == "dry_run":
        del_download = "yes"

    if os.path.exists(download_directory):
        logger.info("The working directory %s already exists", download_directory)
    else:
        os.makedirs(download_directory)
        logger.info("The working directory %s is now created", download_directory)

    os.chdir(download_directory)

    for f in enumerate(fq_ftp.split(";")):  # Splitting the filenames if need be since some are paired and separated by ";"
        fq_download = "ftp://" + f[1]
        logger.info("Downloading %s to %s",fq_download, download_directory)
        wget.download(fq_download)
        logger.info("Download %s is successful", fq_download)

        if del_download == "yes": # This is only for dry run mode
            os.remove(os.path.basename(fq_download))
            logger.info("Deleting %s since the run mode is set to dry_run", fq_download)


# function to read sample metadata
def read_metadata(metadata, file_download_path, base_dir, run_mode):
    sample_metadata = metadata
    fastq_path = file_download_path
    work_directory = base_dir
    mode = run_mode
    logger.info("SampleID metadata file is %s", metadata)
    logger.info("Fastq file path for download is in file %s", fastq_path)
    logger.info("Base working directory is %s", work_directory)
    logger.info("Run mode for this run is %s", mode)

    data_directory = os.path.join(work_directory, "MetaHIT")

    # read the metadata file
    with open(sample_metadata, mode='r') as md_csv:
        csv_reader = csv.DictReader(md_csv)
        md_line_count = 0
        for md_line in csv_reader:
            if md_line_count == 0:
                md_line_count += 1 # Reading Header

            # some sample IDs cannot be used for matching fastq files for download, so replacing those which contains "." with "-"
            sample_id = md_line["Sample ID"]
            special_char = "."
            if special_char in sample_id:
                last_char_index = sample_id.rfind(".")
                new_sample_id = sample_id[:last_char_index] + "-" + sample_id[last_char_index + 1:]
            else:
                new_sample_id = sample_id

            nationality = md_line["Nationality"]
            status = md_line["Health Status"]

            if status == "Healthy":
                health_status = 'healthy'
            elif status == "Crohns disease":
                health_status = 'CD'
            elif status == "Ulcerative colitis":
                health_status = 'UC'
            elif status == "Healthy relative":
                health_status = 'healthy_relative'
            else:
                health_status = "Unknown"

            final_work_directory = os.path.join(data_directory, nationality, health_status)

            with open(file_download_path, mode='r') as fq_path:
                csv_reader_fq = csv.DictReader(fq_path, delimiter="\t")
                line_count_fq = 0
                for lineFq in csv_reader_fq:
                    if line_count_fq == 0:
                        line_count_fq += 1  # Reading Header
                    ftp_link = lineFq["submitted_ftp"]  # Downloading files from Submitted_FTP column

                    if new_sample_id in ftp_link: # match with submitted_ftp and get its corresponding fastq ftp link
                        ftp_fastq = lineFq["fastq_ftp"]
                        logger.info("The Sample Id %s has the following fastq file(s) %s and its submitted ftp link is %s", new_sample_id, ftp_fastq, ftp_link)
                        download_fastq(ftp_fastq, final_work_directory, mode)
                    line_count_fq += 1

            md_line_count += 1

            if mode == "single_run" and md_line_count == 2:  # count 2 for single run since 1st row is header
                logger.info("This is a single-run mode and only files related to %s will be downloaded", new_sample_id)
                return
            elif mode == "user_run" and md_line_count == 11: # count set to 11 for user run since 1st row is header and we want 10 samples
                logger.info("This is a user-run mode and its configured to download 10 Sample Ids which can have multiple fastq files")
                return
            elif mode == "dry_run" and md_line_count == 4: # count set to 4 for dry run since 1st row is header and we want 3 samples
                logger.info("This is a dry-run mode and its configured to download 3 Sample Ids which can have multiple fastq files")
                return


# function where emailing the log files is defined
def email_the_logs(log_attachment):
    # Creating the email content
    subject = 'Downloading data from study ERP002061'
    content = 'This email contains detailed logs of files downloaded from Sample Ids in nbt.2939-S2.csv'
    msg = MIMEMultipart()
    msg['from'] = from_address
    recipients = to_address
    # Checking if there are multiple recipient emails
    if len(recipients) > 1:
        msg['to'] = ", ".join(recipients)

    else:
        msg['to'] = recipients[0] # assigning 1st element in list

    msg['subject'] = subject
    body = MIMEText(content, 'plain')
    msg.attach(body)

    # Please note that gmail has an attachment size limit of 25 Mb.
    logs_file = log_attachment
    logger.info("In email attachment function and ready to send email")
    with open(logs_file, 'r') as f_attachment:
        # MimeApplication is currently used in way that it can read text files and most unzipped files including fastq
        file_attachment = MIMEApplication(f_attachment.read(), Name=basename(logs_file))
        file_attachment['Content-Disposition'] = 'file_attachment; file_attachment="{}"'.format(basename(logs_file))
    # Adding attachment to email
    msg.attach(file_attachment)

    try:
        # Gmail smtp config instantiation
        server = smtplib.SMTP_SSL("smtp.gmail.com", 465)
        # Logging to google smtp server with credentials
        server.login(from_address, from_password)
        # Sending the email with logs
        server.send_message(msg, from_addr=from_address, to_addrs=to_address)
        # Ending the server instantiation
        server.quit()
        print('Email sent to', to_address)
    except Exception as e:
        print(e) # Prints the exception on terminal


def main(argv):

    logger.info("Validating command line arguments")

    # validating the arguments from commandline
    try:
        opts, args = getopt.getopt(argv, "hm:d:b:r:")
    except getopt.GetoptError:
        print('Invalid argument(s) passed, we need')
        print('python3 assignment.py -m <Full_path_to/nbt.2939-S2.csv> -d <Full_path_to/ERP002061.csv> -b <base_directory> -r <run_mode>')
        print('Run mode has only 3 options - dry_run, user_run, single_run')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('Pass the following arguments to run:-')
            print('python3 assignment.py -m <Full_path_to/nbt.2939-S2.csv> -d <Full_path_to/ERP002061.csv> -b <base_directory> -r <run_mode>')
            print('Run mode has only 3 options - dry_run, user_run, single_run')
            sys.exit()
        elif opt in "-m":
            # check if the nbt.2939-S2.csv metadata file exists and is valid
            if os.path.exists(arg) and os.path.getsize(arg) > 0:
                metadata = arg
                logger.info("Input Metadata file exists and is validated")
            else:
                print('There is an issue with with metadata file passed, it is empty or it does not exist')
                sys.exit()
        elif opt in "-d":
            # check if the ERP002061.csv file exists and is valid
            if os.path.exists(arg) and os.path.getsize(arg) > 0:
                file_download_path = arg
                logger.info("File which has Fastq and other metadata download path exists and is validated")
            else:
                print('There is an issue with with fastq paths file passed, it is empty or it does not exist')
                sys.exit()
        elif opt in "-b":
            if os.path.exists(arg):
                base_dir = arg
                logger.info("Base directory %s exists", base_dir)
                logger.info("The command line arguments to run assignment.py is validated and ready to run next step")
            else:
                os.mkdir(arg)
                base_dir = arg
                logger.info("Base directory was created since it didn't exist")
                logger.info("The command line arguments to run assignment.py is validated and ready to run next step")
        elif opt in "-r":
            if arg == "dry_run":
                run_mode = arg
            elif arg == "user_run":
                run_mode = arg
            elif arg == "single_run":
                run_mode = arg
            else:
                print('Invalid run mode chosen,please choose one of the 3 options - dry_run, user_run, single_run')

                sys.exit()

        # checking the length of arguments, should not be less or more than 6
        if len(argv) != 8:
            print('Number of arguments passed is incorrect, we need the following')
            print('python3 assignment.py -m <Full_path_to/nbt.2939-S2.csv> -d <Full_path_to/ERP002061.csv> -b <base_directory> -r <run_mode>')
            sys.exit()

    logger.info("Validation of command line arguments is successful")
    # calling the read sample metadata function
    read_metadata(metadata, file_download_path, base_dir, run_mode)

    # calling the email function to email log file after successful run
    email_the_logs(log_file)

# Call main function
if __name__ == "__main__":
    main(sys.argv[1:])

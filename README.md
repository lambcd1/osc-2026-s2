Operating Systems Concepts — Assignment 1
Author Details
Name: Cam Lamb
Student Code: LAMBCD1
Last Updated: 11 September 2026 13:00

The project contains two shell scripts developed for Assignment 1:

Task 1: Automates the creation and configuration of Linux user accounts and their required environments.
Task 2: Creates compressed backups of directories and uploads them to a remote server using SCP over SSH.
Task 1 — User Environment Script
Purpose

The Task 1 script, create_users.sh, automates the creation and configuration of Linux user accounts from a CSV file.

For each user specified in the CSV file, the script can:

Generate a Linux username from the user's email address.
Create the user with a home directory and Bash as the default shell.
Set a default password based on the user's birth date.
Force the user to change their password at first login.
Create secondary groups when they do not already exist.
Add users to their required secondary groups.
Create required shared folders.
Configure shared-folder group ownership and permissions.
Create a shared symbolic link in the user's home directory.
Create the myls alias for users belonging to the sudo group.
Record detailed information about the execution in a log file.

The script is designed to process the CSV provided for the assignment while also reporting errors when required operations cannot be completed.

Prerequisites

The following are required to run the script:

Linux operating system.
Bash shell.
sudo access.
The create_users.sh script.
A valid CSV file containing the required user information.
Commands used by the script, including:
useradd
usermod
groupadd
chpasswd
chage
date
curl when using a remote CSV file
/bin/bash available as the user shell.

The script performs operations that modify system users, groups, home directories and shared folders, so it should be run with an account that has appropriate sudo privileges.

Input CSV Format

The expected CSV format is:

email,birth_date,groups,shared_folder
alice.smith@example.com,1990/06/15,sudo:dev,/opt/staffData
bob.jones@example.com,1985/11/02,dev,/opt/staffData
carol.white@example.com,2000/03/22,intern,/opt/internData
dave.nguyen@example.com,1978/09/30,dev:docker,/opt/staffData

The assignment's users.csv file can be retrieved from the Otago Polytechnic BIT course resources:

Users CSV url: https://osc.op-bit.nz/share/users.csv

Multiple secondary groups are separated using :.

Running the Script

The script can be given a local CSV path as a command-line argument:

./create_users.sh users.csv

A full or relative local path can also be supplied:

./create_users.sh /path/to/users.csv

If no argument is provided, the script prompts for the CSV path or URI:

./create_users.sh

The script asks for confirmation after validating the input and determining how many users need to be created.

Because the script performs system-level changes, sudo may be requested during execution.

Example
./create_users.sh users.csv

The script displays information about each user being processed, confirms the number of users to be added, and then performs the requested account and environment configuration after confirmation.

Logging

Task 1 writes detailed execution information to:

create_users.log

The log records timestamps and important events such as successful operations, skipped existing users and errors.

Task 2 — Directory Backup Script
Purpose

The Task 2 script, backup.sh, creates a gzip-compressed backup of a directory and uploads the resulting archive to a remote server using SCP over SSH.

The script:

Accepts a directory path as an argument or prompts for one.
Validates that the directory exists.
Creates a .tar.gz archive containing the entire directory.
Names the backup using the required date format:
backup-YYYY-MM-DD.tar.gz
Tests the archive to ensure it can be read successfully.
Displays the contents of the archive.
Prompts for the remote server address.
Prompts for the SSH port, defaulting to port 22.
Prompts for the remote username.
Prompts for the remote destination directory.
Checks that the remote server can be reached using SSH.
Checks that the remote destination directory exists.
Uploads the backup using scp.
Verifies that the uploaded backup exists on the remote server.
Records execution details and errors in a log file.
Prerequisites

The following are required:

Linux operating system.
Bash shell.
tar installed.
scp installed.
ssh installed.
Network access to the remote server.
SSH access to the remote server using the supplied username and credentials.
A remote destination directory that already exists and is writable by the remote user.

The script does not create the remote destination directory. The directory must exist before the backup is uploaded.

Running the Script

A directory can be supplied as a command-line argument:

./backup.sh /path/to/directory

For example:

./backup.sh ../task1

If no argument is supplied, the script prompts for the directory:

./backup.sh

The script then asks for the remote connection details:

Enter remote IP address or hostname:
Enter SSH port (press Enter for 22):
Enter remote username:
Enter remote destination directory:
Example Remote Backup

For a remote server using SSH port 22:

Remote host: 192.168.1.100
Remote port: 22
Remote user: kali
Remote directory: /var/assessments/task2

The resulting backup has the format:

backup-2026-09-11.tar.gz

The script uploads the file using SCP:

scp -P 22 backup-2026-09-11.tar.gz \
    kali@192.168.1.100:/var/assessments/task2/

The script then verifies that the backup exists on the remote server.

Backup Verification

The script checks the archive locally using:

tar -tzf backup-YYYY-MM-DD.tar.gz

It also verifies the uploaded file remotely using SSH.

A successful execution ends with:

========================================
BACKUP COMPLETE
========================================
Logging

Task 2 writes detailed execution information to:

backup.log

The log includes timestamps, input information, backup creation results, remote connection results, upload results and errors.

Error Handling

Both scripts perform validation before carrying out their main operations and report errors when operations fail.

Task 1 handles issues such as:

Invalid or missing CSV input.
Invalid email addresses.
Invalid birth dates.
Existing usernames.
Failed user creation.
Failed password configuration.
Failed group creation or assignment.
Failed shared-folder creation.
Failed permission or ownership changes.
Failed symbolic-link creation.
Failed alias creation.

Task 2 handles issues including:

A local directory that does not exist.
An unreachable remote server.
Incorrect SSH authentication.
An invalid or inaccessible remote destination directory.
Failure to create the backup archive.
Failure of the archive integrity check.
Failure to upload the backup.
Failure to verify the uploaded backup.

Errors are displayed to the user and recorded in the appropriate log file.

Testing

The scripts were tested during development using both successful and deliberately invalid inputs.

Task 1
Successful user creation.
Password configuration.
Group assignment.
Shared-folder configuration.
Symbolic-link creation.
myls alias creation.
Error handling.
Task 2
Successful local backup creation.
Archive integrity and contents.
Successful SSH connection.
Successful SCP upload.
Successful remote verification.
Missing local directory.
Unreachable remote server.
Incorrect authentication credentials.
Invalid remote destination directory.

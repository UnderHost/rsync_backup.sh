# rsync_backup.sh:

This bash script is designed to backup files from two source paths to a remote server over SSH using rsync and sshpass. aaPanel backup uses two separate folders for backup: one for databases and the other for files. The script is intended to be run on a regular basis based on a frequency defined in a configuration file or input by the user with aaPanel or any RHEL-based system.

The script first checks for the existence of a configuration file. If found, it reads the backup details from it. If not, the script prompts the user to enter the backup details and saves them to the configuration file for future runs.

The script checks whether sshpass and rsync are installed on both local and remote servers, installing them if necessary. It also checks for sufficient available space on the remote server. If there is not enough space, the backup is aborted, and an email is sent to the specified email address to notify the user.

Finally, the script creates a backup directory on the remote server using the backup frequency and the current date as part of the directory name. It then runs the rsync command to back up the files from the two source paths to the remote server.

# The following variables in the backup.config file must be configured:

source_path_1: the path to the first source directory to be backed up.

source_path_2: the path to the second source directory to be backed up.

destination_ip: the IP address of the remote server where the backup will be stored.

destination_path: the path on the remote server where the backup will be stored.

destination_user: the username to use to connect to the remote server over SSH.

destination_password: the password to use to connect to the remote server over SSH.

email_address: the email address to use for notifications in case of backup failure.

backup_frequency: the frequency of the backup, which can be daily, weekly, or monthly.

# The default aaPanel paths are:

source_path_1: /www/backup/database

source_path_2: /www/backup/site

# To install and use the script, run the following command:

wget https://github.com/UnderHost/rsync_backup.sh/archive/refs/heads/main.zip && unzip main.zip && mv rsync_backup.sh-main rsync_backup && cd rsync_backup && chmod +x rsync_backup.sh && ./rsync_backup.sh

Please note that while the script attempts to install sshpass and rsync on both servers, you may need to pre-install these packages on both servers using the following command:

yum install -y sshpass rsync

If you want to use the script on Debian, replace "yum" with "apt-get".


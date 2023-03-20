# rsync_backup.sh
This Bash script is designed to backup files from two source paths to a remote server over SSH using rsync and sshpass, aaPanel backup use two seperate folder for backup, one database and other is files. The script is designed to be run on a regular basis based on a frequency defined in a config file or input by the user with aaPanel or anything as long it's RHEL based.

The script first checks for the existence of a config file, and if it is found, reads the backup details from it. If it is not found, the script prompts the user to enter the backup details, and then saves them to the config file for future runs.

The script checks if sshpass and rsync are installed on both the local and remote servers, and installs them if necessary. The script also checks if there is enough available space on the remote server for the backup. If there is not enough space, the backup is aborted, and an email is sent to the specified email address to notify the user.

Finally, the script creates a backup directory on the remote server using the backup frequency and the current date as part of the directory name. It then runs the rsync command to backup the files from the two source paths to the remote server.

Variables that backup.config file will need to be configured:

source_path_1: the path to the first source directory to be backed up.
source_path_2: the path to the second source directory to be backed up.
destination_ip: the IP address of the remote server where the backup will be stored.
destination_path: the path on the remote server where the backup will be stored.
destination_user: the username to use to connect to the remote server over SSH.
destination_password: the password to use to connect to the remote server over SSH.
email_address: the email address to use for notifications in case of backup failure.
backup_frequency: the frequency of the backup, which can be daily, weekly, or monthly.

Usually aaPanel defaut path are:

source_path_1: /www/backup/database
source_path_2: /www/backup/site


# INSTALL

wget https://github.com/UnderHost/rsync_backup.sh/archive/refs/heads/main.zip && unzip main.zip && mv rsync_backup.sh-main rsync_backup && cd rsync_backup && chmod +x rsync_backup.sh && ./rsync_backup.sh

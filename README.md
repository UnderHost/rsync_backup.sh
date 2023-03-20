# rsync_backup.sh
This will backup the specified source directories to the destination server at the specified backup directory using rsync. The backup log will be saved to backup.log in the same directory as the script.


rsync_backup.sh is a simple script that uses the rsync command to backup one or more directories to a remote server. The script takes four arguments: the path to the first source directory, the path to the second source directory (optional), the destination user and IP address, and the path to the backup directory on the remote server. The script uses an exclude list file to exclude certain files or directories from the backup. The backup log is saved to backup.log in the same directory as the script.

# INSTALL

wget https://github.com/UnderHost/rsync_backup.sh/archive/refs/heads/main.zip && unzip main.zip && mv rsync_backup.sh-main rsync_backup && cd rsync_backup && chmod +x rsync_backup.sh && ./rsync_backup.sh

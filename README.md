# UnderHost.com - aaPanel -rsync_backup.sh:

# What is rsync_backup.sh?

rsync_backup.sh is a free and open-source bash script that enables you to backup files from two source paths to a remote server over SSH using rsync and sshpass. While it was designed to work with aaPanel, it can be used in any RHEL-based system.

# How does rsync_backup.sh work?

The script uses a configuration file to manage backup details, or it prompts you to enter the details if the configuration file doesn't exist. It then checks whether sshpass and rsync are installed on both local and remote servers, installing them if necessary. It also checks for sufficient available space on the remote server.

After the checks, the script creates a backup directory on the remote server using the backup frequency and the current date as part of the directory name. It then runs the rsync command to back up the files from the two source paths to the remote server.

# What are the benefits of using rsync_backup.sh?

-Easy to install and use
-Supports aaPanel backup structure
-Flexible backup options (daily, weekly, or monthly)
-Secure and efficient data transfer with rsync
-Email notifications for backup success alerts and log file attachments
-Cron job automation
-Intelligent configuration file usage
-Dependency and space check
-How do I get started with rsync_backup.sh?

rsync_backup.sh is a free and open-source script that you can download and use immediately. Simply copy the script to your server and configure the backup settings using the configuration file or the prompt. Once configured, you can run the script manually or set up a cron job for automatic backups.

Using rsync_backup.sh to back up your files ensures the safety and security of your data. With its flexibility, security, and ease of use, rsync_backup.sh is the perfect solution for users of all skill levels who want to safeguard their important data. Try it today and experience the peace of mind that comes with knowing your data is safe and secure.

# The following variables in the backup.config can be modified manually:

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

wget https://github.com/UnderHost/rsync_backup.sh/archive/refs/heads/rsync_backup.zip && \
unzip rsync_backup.zip && \
mv rsync_backup.sh-rsync_backup rsync_backup && \
cd rsync_backup && \
chmod +x rsync_backup.sh && \
./rsync_backup.sh

# To uninstall:

rm -rf rsync_backup

(If you have created or modified any files outside of the rsync_backup directory while using the script, you may need to remove them manually)

# Should work on all linux distro

Debian, Ubuntu, Fedora, CentOS, RHEL, SUSE, and their derivatives, Arch & Alpine Linux as well.


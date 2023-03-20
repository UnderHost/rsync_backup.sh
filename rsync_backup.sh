#!/bin/bash
#  _   _ _  _ ___  ___ ___ _  _  ___  ___ _____ 
# | | | | \| |   \| __| _ \ || |/ _ \/ __|_   _|
# | |_| | .` | |) | _||   / __ | (_) \__ \ | |  
#  \___/|_|\_|___/|___|_|_\_||_|\___/|___/ |_|  
#                                               
# GNU General Public License v3.0
# Copyright (C) 2023 UnderHost.com
#
# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

CONFIG_FILE="backup.config"

# Read backup details from config file
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Prompt user for backup details if any variable is missing
if [ -z "$source_path_1" ]; then
    read -p "Enter source path 1: " source_path_1
fi
if [ -z "$source_path_2" ]; then
    read -p "Enter source path 2: " source_path_2
fi
if [ -z "$destination_ip" ]; then
    read -p "Enter destination IP: " destination_ip
fi
if [ -z "$destination_user" ]; then
    read -p "Enter destination user: " destination_user
fi
if [ -z "$destination_path" ]; then
    read -p "Enter destination path: " destination_path
fi
if [ -z "$destination_password" ]; then
    read -p "Enter destination password: " -s destination_password
fi
if [ -z "$email_address" ]; then
    read -p "Enter email address for alerts:  " -s email_address
fi
if [ -z "$backup_frequency" ]; then
    read -p "Enter backup frequency (daily, weekly, or monthly): " backup_frequency
fi



# Check if sshpass is installed on current server, if not install it
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass is not installed on current server. Installing...${NC}"
    sudo apt-get update
    sudo apt-get install -y sshpass
fi

# Check if rsync is installed on current server, if not install it
if ! command -v rsync &> /dev/null; then
    echo -e "${YELLOW}rsync is not installed on current server. Installing...${NC}"
    sudo apt-get update
    sudo apt-get install -y rsync
fi

# Prompt user for backup details if config file does not exist
if [ ! -f "$CONFIG_FILE" ]; then
    read -p "Enter source path 1: " source_path_1
    read -p "Enter source path 2: " source_path_2
    read -p "Enter destination IP: " destination_ip
    read -p "Enter destination path: " destination_path
    read -p "Enter destination user: " destination_user
    read -p "Enter destination password: " -s destination_password
    read -p "Enter email address for alerts:  "  email_address
    echo
    read -p "Enter backup frequency (daily, weekly, or monthly): " backup_frequency

    # Save backup details to config file
    echo "source_path_1=$source_path_1" > "$CONFIG_FILE"
    echo "source_path_2=$source_path_2" >> "$CONFIG_FILE"
    echo "destination_ip=$destination_ip" >> "$CONFIG_FILE"
    echo "destination_user=$destination_user" >> "$CONFIG_FILE"
    echo "destination_path=$destination_path" >> "$CONFIG_FILE"
    echo "destination_password=$destination_password" >> "$CONFIG_FILE"
    echo "email_address=$email_address" >> "$CONFIG_FILE"
    echo "backup_frequency=$backup_frequency" >> "$CONFIG_FILE"
else
    # Read backup details from config file
    source "$CONFIG_FILE"
fi

# Check if sshpass is installed on destination server, if not install it
if ! sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass is not installed on destination server. Installing...${NC}"
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo apt-get update
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo apt-get install -y sshpass
fi

# Check if rsync is installed on destination server, if not install it
if ! sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" command -v rsync &> /dev/null; then
    echo -e "${YELLOW}rsync is not installed on destination server. Installing...${NC}"
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo apt-get update
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo apt-get install -y rsync
fi

# Check available space on destination
destination_space=$(sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "df -h --output=avail $destination_path" | tail -n 1 | tr -d ' ')
if [ "$destination_space" -lt 1024000 ]; then
    echo -e "${RED}Not enough space on destination. Aborting.${NC}" | tee "$log_file"
    mail -s "Backup failed - not enough space on destination" "$email_address" < "$log_file"
    exit 1
fi

# Create backup directory with date and run rsync command
backup_dir="$destination_path/$backup_frequency-$(date +%Y-%m-%d)"
sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "mkdir -p $backup_dir"
rsync -avz --exclude-from 'exclude-list.txt' "$source_path_1" "$source_path_2" "$destination_user"@"$destination_ip":"$backup_dir" > backup.log

# Send email with log attached
echo "Backup complete. Log file attached." | mail -s "Backup Report" -a backup.log "$email_address"

# Add cron job based on frequency
if [ "$backup_frequency" == "daily" ]; then
    cron_job="0 0 * * * $0"
elif [ "$backup_frequency" == "weekly" ]; then
    cron_job="0 0 * * 0 $0"
elif [ "$backup_frequency" == "monthly" ]; then
    cron_job="0 0 1 * * $0"
fi

(crontab -u "$(whoami)" -l; echo "$cron_job") | crontab -u "$(whoami)" -

echo -e "${GREEN}Backup completed successfully.${NC}"
echo -e "Cron job added: ${GREEN}$cron_job${NC}"

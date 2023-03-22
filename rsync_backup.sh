#!/bin/bash
#  _   _ _  _ ___  ___ ___ _  _  ___  ___ _____ 
# | | | | \| |   \| __| _ \ || |/ _ \/ __|_   _|
# | |_| | .` | |) | _||   / __ | (_) \__ \ | |  
#  \___/|_|\_|___/|___|_|_\_||_|\___/|___/ |_|  
#                                               
# GNU General Public License v3.0
# Copyright (C) 2023 UnderHost.com
# v2.0.1 ALL DISTRO
# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
CONFIG_FILE="backup.config"

get_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
  else
    DISTRO=$(uname -s)
  fi
}

get_distro

# Function to install packages based on package manager
install_package() {
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y "$1"
    elif command -v yum &> /dev/null; then
        sudo yum update -y
        sudo yum install -y "$1"
    elif command -v zypper &> /dev/null; then
        sudo zypper refresh
        sudo zypper install -y "$1"
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm "$1"
    elif command -v apk &> /dev/null; then
        sudo apk update
        sudo apk add "$1"
    else
        echo -e "${RED}Package manager not supported. Please install $1 manually.${NC}"
        exit 1
    fi
}

# Read backup details from config file
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Prompt user for backup details if config file does not exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Backup config file not found. Prompting user for backup details...${NC}"
    
    # Use dialog to create a simple user interface
    source_path_1=$(dialog --stdout --inputbox "Enter source path 1:" 8 40)
    source_path_2=$(dialog --stdout --inputbox "Enter source path 2:" 8 40)
    destination_ip=$(dialog --stdout --inputbox "Enter destination IP:" 8 40)
    destination_path=$(dialog --stdout --inputbox "Enter destination path:" 8 40)
    destination_user=$(dialog --stdout --inputbox "Enter destination user:" 8 40)
    destination_password=$(dialog --stdout --insecure --passwordbox "Enter destination password:" 8 40)
    email_address=$(dialog --stdout --inputbox "Enter email address for alerts:" 8 40)
    backup_frequency=$(dialog --stdout --menu "Enter backup frequency:" 10 40 3 \
        "daily" "Daily" \
        "weekly" "Weekly" \
        "monthly" "Monthly")
    
    # Save backup details to config file
    echo -e "${GREEN}Saving backup details to config file...${NC}"
    echo "source_path_1=$source_path_1" > "$CONFIG_FILE"
    echo "source_path_2=$source_path_2" >> "$CONFIG_FILE"
    echo "destination_ip=$destination_ip" >> "$CONFIG_FILE"
    echo "destination_user=$destination_user" >> "$CONFIG_FILE"
    echo "destination_path=$destination_path" >> "$CONFIG_FILE"
    echo "destination_password=$destination_password" >> "$CONFIG_FILE"
    echo "email_address=$email_address" >> "$CONFIG_FILE"
    echo "backup_frequency=$backup_frequency" >> "$CONFIG_FILE"
    echo -e "${GREEN}Backup details saved successfully.${NC}"
else
    # Read backup details from config file
    echo -e "${GREEN}Reading backup details from config file...${NC}"
    source "$CONFIG_FILE"
fi

# Check if sshpass is installed on current server, if not install it
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass is not installed on current server. Installing...${NC}"
    install_package "sshpass"
fi

# Check if rsync is installed on current server, if not install it
if ! command -v rsync &> /dev/null; then
    echo -e "${YELLOW}rsync is not installed on current server. Installing...${NC}"
    install_package "rsync"
fi

# Check if sshpass is installed on destination server, if not install it
if ! sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass is not installed on destination server. Installing...${NC}"
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "$(declare -f install_package); install_package sshpass"
fi

# Check if rsync is installed on destination server, if not install it
if ! sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" command -v rsync &> /dev/null; then
    echo -e "${YELLOW}rsync is not installed on destination server. Installing...${NC}"
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "$(declare -f install_package); install_package rsync"
fi

# Check available space on destination
destination_space=$(sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "df -h --output=avail $destination_path" | tail -n 1 | tr -d ' ')
if [ "${destination_space%%[^0-9]*}" -lt 1024 ]; then
    echo -e "${RED}Not enough space on destination. Aborting.${NC}" | tee "$log_file"
    mail -s "Backup failed - not enough space on destination" "$email_address" < "$log_file"
    exit 1
fi

# Create backup directory with date and run rsync command
backup_dir="$destination_path/$backup_frequency-$(date +%Y-%m-%d)"
sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "mkdir -p '$backup_dir'"

# Set rsync options based on backup frequency
case $backup_frequency in
daily)
rsync_options="-avz --delete --exclude 'weekly*' --exclude 'monthly*'"
;;
weekly)
rsync_options="-avz --delete --exclude 'daily*' --exclude 'monthly*'"
;;
monthly)
rsync_options="-avz --delete --exclude 'daily*' --exclude 'weekly*'"
;;
esac

# Run rsync command to perform backup
rsync $rsync_options -e "sshpass -p '$destination_password' ssh" "$source_path_1" "$destination_user"@"$destination_ip":"$backup_dir"
rsync $rsync_options -e "sshpass -p '$destination_password' ssh" "$source_path_2" "$destination_user"@"$destination_ip":"$backup_dir"

# Log backup results
echo "$(date) - Backup complete. Files copied to $backup_dir" >> "$log_file"

# Send email with log attached
echo "Backup complete. Log file attached." | mail -s "Backup success - $backup_frequency backup" "$email_address" < "$log_file"

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

# Exit script
exit 0
    echo "backup_frequency=$backup_frequency" >> "$CONFIG_FILE"
    echo -e "${GREEN}Backup details saved successfully.${NC}"
else
    # Read backup details from config file
    echo -e "${GREEN}Reading backup details from config file...${NC}"
    source "$CONFIG_FILE"
fi

# Check if sshpass is installed on current server, if not install it
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass is not installed on current server. Installing...${NC}"
    sudo yum update -y
    sudo yum install -y sshpass
fi

# Check if rsync is installed on current server, if not install it
if ! command -v rsync &> /dev/null; then
    echo -e "${YELLOW}rsync is not installed on current server. Installing...${NC}"
    sudo yum update -y
    sudo yum install -y rsync
fi

# Check if sshpass is installed on destination server, if not install it
if ! sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass is not installed on destination server. Installing...${NC}"
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yum update -y
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yuminstall -y sshpass
fi

# Check if rsync is installed on destination server, if not install it
if ! sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" command -v rsync &> /dev/null; then
    echo -e "${YELLOW}rsync is not installed on destination server. Installing...${NC}"
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yum update -y
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yum install -y rsync
fi

# Check available space on destination
destination_space=$(sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "df -h --output=avail $destination_path" | tail -n 1 | tr -d ' ')
if [ "$destination_space" -lt 1024000 ]; then
    echo -e "${RED}Not enough space on destination. Aborting.${NC}" | tee "$log_file"
    mail -s "Backup failed - not enough space on destination" "$email_address" < "$log_file"
    exit 1
fi

#Create backup directory with date and run rsync command
backup_dir="$destination_path/$backup_frequency-$(date +%Y-%m-%d)"
sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "mkdir -p '$backup_dir'"

#Set rsync options based on backup frequency
case $backup_frequency in
daily)
rsync_options="-avz --delete --exclude 'weekly*' --exclude 'monthly*'"
;;
weekly)
rsync_options="-avz --delete --exclude 'daily*' --exclude 'monthly*'"
;;
monthly)
rsync_options="-avz --delete --exclude 'daily*' --exclude 'weekly*'"
;;
esac

#Run rsync command to perform backup
rsync $rsync_options -e "sshpass -p '$destination_password' ssh" "$source_path_1" "$destination_user"@"$destination_ip":"$backup_dir"
rsync $rsync_options -e "sshpass -p '$destination_password' ssh" "$source_path_2" "$destination_user"@"$destination_ip":"$backup_dir"

Log backup results
echo "$(date) - Backup complete. Files copied to $backup_dir" >> "$log_file"

# Send email with log attached
echo "Backup complete. Log file attached." | mail -s "Backup success - $backup_frequency backup" "$email_address" < "$log_file"

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

#Exit script
exit 0
    read -p "Enter backup frequency (daily, weekly, or monthly): " backup_frequency

    # Save backup details to config file
    echo -e "${GREEN}Saving backup details to config file...${NC}"
    echo "source_path_1=$source_path_1" > "$CONFIG_FILE"
    echo "source_path_2=$source_path_2" >> "$CONFIG_FILE"
    echo "destination_ip=$destination_ip" >> "$CONFIG_FILE"
    echo "destination_user=$destination_user" >> "$CONFIG_FILE"
    echo "destination_path=$destination_path" >> "$CONFIG_FILE"
    echo "destination_password=$destination_password" >> "$CONFIG_FILE"
    echo "email_address=$email_address" >> "$CONFIG_FILE"
    echo "backup_frequency=$backup_frequency" >> "$CONFIG_FILE"
    echo -e "${GREEN}Backup details saved successfully.${NC}"
else
    # Read backup details from config file
    echo -e "${GREEN}Reading backup details from config file...${NC}"
    source "$CONFIG_FILE"
fi

# Check if sshpass is installed on current server, if not install it
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass is not installed on current server. Installing...${NC}"
    case "$DISTRO" in
        centos|rhel|fedora)
            sudo yum update -y
            sudo yum install -y sshpass
            ;;
        debian|ubuntu)
            sudo apt update
            sudo apt install -y sshpass
            ;;
        opensuse*|sles)
            sudo zypper refresh
            sudo zypper install -y sshpass
            ;;
        *)
            echo "Unsupported distribution. Exiting."
            exit 1
            ;;
    esac
fi

# Check if rsync is installed on current server, if not install it
if ! command -v rsync &> /dev/null; then
    echo -e "${YELLOW}rsync is not installed on current server. Installing...${NC}"
    case "$DISTRO" in
        centos|rhel|fedora)
            sudo yum update -y
            sudo yum install -y rsync
            ;;
        debian|ubuntu)
            sudo apt update
            sudo apt install -y rsync
            ;;
        opensuse*|sles)
            sudo zypper refresh
            sudo zypper install -y rsync
            ;;
        *)
            echo "Unsupported distribution. Exiting."
            exit 1
            ;;
    esac
fi

# Check if sshpass is installed on destination server, if not install it
if ! sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass is not installed on destination server. Installing...${NC}"
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yum update -y
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yum install -y sshpass
fi

# Check if rsync is installed on destination server, if not install it
if ! sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" command -v rsync &> /dev/null; then
    echo -e "${YELLOW}rsync is not installed on destination server. Installing...${NC}"
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yum update -y
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yum install -y rsync
fi

# Check available space on destination
destination_space=$(sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "df -h --output=avail $destination_path" | tail -n 1 | tr -d ' ')
if [ "${destination_space%%[^0-9]*}" -lt 1024 ]; then
    echo -e "${RED}Not enough space on destination. Aborting.${NC}" | tee "$log_file"
    mail -s "Backup failed - not enough space on destination" "$email_address" < "$log_file"
    exit 1
fi

# Create backup directory with date and run rsync command
backup_dir="$destination_path/$backup_frequency-$(date +%Y-%m-%d)"
sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "mkdir -p '$backup_dir'"

# Set rsync options based on backup frequency
case $backup_frequency in
daily)
rsync_options="-avz --delete --exclude 'weekly*' --exclude 'monthly*'"
;;
weekly)
rsync_options="-avz --delete --exclude 'daily*' --exclude 'monthly*'"
;;
monthly)
rsync_options="-avz --delete --exclude 'daily*' --exclude 'weekly*'"
;;
esac

# Run rsync command to perform backup
rsync $rsync_options -e "sshpass -p '$destination_password' ssh" "$source_path_1" "$destination_user"@"$destination_ip":"$backup_dir"
rsync $rsync_options -e "sshpass -p '$destination_password' ssh" "$source_path_2" "$destination_user"@"$destination_ip":"$backup_dir"

# Log backup results
echo "$(date) - Backup complete. Files copied to $backup_dir" >> "$log_file"

# Send email with log attached
echo "Backup complete. Log file attached." | mail -s "Backup success - $backup_frequency backup" "$email_address" < "$log_file"

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

# Exit script
exit 0
    echo "backup_frequency=$backup_frequency" >> "$CONFIG_FILE"
    echo -e "${GREEN}Backup details saved successfully.${NC}"
else
    # Read backup details from config file
    echo -e "${GREEN}Reading backup details from config file...${NC}"
    source "$CONFIG_FILE"
fi

# Check if sshpass is installed on current server, if not install it
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass is not installed on current server. Installing...${NC}"
    sudo yum update -y
    sudo yum install -y sshpass
fi

# Check if rsync is installed on current server, if not install it
if ! command -v rsync &> /dev/null; then
    echo -e "${YELLOW}rsync is not installed on current server. Installing...${NC}"
    sudo yum update -y
    sudo yum install -y rsync
fi

# Check if sshpass is installed on destination server, if not install it
if ! sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass is not installed on destination server. Installing...${NC}"
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yum update -y
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yuminstall -y sshpass
fi

# Check if rsync is installed on destination server, if not install it
if ! sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" command -v rsync &> /dev/null; then
    echo -e "${YELLOW}rsync is not installed on destination server. Installing...${NC}"
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yum update -y
    sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" sudo yum install -y rsync
fi

# Check available space on destination
destination_space=$(sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "df -h --output=avail $destination_path" | tail -n 1 | tr -d ' ')
if [ "$destination_space" -lt 1024000 ]; then
    echo -e "${RED}Not enough space on destination. Aborting.${NC}" | tee "$log_file"
    mail -s "Backup failed - not enough space on destination" "$email_address" < "$log_file"
    exit 1
fi

#Create backup directory with date and run rsync command
backup_dir="$destination_path/$backup_frequency-$(date +%Y-%m-%d)"
sshpass -p "$destination_password" ssh "$destination_user"@"$destination_ip" "mkdir -p '$backup_dir'"

#Set rsync options based on backup frequency
case $backup_frequency in
daily)
rsync_options="-avz --delete --exclude 'weekly*' --exclude 'monthly*'"
;;
weekly)
rsync_options="-avz --delete --exclude 'daily*' --exclude 'monthly*'"
;;
monthly)
rsync_options="-avz --delete --exclude 'daily*' --exclude 'weekly*'"
;;
esac

#Run rsync command to perform backup
rsync $rsync_options -e "sshpass -p '$destination_password' ssh" "$source_path_1" "$destination_user"@"$destination_ip":"$backup_dir"
rsync $rsync_options -e "sshpass -p '$destination_password' ssh" "$source_path_2" "$destination_user"@"$destination_ip":"$backup_dir"

Log backup results
echo "$(date) - Backup complete. Files copied to $backup_dir" >> "$log_file"

# Send email with log attached
echo "Backup complete. Log file attached." | mail -s "Backup success - $backup_frequency backup" "$email_address" < "$log_file"

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

#Exit script
exit 0

#!/bin/bash
#  _   _ _  _ ___  ___ ___ _  _  ___  ___ _____ 
# | | | | \| |   \| __| _ \ || |/ _ \/ __|_   _|
# | |_| | .` | |) | _||   / __ | (_) \__ \ | |  
#  \___/|_|\_|___/|___|_|_\_||_|\___/|___/ |_|  
#                                               
# UnderHost Dedicated Server Toolkit
# GNU General Public License v3.0
# Copyright (C) 2023-2025 UnderHost.com
# v2.2.0 (Optimized for UnderHost NVMe Storage)

set -o pipefail

# Configuration
CONFIG_FILE="/etc/underhost/backup.conf"
LOG_FILE="/var/log/underhost_backup.log"
LOCK_FILE="/tmp/underhost_backup.lock"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# UnderHost header
echo -e "${BLUE}"
echo "   ___  _   _ _____ _   _ _  _ ___ ___  ___ "
echo "  / _ \| | | |_   _| | | | \| | __/ _ \/ __|"
echo " | (_) | |_| | | | | |_| | .\` | _| (_) \__ \\"
echo "  \___/ \___/  |_|  \___/|_|\_|___\___/|___/"
echo -e "${NC}"
echo "=== UnderHost Dedicated Server Backup Solution ==="
echo ""

# Check for root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run as root${NC}" >&2
  exit 1
fi

# Check for existing lock file
if [ -f "$LOCK_FILE" ]; then
  echo -e "${YELLOW}Backup is already running (lock file exists)${NC}"
  exit 0
fi

# Create lock file
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"; exit' INT TERM EXIT

# Function to install packages
install_package() {
  echo -e "${YELLOW}Installing $1...${NC}"
  if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y "$1"
  elif command -v yum &> /dev/null; then
    yum install -y "$1"
  elif command -v dnf &> /dev/null; then
    dnf install -y "$1"
  elif command -v apk &> /dev/null; then
    apk add "$1"
  else
    echo -e "${RED}Error: Package manager not supported${NC}"
    exit 1
  fi
}

validate_frequency() {
  case "$1" in
    daily|weekly|monthly) return 0 ;;
    *) return 1 ;;
  esac
}

validate_config() {
  local required=(source_path_1 destination_ip destination_port destination_user destination_path email_address backup_frequency destination_password)
  for key in "${required[@]}"; do
    if [ -z "${!key:-}" ]; then
      echo -e "${RED}Error: Missing required config value: $key${NC}" >&2
      exit 1
    fi
  done

  if ! validate_frequency "$backup_frequency"; then
    echo -e "${RED}Error: backup_frequency must be daily, weekly, or monthly${NC}" >&2
    exit 1
  fi
}

# Initialize configuration
init_config() {
  mkdir -p /etc/underhost
  echo -e "${YELLOW}Initializing new backup configuration...${NC}"
  
  read -r -p "Enter source path 1: " source_path_1
  read -r -p "Enter source path 2 (optional, press enter to skip): " source_path_2
  read -r -p "Enter destination IP: " destination_ip
  read -r -p "Enter destination SSH port (default 22): " destination_port
  destination_port=${destination_port:-22}
  read -r -p "Enter destination user: " destination_user
  read -r -p "Enter destination path: " destination_path
  read -r -s -p "Enter destination password: " destination_password
  echo ""
  read -r -p "Enter email for notifications: " email_address

  while true; do
    read -r -p "Backup frequency (daily/weekly/monthly): " backup_frequency
    if validate_frequency "$backup_frequency"; then
      break
    fi
    echo -e "${YELLOW}Please enter daily, weekly, or monthly.${NC}"
  done

  # Generate config file
  cat > "$CONFIG_FILE" <<EOL
# UnderHost Backup Configuration
source_path_1='$source_path_1'
source_path_2='$source_path_2'
destination_ip='$destination_ip'
destination_port='$destination_port'
destination_user='$destination_user'
destination_path='$destination_path'
destination_password='$destination_password'
email_address='$email_address'
backup_frequency='$backup_frequency'
EOL

  chmod 600 "$CONFIG_FILE"
  echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
}

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
  init_config
fi
source "$CONFIG_FILE"
validate_config

# Verify required packages
if ! command -v rsync &> /dev/null; then
  install_package "rsync"
fi

if ! command -v sshpass &> /dev/null; then
  install_package "sshpass"
fi

if ! command -v mail &> /dev/null; then
  if command -v apt-get &> /dev/null; then
    install_package "mailutils"
  else
    install_package "mailx"
  fi
fi

# Backup function
perform_backup() {
  local timestamp
  timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  local backup_dir="$destination_path/$backup_frequency-$timestamp"
  
  echo -e "${BLUE}Starting UnderHost Backup at $(date)${NC}" | tee -a "$LOG_FILE"
  
  # Create backup directory
  sshpass -p "$destination_password" ssh -p "$destination_port" "$destination_user@$destination_ip" \
    "mkdir -p '$backup_dir'"
  
  # Set rsync options
  local rsync_opts="-avz --progress --delete --exclude='*.tmp' --exclude='cache/*'"
  
  # Perform backup
  echo -e "${YELLOW}Backing up $source_path_1...${NC}" | tee -a "$LOG_FILE"
  sshpass -p "$destination_password" rsync $rsync_opts -e "ssh -p $destination_port" \
    "$source_path_1" "$destination_user@$destination_ip:$backup_dir" | tee -a "$LOG_FILE"
  
  if [ -n "${source_path_2:-}" ]; then
    echo -e "${YELLOW}Backing up $source_path_2...${NC}" | tee -a "$LOG_FILE"
    sshpass -p "$destination_password" rsync $rsync_opts -e "ssh -p $destination_port" \
      "$source_path_2" "$destination_user@$destination_ip:$backup_dir" | tee -a "$LOG_FILE"
  fi
  
  # Verify backup
  local backup_size
  backup_size=$(sshpass -p "$destination_password" ssh -p "$destination_port" \
    "$destination_user@$destination_ip" "du -sh '$backup_dir' | cut -f1")
  
  echo -e "${GREEN}Backup completed successfully!${NC}" | tee -a "$LOG_FILE"
  echo -e "Backup size: $backup_size" | tee -a "$LOG_FILE"
  
  # Send notification
  echo "UnderHost Backup Report" > /tmp/backup_report.txt
  echo "---------------------" >> /tmp/backup_report.txt
  tail -n 10 "$LOG_FILE" >> /tmp/backup_report.txt
  mail -s "UnderHost Backup Completed ($backup_frequency)" "$email_address" < /tmp/backup_report.txt
}

# Main execution
perform_backup

# Cleanup
rm -f "$LOCK_FILE"
echo -e "${GREEN}UnderHost Backup completed at $(date)${NC}" | tee -a "$LOG_FILE"
exit 0

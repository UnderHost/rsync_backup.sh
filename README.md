# 🔄 UnderHost Rsync Backup Solution  
**Part of the [UnderHost Dedicated Server Toolkit](https://underhost.com/servers.php)**  
*Enterprise-grade backups for aaPanel and Linux systems*  

---

## 🚀 Key Features  
✔ **Cross-Platform** - Works on RHEL, Debian, Ubuntu, Alpine, and more  
✔ **aaPanel-Optimized** - Pre-configured for `/www/backup/` paths  
✔ **Smart Scheduling** - Daily/Weekly/Monthly rotations with cron automation  
✔ **Encrypted Transfers** - SSH-secured rsync with password or key auth  
✔ **Email Alerts** - Get notified of backup success/failure  
✔ **Space Monitoring** - Auto-checks destination storage before transfer  

---

## 📦 Installation  

### **One-Line Install**  
```
wget -qO- https://raw.githubusercontent.com/UnderHost/rsync_backup/main/install.sh | bash
```

### **Manual Installation**  
```
# Download and prepare
wget https://github.com/UnderHost/rsync_backup/archive/refs/heads/main.zip
unzip main.zip
cd rsync_backup-main

# Make executable and run
chmod +x rsync_backup.sh
sudo ./rsync_backup.sh
```

---

## ⚙️ Configuration  

### **First-Run Setup**  
The script will prompt for:  
- Source paths (defaults to aaPanel locations)  
- Destination server credentials  
- Notification email  
- Backup frequency  

*Config saved to:* `/etc/underhost/backup.conf`  

### **Manual Config Example**  
```
# UnderHost Backup Configuration
source_path_1="/www/backup/database"
source_path_2="/www/backup/site"
destination_ip="backup.server.com"
destination_user="backupuser"
destination_path="/remote/backups"
email_address="admin@yourdomain.com"
backup_frequency="weekly"
```

---

## 🛠️ Usage  

### **Manual Run**  
```
sudo ./rsync_backup.sh
```

### **Cron Automation**  
```
# Daily at 2AM
0 2 * * * /path/to/rsync_backup.sh
```

### **Logs & Monitoring**  
- Live output: `tail -f /var/log/underhost_backup.log`  
- Email reports: Sent after each run  

---

## 📚 Documentation  

### **Supported Paths**  
| Path | Description |  
|------|-------------|  
| `/www/backup/database` | aaPanel MySQL dumps |  
| `/www/backup/site` | aaPanel website archives |  

### **Compatibility Matrix**  
| Distro | Tested Versions |  
|--------|----------------|  
| CentOS | 7, 8, Stream |  
| Ubuntu | 20.04, 22.04 |  
| Debian | 10, 11 |  
| Alpine | 3.15+ |  

---

## ❓ FAQ  

**Q: Can I use SSH keys instead of passwords?**  
A: Yes! Replace `destination_password` with `ssh_key_path="/path/to/key"` in config  

**Q: How do I exclude files?**  
A: Add `--exclude='pattern'` to `rsync_options` in the script  

**Q: Where are backups stored remotely?**  
A: In `destination_path/frequency-date/` (e.g., `/remote/backups/weekly-2025-06-15`)  

---

## 🌟 Why Choose UnderHost?  
- **NVMe Storage** - Faster backup/restore speeds  
- **24/7 Support** - [Contact Us](https://underhost.com/contact) for backup assistance  
- **Bare-Metal Optimized** - Designed for dedicated server performance  

[![Deploy on UnderHost](https://via.placeholder.com/200x50?text=Deploy+on+UnderHost+→)](https://underhost.com/servers.php)  

---

## 📜 License  
MIT License © 2023-2025 UnderHost.com  
*Free for personal and commercial use*  

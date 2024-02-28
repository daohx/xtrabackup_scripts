# Automates the process of setting up and managing backups using Percona XtraBackup.

Step 1: Clone the repository
```
git clone https://github.com/daohx/xtrabackup_scripts.git /backup/xtrabackup_scripts/
```

Step 2: Make the downloaded script executable
```
chmod +x /backup/xtrabackup_scripts/xtrabackup_full_incremental_restore_cleanup.sh
```

Step 3: Run full backup
```
cd /backup/xtrabackup_scripts/ && \
bash xtrabackup_full_incremental_restore_cleanup.sh full
```

Step 4: Copy the systemd service and timer files to the appropriate directory
```
cd /backup/xtrabackup_scripts/ && \
cp xtrabackup_full_cleanup.service xtrabackup_full_cleanup.timer xtrabackup_incremental.service xtrabackup_incremental.timer /etc/systemd/system/
```

Step 5: Reload systemd to detect the new unit files
```
sudo systemctl daemon-reload
```

Step 6: Enable and start the timers
```
sudo systemctl enable --now xtrabackup_full_cleanup.timer
sudo systemctl enable --now xtrabackup_incremental.timer
```

## One short scripts
```
# Step 1: Clone the repository
git clone https://github.com/daohx/xtrabackup_scripts.git /backup/xtrabackup_scripts/

# Step 2: Make the downloaded script executable
chmod +x /backup/xtrabackup_scripts/xtrabackup_full_incremental_restore_cleanup.sh

# Step 3: Copy the systemd service and timer files to the appropriate directory
cd /backup/xtrabackup_scripts/ && \
cp xtrabackup_full_cleanup.service xtrabackup_full_cleanup.timer xtrabackup_incremental.service xtrabackup_incremental.timer /etc/systemd/system/

# Step 4: Reload systemd to detect the new unit files
sudo systemctl daemon-reload

# Step 5: Enable and start the timers
sudo systemctl enable --now xtrabackup_full_cleanup.timer
sudo systemctl enable --now xtrabackup_incremental.timer
```

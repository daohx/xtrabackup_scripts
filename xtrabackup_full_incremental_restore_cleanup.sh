#!/bin/bash
# This is my production backup script.
# https://sqlgossip.com

set -e  # Halt on errors

usage() {
    echo "usage: $(basename $0) [option]"
    echo "option=full: Perform Full Backup"
    echo "option=incremental: Perform Incremental Backup"
    echo "option=restore: Start to Restore! Be Careful!!"
    echo "option=cleanup: Perform Backup Cleanup (Retention)"
	echo "option=help: show this help"
}

full_backup() {

        if [ ! -d $BACKUP_DIR ]
        then
            mkdir $BACKUP_DIR
        fi
        
        rm -rf $BACKUP_DIR/*
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Cleanup the backup folder is done! Starting backup" >> $BACKUP_DIR/xtrabackup.log
        
        xtrabackup --backup --login-path=xtrabackup --compress --parallel=4 --compress-threads=4 --target-dir=$BACKUP_DIR/FULL
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Backup Done!" >> $BACKUP_DIR/xtrabackup.log
}


incremental_backup()
{
        if [ ! -d $BACKUP_DIR/FULL ]
        then
                echo "ERROR: Unable to find the FULL Backup. aborting....."
                exit -1
        fi

        if [ ! -f $BACKUP_DIR/last_incremental_number ]; then
            NUMBER=1
        else
            NUMBER=$(($(cat $BACKUP_DIR/last_incremental_number) + 1))
        fi
        
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Starting Incremental backup $NUMBER" >> $BACKUP_DIR/xtrabackup.log
        if [ $NUMBER -eq 1 ]
        then
                xtrabackup --backup --parallel=4 --compress-threads=4 --target-dir=$BACKUP_DIR/inc$NUMBER --incremental-basedir=$BACKUP_DIR/FULL 
        else
                xtrabackup --backup --parallel=4 --compress-threads=4 --target-dir=$BACKUP_DIR/inc$NUMBER --incremental-basedir=$BACKUP_DIR/inc$(($NUMBER - 1)) 
        fi

        echo $NUMBER > $BACKUP_DIR/last_incremental_number
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Incremental Backup:$NUMBER done!"  >> $BACKUP_DIR/xtrabackup.log
}

restore() {
    # List available backup directories
    echo "Available backup directories:"
    ls -d /backup/xtrabackup/*/ | awk -F'/' '{print NR".",$4}'

    # Prompt the user to select a backup directory
    read -p "Enter the number of the backup directory you want to restore from: " backup_number

    # Validate the user input
    if ! [[ "$backup_number" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a valid number."
        exit 1
    fi

    # Get the selected backup directory based on user input
    selected_backup=$(ls -d /backup/xtrabackup/*/ | awk -F'/' -v num="$backup_number" 'NR==num {print $0}')

    if [ -z "$selected_backup" ]; then
        echo "Invalid backup number. Please select a valid backup directory."
        exit 1
    fi

    # Define the restore directory
    RESTORE_DIR="/backup/xtrabackup-restore"

    echo "$(date '+%Y-%m-%d %H:%M:%S:%s'): Restoring backup from directory: $selected_backup" >> "$RESTORE_DIR/xtrabackup-restore.log"

    # Decompress and prepare the selected backup for restoration
    xtrabackup --decompress --parallel=4 --target-dir="$selected_backup"
    xtrabackup --prepare --apply-log-only --target-dir="$selected_backup"

    # Restore the selected backup to the restore directory
    xtrabackup --copy-back --target-dir="$selected_backup" --datadir="$RESTORE_DIR"

    echo "$(date '+%Y-%m-%d %H:%M:%S:%s'): Backup restoration completed." >> "$RESTORE_DIR/xtrabackup-restore.log"
}



cleanup() {
    # Specify the number of backups to retain    
    RETENTION_COUNT=5
    # For weekly backups, RETENTION_COUNT=5 means retaining the most recent 5 weeks' worth of backups

    # List all backup directories sorted by modification time (oldest first)
    backup_dirs=($(ls -td "$BACKUP_DIR"/*/))

    # Determine the number of backups to delete
    num_backups=$((${#backup_dirs[@]} - RETENTION_COUNT))

    # Delete old backups
    if ((num_backups > 0)); then
        echo "Removing $num_backups old backup(s)..."
        for ((i = 0; i < num_backups; i++)); do
            echo "Deleting ${backup_dirs[i]}"
            rm -rf "${backup_dirs[i]}"
        done
    else
        echo "No old backups to remove."
    fi
}

## Parameters
BACKUP_DIR="/backup/xtrabackup/$(date +\%Y-Week%W)"

if [ $# -eq 0 ]
then
    usage
    exit 1
fi

case $1 in
    "full")
        full_backup
        ;;
    "incremental")
        incremental_backup
        ;;
    "restore")
        restore
        ;;
    "cleanup")
        cleanup
        ;;    
    "help")
        usage
        break
        ;;
    *) echo "invalid option";;
esac

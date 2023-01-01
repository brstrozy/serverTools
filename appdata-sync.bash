#!/bin/bash

LOG_DIR="/mnt/user/logs/appdataSync/"`date +"%m-%d-%Y"`""
LOG_FILEPATH="$BACKUP_DIR"/appdata-backup.txt""

#Backing up all server data (appdata)
mkdir -p "$LOG_DIR"
echo -e "--------Backing up AppData --------\n" >> "$LOG_FILEPATH"
rsync -xavh --progress  --delete --exclude=trash --exclude=movies --exclude=tv_shows /mnt/user/ /mnt/disks/Backup &>> "$LOG_FILEPATH"
echo -e "\n\n------------------------------------------------------------------------------\n" >> "$LOG_FILEPATH"
echo -e "-------- Finished Backup for the rest of the UNRAID server --------\n" >> "$LOG_FILEPATH"
echo -e "------------------------------------------------------------------------------\n\n" >> "$LOG_FILEPATH"

echo -e "AppData Sync Complete!" >> "$LOG_FILEPATH"

#Send Completion Email
/usr/local/emhttp/webGui/scripts/notify -e "AppData Sync Status" -i normal -s "AppData Sync Complete!"

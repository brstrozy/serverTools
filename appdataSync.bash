#!/bin/bash

LOG_DIR="/mnt/user/logs/appdataSync/"`date +"%m-%d-%Y"`""
BACKUP_PATH="/mnt/disks/Backup"

LOG_FILEPATH="$LOG_DIR"/appdata-backup.txt""
HAD_ERROR=0

#Make log directory if not exists
mkdir -p "$LOG_DIR"

paths[0]="/mnt/user/appdata"
paths[1]="/mnt/user/domains"
paths[2]="/mnt/user/isos"
paths[3]="/mnt/user/system"

#--------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------

echo -e "Starting Backup..." >> "$LOG_FILEPATH"

for path in ${paths[@]}; do 

    echo -e "\n\n---------------------------------------------------------------------------------------------------------------------------------------------------" >> "$LOG_FILEPATH"
    echo -e "\n-------- BACKING UP: "$path" ------------------------------------------------------------------------------------------------------------------------\n" >> "$LOG_FILEPATH"
    echo -e "---------------------------------------------------------------------------------------------------------------------------------------------------\n\n" >> "$LOG_FILEPATH"

    # Sync files between two locations
    rsync -xavh --progress --delete "$path" "$BACKUP_PATH" &>> "$LOG_FILEPATH"

    # Send an error email if rsync exits with non 0 exit code.
    if [ $? -ne 0 ]; then
        HAD_ERROR=$?
        /usr/local/emhttp/webGui/scripts/notify -e "AppData Sync Status" -i alert -s "AppData Sync Error!!!" -d "Error: rsync exited with error code $? while backup up "$path""
    fi

done

echo -e "\n\nDone.\n" >> "$LOG_FILEPATH"

#--------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------

#Send Completion Email if no errors occurred
if [ "$HAD_ERROR" -eq 0 ]; then
	/usr/local/emhttp/webGui/scripts/notify -e "AppData Sync Status" -i normal -s "AppData Sync Complete!"
fi


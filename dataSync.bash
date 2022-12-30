#!/bin/bash

inputFile="paths.txt"
LOG_DIR="/mnt/user/storage/rsync_logs/"`date +"%m-%d-%Y"`""
TRASH_PATH="/mnt/user/trash/"
BACKUP_PATH="/mnt/disks/Backup"

LOG_FILEPATH="$LOG_DIR"/data-backup2.txt""
HAD_ERROR=0

#Make backup directory if not exists
mkdir -p "$LOG_DIR"

file=$(cat $inputFile)
declare paths=()

# GET ARRAY OF PATHS FROM file
index=0
for line in $file
do
    filtered_line=$(echo -e "$line" | sed 's/\r//g')
    paths[$index]="$filtered_line"
    ((index+=1))
done

echo -e "Starting Backup..." >> "$LOG_FILEPATH"

for path in ${paths[@]}; do 

    echo -e "\n\n---------------------------------------------------------------------------------------------------------------------------------------------------" >> "$LOG_FILEPATH"
    echo -e "\n-------- BACKING UP: $path ------------------------------------------------------------------------------------------------------------------------\n" >> "$LOG_FILEPATH"
    echo -e "---------------------------------------------------------------------------------------------------------------------------------------------------\n\n" >> "$LOG_FILEPATH"

    # Sync files between two locations, move differing/deleted items to trash directory
    rsync -xavh --progress --delete --backup --backup-dir="$TRASH_PATH" "$path" "$BACKUP_PATH" &>> "$LOG_FILEPATH"

    # Send an error email if rsync exits with non 0 exit code.
    if [ $? -ne 0 ]; then
        HAD_ERROR=$?
        /usr/local/emhttp/webGui/scripts/notify -e "Data Sync Status" -i alert -s "Data Sync Error!!!" -d "Error: rsync exited with error code $? while backup up $path"
    fi

done

#--------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------

#Empties trash share of files/directories older present longer than 30 days or files/directories that are empty
# ------------------------------------------------------------------------------------------------------------
#
#NOTE:
#- Order is important, first delete old files but not directories because there may be additional files in a directory that are not yet deleted so we don't want to delete the entire directory.
#- Only remove directories if they are empty.
#- /mnt/user/trash/* the wildcard (*) makes it so the root/src directory is ignored in this case /trash, so that /trash itself is not deleted by the xargs ... rm -rf

find /mnt/user/trash/* -type f -ctime +30 | xargs -d '\n' rm -rf #Removes files present in trash longer than 30 days
find /mnt/user/trash/* -empty | xargs -d '\n' rm -rf #Removes empty directories and files
echo -e "\nEmpty Trash Complete!" >> "$LOG_FILEPATH"

echo -e "\n\nDone.\n" >> "$LOG_FILEPATH"

#--------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------

#Send Completion Email if no errors occurred
if [ $HAD_ERROR -eq 0 ]; then
	/usr/local/emhttp/webGui/scripts/notify -e "Data Sync Status" -i normal -s "Data Sync Complete!"
fi

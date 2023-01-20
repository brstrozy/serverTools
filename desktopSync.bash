#!/bin/bash

inputFile="/mnt/user/storage/serverConfig/desktop.txt"
HOST="192.168.1.80"
LOG_DIR="/mnt/user/logs/desktopSync/"`date +"%m-%d-%Y"`""
TRASH_PATH="/mnt/user/trash/"
BACKUP_PATH="/mnt/user/desktop/"

LOG_FILEPATH="$LOG_DIR"/desktop-backup.txt""
HAD_ERROR=0

#Make log directory if not exists
mkdir -p "$LOG_DIR"

# INPUT FILE FORMAT: input path alone (no extra space, commas, etc.) or inputpath,outputpath if you need to change the output for specific input paths
file=$(cat $inputFile)

# GET ARRAY OF PATHS FROM file
readarray -t paths < $inputFile

# echo -e "ARRAY: \n"
# for (( i=0; i<=${#paths[@]}; i++ )); do
#     echo "${paths[$i]}" >> "$LOG_FILEPATH"
# done

#--------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------

echo -e "Starting Backup..." >> "$LOG_FILEPATH"

ping -q -c 1 $HOST > /dev/null
SKIP=$?

# ERROR HANDLING IF HOST PC OFFLINE
if [ $SKIP -ne 0 ]; then
    TIME="`date + "%T"`"
    echo -e "[ $TIME ] Error: ping exited with error code $SKIP on host $HOST" >> "$LOG_FILEPATH"
    echo -e "[ $TIME ] Host likely offline" >> "$LOG_FILEPATH"
fi

# BACK UP EACH DIRECTORY IN inputFile
if [ $SKIP -eq 0 ]; then
    for (( i=0; i<=${#paths[@]}; i++ )); do
    
        # SPLIT ROW INTO SRC AND DEST
        path=$( ${paths[$i]} | sed 's/\r//g' )
        pathArray=(`echo $path | tr ',' ' '`)

        echo -e "\n\n---------------------------------------------------------------------------------------------------------------------------------------------------" >> "$LOG_FILEPATH"
        echo -e "\n-------- BACKING UP: ${pathArray[0]} ------------------------------------------------------------------------------------------------------------------------\n" >> "$LOG_FILEPATH"
        echo -e "---------------------------------------------------------------------------------------------------------------------------------------------------\n\n" >> "$LOG_FILEPATH"

        # CHECK FOR CUSTOM DEST, OTHERWISE DEFAULT BACKUP PATH DEST USED
        if [ ${#pathArray[@]} == 1 ]; then
            SRC=${pathArray[0]}
            DEST=$BACKUP_PATH
        else
            SRC=${pathArray[0]}
            DEST=${pathArray[1]}
        fi

        # Sync files between two locations, move differing/deleted items to trash directory
        rsync -xavh --progress --delete --backup --backup-dir="$TRASH_PATH" "$SRC" "$DEST" &>> "$LOG_FILEPATH"

        # Send an error email if rsync exits with non 0 exit code.
        if [ $? -ne 0 ]; then
            HAD_ERROR=$?
            /usr/local/emhttp/webGui/scripts/notify -e "Desktop Sync Status" -i alert -s "Desktop Sync Error!!!" -d "Error: rsync exited with error code $? while backup up ${pathArray[0]}"
        fi

    done
fi

#Create some separation in the log file since this will be run quite frequently
echo -e "\n\n\n\n\n" >> "$LOG_FILEPATH"

#--------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------

#Send Completion Email if no errors occurred
if [ $HAD_ERROR -eq 0 ]; then
	/usr/local/emhttp/webGui/scripts/notify -e "Desktop Sync Status" -i normal -s "Desktop Sync Complete!"
fi

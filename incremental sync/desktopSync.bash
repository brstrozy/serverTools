#!/bin/bash

# CRON SETUP
#run every 5 minutes, flock used to make sure another instance of rsync/script doesn't start while the previous is still running
#
# m h dom mon dow user  command
# 5 * * * * root /usr/bin/flock -w 0 /var/cron.lock /usr/bin/myscript

#--------------------------------------------------------------------------------------------
# VARIABLES
#--------------------------------------------------------------------------------------------

# INPUT FILE FORMAT: input path alone (no extra space, commas, etc.) or inputpath,outputpath if you need to change the output for specific input paths
INPUT_FILE="PATH"
LOG_DIR="PATH/"`date +"%m-%d-%Y"`""
TRASH_PATH="PATH"
BACKUP_PATH="PATH"

LOG_FILEPATH="$LOG_DIR"/desktop-backup.txt""
HAD_ERROR=0

#--------------------------------------------------------------------------------------------
# INIT
#--------------------------------------------------------------------------------------------

#Make log directory if not exists
mkdir -p "$LOG_DIR"

# GET ARRAY OF PATHS FROM file
readarray -t paths < $INPUT_FILE

#--------------------------------------------------------------------------------------------
# BACKUP
#--------------------------------------------------------------------------------------------

echo -e "Starting Backup..." >> "$LOG_FILEPATH"

# BACK UP EACH DIRECTORY IN INPUT_FILE
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
        rsync -xavhi --delete --backup --backup-dir="$TRASH_PATH" "$SRC" "$DEST" &>> "$LOG_FILEPATH"

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


# DISABLED EMAIL SUCCESS DUE TO REPETITIVE NATURE OF INCREMENTAL SYNCING
# #Send Completion Email if no errors occurred
# if [ $HAD_ERROR -eq 0 ]; then
# 	/usr/local/emhttp/webGui/scripts/notify -e "Desktop Sync Status" -i normal -s "Desktop Sync Complete!"
# fi

#!/bin/bash

#Empties trash share of files/directories older present longer than 30 days or files/directories that are empty
# ------------------------------------------------------------------------------------------------------------
#
#NOTE:
#- Order is important, first delete old files but not directories because there may be additional files in a directory that are not yet deleted so we don't want to delete the entire directory.
#- Only remove directories if they are empty.
#- /mnt/user/trash/* the wildcard (*) makes it so the root/src directory is ignored in this case /trash, so that /trash itself is not deleted by the xargs ... rm -rf

BACKUP_DIR="/mnt/user/storage/rsync_logs/"`date +"%m-%d-%Y"`""
BACKUP_PATH="$BACKUP_DIR"/data-backup.txt""

find /mnt/user/trash/* -type f -ctime +30 | xargs -d '\n' rm -rf #Removes files present in trash longer than 30 days
find /mnt/user/trash/* -empty | xargs -d '\n' rm -rf #Removes empty directories and files
echo -e "Empty Trash Complete!" >> "$BACKUP_PATH"

#Send Completion Email
/usr/local/emhttp/webGui/scripts/notify -e "Empty Trash Status" -i normal -s "Trash has been emptied!"
#!/bin/bash

BACKUP_DIR="/mnt/user/storage/minecraft_server_backups/"`date +"%m-%d-%Y"`""
BACKUP_PATH="$BACKUP_DIR"/world_backup_log.txt""
HAD_ERROR=0

SOURCE="/mnt/user/appdata/binhex-minecraftserver/minecraft/world"
MINECRAFT_BACKUP_PATH=""$BACKUP_DIR/""`date +%H`""

#Make backup directory if not exists
mkdir -p "$BACKUP_DIR"
mkdir -p "$MINECRAFT_BACKUP_PATH"

#Backup Movies and TV Shows
echo -e "-------- Backing up Minecraft Server --------\n" &>> "$BACKUP_PATH"

#BACKUP DATA 1
# rsync -xavh --progress --include=world --exclude=/mnt/user/*/ $SOURCE $BACKUP_DIR &>> "$BACKUP_PATH"
rsync -xavh --progress --include=world --exclude=/mnt/user/*/ --delete --backup --backup-dir=$MINECRAFT_BACKUP_PATH $SOURCE $BACKUP_DIR &>> "$BACKUP_PATH"
if [ $? -ne 0 ]; then
	HAD_ERROR=$?
	/usr/local/emhttp/webGui/scripts/notify -e "Minecraft Backup Status" -i alert -s "Minecraft Backup Error!!!" -d "rsync exited with error code $?"
fi

# #Send Completion Email if no errors occurred
# if [ $HAD_ERROR -eq 0 ]; then
# 	/usr/local/emhttp/webGui/scripts/notify -e "Data Sync Status" -i normal -s "Data Sync Complete!"
# fi

#!/bin/bash



LOG_DIR="/var/log/backup_script"

LOG_FILE="$LOG_DIR/history.log"

mkdir -p "$LOG_DIR"


log_message() {
    local TYPE=$1
    local MESSAGE=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $USER : $TYPE : $MESSAGE" | tee -a "$LOG_FILE"
}

# checking usage with --herlp
show_help() {
    echo "usage: ./backup_script.sh [OPTIONS] <source_dir> <backup_dir> [remote_server] [ftp_user] [remote_path]"
    echo ""
    echo "options:"
    echo "  --help            display this help message"
    echo ""
    echo "rguments:"
    echo "  source_dir        path to the directory containing files to backup"
    echo "  backup_dir        path to the local backup directory"
    echo "  remote_server     (optional) address of the remote FTP server"
    echo "  ftp_user          (optional) username for the FTP server"
    echo "  remote_path       (optional) path on the remote server to upload the backup"
    echo ""
    echo "description:"
    echo "  This script automates the process of backing up .txt,"
    echo "  compressing the backup, and uploading it to a remote server."
    echo ""
    echo "example:"
    echo "  ./backup_script.sh /home/user/documents /home/user/backup ftp.example.com ftpuser /backups/server1"
    exit 0
}



if [[ $1 == "--help" ]]; then
    show_help 

fi


if [[ $# -lt 2 ]];  then
    log_message "ERROR" "Not enough arguments provided."
    show_help

fi

SOURCE_DIR=$1

BACKUP_DIR=$2

REMOTE_SERVER=$3

FTP_USER=$4
REMOTE_PATH=${5:-"/"}  



if [[ ! -d "$SOURCE_DIR" ]];   then
    log_message "ERROR" "Source directory $SOURCE_DIR does not exist."
    exit 1


fi



mkdir -p "$BACKUP_DIR"

BACKUP_FILE="$BACKUP_DIR/backup_$(date '+%Y%m%d%H%M%S').tar.gz"

tar -czf "$BACKUP_FILE" "$SOURCE_DIR"/*.txt 2>> "$LOG_FILE"

if [[ $? -eq 0 ]];   then
    log_message "INFOS" "backup created successfully at $BACKUP_FILE."
else
    log_message "ERROR" "failed."
    exit 1

fi



if [[ -n "$REMOTE_SERVER" && -n "$FTP_USER" ]]; then
    log_message "INFOS" "Checking remote server $REMOTE_SERVER..."
    ping -c 1 "$REMOTE_SERVER" &>/dev/null
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "remote server $REMOTE_SERVER is down."
        exit 1
    fi

    log_message "INFOS" "uploading backup to server..."
    ftp -inv "$REMOTE_SERVER" <<EOF &>> "$LOG_FILE"
    user $FTP_USER

    cd "$REMOTE_PATH"

    put "$BACKUP_FILE"

    bye
EOF

    if [[ $? -eq 0 ]]; then
        log_message "INFOS" "backup uploaded successfully to $REMOTE_SERVER:$REMOTE_PATH."
    else
        log_message "ERROR" "failed  backup to $REMOTE_SERVER."

        exit 1
    fi
else
    log_message "INFOS" "Remote server not specified  skipping ftp upload."
fi

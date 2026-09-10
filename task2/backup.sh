#!/bin/bash

echo "Task 2 - Directory Backup Script"
echo

# find the directory this script is in
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log_file="$script_dir/backup.log"
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$log_file"
}
log "Script started"

# Get directory from cmd line or ask user
if [[ $# -eq 1 ]]; then
	source_dir="$1"
	echo "Input received: $source_dir"
	log "Input received: $source_dir"
else
	read -rp "Enter the directory to backup: " source_dir
	echo "Input received: $source_dir"
	log "Input received: $source_dir"
fi

# Check directory exists
if [[ ! -d "$source_dir" ]]; then
	echo "ERROR: Directory does not exist: $source_dir"
	log "ERROR: Directory does not exist: $source_dir"
	exit 1
fi

echo "Source directory exists"
log "SUCCESS: Source directory exists: $source_dir"

# Convert to absolute path
source_dir="$(cd "$source_dir" && pwd)"

directory_name="$(basename "$source_dir")"
parent_dir="$(dirname "$source_dir")"

echo "Source directory: $source_dir"
echo "Directory name: $directory_name"
log "Source directory confirmed: $source_dir"

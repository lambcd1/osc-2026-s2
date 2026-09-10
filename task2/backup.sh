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

# Create timestamp
timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"

# Create backup filename
backup_file="backup-${directory_name}-${timestamp}.tar.gz"
backup_path="$script_dir/$backup_file"

echo
echo "Creating backup:"
echo "	$backup_file"
log "Creating backup: $backup_file"

# Create Zip File
if tar -czf "$backup_path" -C "$parent_dir" "$directory_name"; then
	echo "Backup created successfully"
	log "SUCCESS: Backup created: $backup_path"
else
	echo "ERROR: Failed to create backup"
	log "ERROR: Failed to create backup: $backup_path"
	exit 1
fi

# Check backup file exists
if [[ ! -f "$backup_path" ]]; then
	echo "ERROR: Backup file was not created"
	log "ERROR: Backup file missing after tar command"
	exit 1
fi

# Display backup information
backup_size="$(du -h "$backup_path" | cut -f1)"

echo "Backup file: $backup_path"
echo "Backup size: $backup_size"
log "Backup size: $backup_size"

# Test backup archive integrity - Table Zip File
echo
echo "Testing backup archive"

if tar -tzf "$backup_path" >/dev/null; then
	echo "Backup archive IS valid"
	log "SUCCESS: Backup archive passed integrity test"
else
	echo "ERROR: Backup archive failed integrity test"
	log "ERROR: Backup archive failed integrity test"
	exit 1
fi

# Display archive contents
echo
echo "Backup contents:"
if tar -tzf "$backup_path"; then
	log "SUCCESS: Backup contents displayed"
else
	echo "ERROR: Failed to read backup contents"
	log "ERROR: Failed to read backup contents"
	exit 1
fi














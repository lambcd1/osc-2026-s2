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
timestamp="$(date '+%Y-%m-%d')"

# Create backup filename
backup_file="backup-${timestamp}.tar.gz"
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


# Get remote connection details
echo
echo "Remote backup destination"

read -rp "Enter remote IP address or hostname: " remote_host

if [[ -z "$remote_host" ]]; then
	echo "ERROR: Remote host cannot be empty"
	log "ERROR: Remote host was empty"
	exit 1
fi

read -rp "Enter SSH port (press Enter for 22): " remote_port

if [[ -z "$remote_port" ]]; then
	remote_port=22
fi

# Check port contains only numbers
if [[ ! "$remote_port" =~ ^[0-9]+$ ]]; then
	echo "ERROR: Invalid SSH port: $remote_port"
	log "ERROR: Invalid SSH port: $remote_port"
	exit 1
fi

read -rp "Enter remote username: " remote_user

if [[ -z "$remote_user" ]]; then
	echo "ERROR: Remote username cannot be empty"
	log "ERROR: Remote username was empty"
	exit 1
fi

read -rp "Enter remote destination directory: " remote_dir

if [[ -z "$remote_dir" ]]; then
	echo "ERROR: Remote destination directory cannot be empty"
	log "ERROR: Remote destination directory was empty"
	exit 1
fi

echo
echo "Remote host: $remote_host"
echo "Remote port: $remote_port"
echo "Remote user: $remote_user"
echo "Remote directory: $remote_dir"
log "Remote destination: $remote_user@$remote_host:$remote_dir"
log "Remote SSH port: $remote_port"

# Check remote host is reachable over SSH
echo
echo "Checking remote connection..."

if ssh -p "$remote_port" -o ConnectTimeout=10 \
	"$remote_user@$remote_host" "true"; then
	echo "Remote connection successful"
	log "SUCCESS: Remote SSH connection established"
else
	echo "ERROR: Unable to connect to remote host"
	log "ERROR: Unable to connect to remote host"
	exit 1
fi

# Check remote destination directory
echo
echo "Checking remote destination directory..."

if ssh -p "$remote_port" \
	"$remote_user@$remote_host" "test -d '$remote_dir'"; then
	echo "Remote destination directory exists"
	log "SUCCESS: Remote destination exists: $remote_dir"
else
	echo "ERROR: Remote destination directory does not exist or is inaccessible"
	log "ERROR: Remote destination unavailable: $remote_dir"
	exit 1
fi

# Upload backup
echo
echo "Uploading backup..."
log "Uploading backup: $backup_file"

if scp -P "$remote_port" "$backup_path" \
	"$remote_user@$remote_host:$remote_dir/"; then
	echo "Backup uploaded successfully"
	log "SUCCESS: Backup uploaded to $remote_user@$remote_host:$remote_dir"
else
	echo "ERROR: Failed to upload backup"
	log "ERROR: Backup upload failed: $backup_file"
	exit 1
fi

# Verify backup exists remotely
echo
echo "Verifying remote backup..."

remote_backup="$remote_dir/$backup_file"

if ssh -p "$remote_port" \
	"$remote_user@$remote_host" "test -f '$remote_backup'"; then
	echo "Remote backup verified successfully"
	log "SUCCESS: Remote backup verified: $remote_backup"
else
	echo "ERROR: Remote backup could not be verified"
	log "ERROR: Remote backup verification failed: $remote_backup"
	exit 1
fi

echo
echo "========================================"
echo "BACKUP COMPLETE"
echo "========================================"
echo "Source: $source_dir"
echo "Backup: $backup_file"
echo "Remote: $remote_user@$remote_user@$remote_host:$remote_dir"
echo

log "Script completed successfully"











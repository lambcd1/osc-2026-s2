#!/bin/bash

echo "Task 1 - User Environment Cleanup"
echo

# delete previous log file
#if [[ -f create_users.log ]]; then
#	rm create_users.log

users=(
	sAlice
	jBob
	wCarol
	nDave
)

for username in "${users[@]}"
do
	echo
	echo "Checking user: $username"

	if id "$username" &>/dev/null; then
		echo "	User exists - removing user and home directory"
		if sudo userdel -r "$username"; then
			echo "	User $username removed successfully"
		else
			echo "	ERROR: Failed to remove user $username"
		fi
	else
		echo "	User $username does not exist - skipping"
	fi
done

echo
echo "Removing test groups"

groups=(
    dev
    intern
    docker
)

for group_name in "${groups[@]}"
do
    echo
    echo "Checking group: $group_name"

    if getent group "$group_name" &>/dev/null; then
        echo "    Group exists - removing"

        if sudo groupdel "$group_name"; then
            echo "    Group $group_name removed successfully"
        else
            echo "    ERROR: Failed to remove group $group_name"
        fi
    else
        echo "    Group $group_name does not exist - skipping"
    fi
done

shared_folders=(
    /opt/staffData
    /opt/internData
)

for folder in "${shared_folders[@]}"

do
	echo
	echo "Checking shared folder: $folder"

	if [[ -d "$folder" ]]; then

		echo "    Shared folder exists - removing"

		if sudo rm -rf "$folder"; then
			echo "    Shared folder $folder removed successfully"
		else
			echo "    ERROR: Failed to remove shared folder $folder"
		fi
	else
		echo "    Shared folder $folder does not exist - skipping"
	fi
done

echo
echo "Cleanup complete"

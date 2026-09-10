#!/bin/bash

echo "Task 1 - User Environment Cleanup"
echo

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
echo "Cleanup complete"

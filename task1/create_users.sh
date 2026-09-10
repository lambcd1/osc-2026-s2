#!/bin/bash

echo "Task 1 - User Environment Script"
echo

# find the directory this script is in
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Get CSV path or URI from cmd line
# or ask user if no arg provided
if [[ $# -eq 1 ]]; then
	input="$1"
	echo "Input received: $input"
else
	read -rp "Enter a local CSV path or URI: " input
	echo "Input received: $input"
fi

# Check which input type (web or local)
if [[ "$input" == http://* || "$input" == https://* ]]; then
	echo "Remote URI detected: $input"

	# download to the same directory as this with curl
	filename=$(basename "$input")
	curl -fl -o "$script_dir/$filename" "$input"

	if [[ $? -eq 0 && -f "$script_dir/$filename" ]]; then
		echo "Remote file downloaded successfully: $filename"
		csv_file="$script_dir/$filename"
	else
		echo "ERROR: Failed to download remote file"
		exit 1
	fi
else
	echo "Local file detected: $input"

	if [[ -f "$input" ]]; then
		echo "Local file exists"
		csv_file="$input"
	else
		echo "ERROR: Local file does not exist"
		exit 1
	fi
fi

# Check csv file is not empty, read the header
if [[ ! -s "$csv_file" ]]; then
	echo "ERROR: CSV file IS empty"
	exit 1
fi

echo "CSV file IS NOT empty"

header=$(head -n 1 "$csv_file")

echo "CSV header:"
echo "$header"

if [[ "$header" != "email,birth_date,groups,shared_folder" ]]; then
	echo "ERROR: Invalid CSV header"
	exit 1
fi
echo "CSV header is valid"


get_username() {
	# -d cut delimiter
	# -f cut field selector
	# -c cut character selector
	first_name=$(echo "$email" | cut -d'.' -f1)
	surname=$(echo "$email" | cut -d'@' -f1 | cut -d'.' -f2)
	first_letter=$(echo "$surname" | cut -c1)

	# sed = stream editor. ^. selects first char, U& uppercases it
	first_name_capital=$(echo "$first_name" | sed 's/^./\U&/')
	username="${first_letter}${first_name_capital}"

	echo "$username"
}

create_group() {
	# first field is the one variable fed into the function call
	group_name="$1"

	# return 0 means success
	if [[ -z "$group_name" ]]; then
		return 0
	fi

	if getent group "$group_name" &>/dev/null; then
		echo "	Group already exists: $group_name"
	else
		if sudo groupadd "$group_name"; then
			echo "	Group created: $group_name"
		else
			echo "	ERROR: Failed to create group: $group_name"
			# return 1 for failure
			return 1
		fi
	fi
}

# initialise count for user creation
users_to_add=0

	# Internal Field Seperator parses the CSV,
while IFS=',' read -r -a fields
do
	# refresh each time so previous one doesnt pollute current one
	group=""
	shared_folder=""

	email="${fields[0]}"
	birth_date="${fields[1]}"
	group="${fields[2]}"
	shared_folder="${fields[3]}"

	# input smoothing - subgroups, empty, shared folder?
	if [[ "${fields[3]}" == /* ]]; then
		shared_folder="${fields[3]}"
	elif [[ -z "${fields[3]}" ]]; then
		shared_folder=""
	else
		subgroup="${fields[3]}"
		shared_folder="${fields[4]}"
	fi

	echo
	echo "Processing user:"
	echo "	Email: $email"
	echo "	Birth Date: $birth_date"
	echo "	Groups: $group"
	echo "	Shared folder: $shared_folder"

	# formats date and checks if its valid
	if date -d "$birth_date" '+%Y/%m/%d' >/dev/null 2>&1 &&
		[[ "$(date -d "$birth_date" '+%Y/%m/%d')" == "$birth_date" ]]; then
		echo "	Birth date format IS valid"
	else
		echo " ERROR: Invalid birth date format"
		continue
	fi

	# call username generator function
	username=$(get_username "$email")
	echo "	Username: $username"

	birth_year=$(echo "$birth_date" | cut -d'/' -f1)
	birth_month=$(echo "$birth_date" | cut -d'/' -f2)
	default_password="${birth_year}${birth_month}"

	echo "	Default password: $default_password"

	# check existing username before gen - &> redirects stdoutput and stderror to same destination
	if id "$username" &>/dev/null; then
		echo "	Username already exists - skipping user creation"
	else
		echo "	Username available - can create user"
		((users_to_add++))
	fi

	# right arrow outputs the bracketed command
	# left arrow puts it into the loop
done < <(tail -n +2 "$csv_file")

echo
echo "Number of users to be added: $users_to_add"

read -rp "Continue with user creation? (y/n): " confirmation

if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
	echo "User creation cancelled"
	exit 0
fi

echo "User creation confirmed"


# Create users after confirmation
while IFS=',' read -r -a fields
do
	email="${fields[0]}"
	birth_date="${fields[1]}"
	group="${fields[2]}"
	shared_folder="${fields[3]}"

	username=$(get_username "$email")

	birth_year=$(echo "$birth_date" | cut -d'/' -f1)
	birth_month=$(echo "$birth_date" | cut -d'/' -f2)
	default_password="${birth_year}${birth_month}"

	# skip users that already existed
	if id "$username" &>/dev/null; then
		echo "Skipping existing user: $username"
		continue
	fi

	echo
	echo "Creating user: $username"

	if sudo useradd -m -s /bin/bash "$username"; then
		echo "	User created successfully"
	else
		echo "	ERROR: Failed to create user"
		continue
	fi

	# key value pair so password isnt exposed on cmd line
	if echo "$username:$default_password" | sudo chpasswd; then
		echo "	Default password set successfully"
	else
		echo "	ERROR: Failed to set default password"
		continue
	fi

	# default password first login force chage
	if sudo chage -d 0 "$username"; then
		echo "	Password change at first login enabled"
	else
		echo "	ERROR: Failed to enforce password change"
	fi

	# create and assign groups
	if [[ -n "$group" ]]; then
		IFS=':' read -ra groups <<< "$group"
		for group_name in "${groups[@]}"
		do
			if create_group "$group_name"; then
				if sudo usermod -aG "$group_name" "$username"; then
					echo "	User added to group: $group_name"
				else
					echo "	ERROR: Failed to add user to group: $group_name"
				fi
			fi
		done
	fi

	# create myls alias for sudo users
	if [[ ":$group:" == *":sudo:"* ]]; then
		alias_file="/home/$username/.bash_aliases"
		echo "alias myls='ls -la ~'" | sudo tee -a "$alias_file" > /dev/null
		sudo chown "$username:$username" "$alias_file"
		echo "	myls alias created for sudo user"
	fi

	# check and create shared folder
	if [[ -n "$shared_folder" ]]; then
		if [[ -d "$shared_folder" ]]; then
			echo "	Shared folder already exists: $shared_folder"
		else
			if sudo mkdir -p "$shared_folder"; then
				echo "	Shared folder created: $shared_folder"
			else
				echo "	ERROR: Failed to create shared folder: $shared_folder"
			fi
		fi
	fi

	# set shared folder group ownership and permissions
	if [[ -n "$shared_folder" ]]; then
		if [[ "$shared_folder" == "/opt/staffData" ]]; then
			folder_group="dev"
		elif [[ "$shared_folder" == "/opt/internData" ]]; then
			folder_group="intern"
		fi

		if sudo chown "root:$folder_group" "$shared_folder"; then
			echo "	Shared folder group set to: $folder_group"
		else
			echo "	ERROR: Failed to set shared folder group"
		fi

		if sudo chmod 770 "$shared_folder"; then
			echo "	Shared folder permissions set to 770"
		else
			echo "	ERROR: Failed to set shared folder permissions"
		fi
	fi

	# create shared folder symbolic link in user's home
	if [[ -n "$shared_folder" ]]; then
		shared_link="/home/$username/shared"
		if [[ -L "$shared_link" ]]; then
			echo "	Shared link already exists: $shared_link"
		else
			if sudo ln -s "$shared_folder" "$shared_link"; then
				echo "	Shared link created: $shared_link -> $shared_folder"
			else
				echo "	ERROR: Failed to create shared link: $shared_link"
			fi
		fi
	fi

done < <(tail -n +2 "$csv_file")





# Potential Problems:
#
#






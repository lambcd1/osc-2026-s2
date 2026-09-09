#!/bin/bash

echo "Task 1 - User Environment Script"
echo

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

	# download to the same directory as this
	filename=$(basename "$input")
	curl -o "$filename" "$input"

	if [[ -f "$filename" ]]; then
		echo "Remote file downloaded successfully: $filename"
	else
		echo "ERROR: Failed to download remote file"
	fi
else
	echo "Local file detected: $input"

	if [[ -f "$input" ]]; then
		echo "Local file exists"
		csv_file="$input"
	else
		echo "ERROR: Local file does not exist"
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

	# Internal Field Seperator parses the CSV, 
tail -n +2 "$csv_file" | while IFS=',' read -r -a fields
do
	email="${fields[0]}"
	birth_date="${fields[1]}"
	group="${fields[2]}"

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
	echo "	Group: $group"
	echo "	Subgroup: $subgroup"
	echo "	Shared folder: $shared_folder"

	# =~ checks if right side matches left side of equals (regex)
	if [[ "$birth_date" =~ ^[0-9]{4}/[0-9]{2}/[0-9]{2}$ ]]; then
		echo "	Birth date format IS valid"
	else
		echo " ERROR: Invalid birth date format"
	fi

	# username generation with cut
		# -d cut delimiter
		# -f cut field selector
		# -c cut character selector
	first_name=$(echo "$email" | cut -d'.' -f1)
	surname=$(echo "$email" | cut -d'@' -f1 | cut -d'.' -f2)
	first_letter=$(echo "$surname" | cut -c1)

	# sed = stream editor. ^. selects first char, U& uppercases it
	first_name_capital=$(echo "$first_name" | sed 's/^./\U&/')
	username="${first_letter}${first_name_capital}"

	echo "	Username: $username"

	# check existing username before gen - &> redirects stdoutput and stderror to same destination
	if id "$username" &>/dev/null; then
		echo "	Username already exists - skipping user creation"
	else
		echo "	Username available - can create user"
	fi

	birth_year=$(echo "$birth_date" | cut -d'/' -f1)
	birth_month=$(echo "$birth_date" | cut -d'/' -f2)
	default_password="${birth_year}${birth_month}"

	echo "	Default password: $default_password"
done


























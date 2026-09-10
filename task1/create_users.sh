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

	# download to the same directory as this
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

if [[ "$header" != "email,birth date,groups,sharedFolder" ]]; then
	echo "ERROR: Invalid CSV header"
	exit 1
fi
echo "CSV header is valid"

	# Internal Field Seperator parses the CSV,
while IFS=',' read -r -a fields
do
	# refresh each time so previous one doesnt pollute current one
	group=""
	subgroup=""
	shared_folder=""

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

	# formats date and checks if its valid
	if date -d "$birth_date" '+%Y/%m/%d' >/dev/null 2>&1 &&
		[[ "$(date -d "$birth_date" '+%Y/%m/%d')" == "$birth_date" ]]; then
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

	# right arrow outputs the bracketed command
	# left arrow puts it into the loop
done < <(tail -n +2 "$csv_file")


























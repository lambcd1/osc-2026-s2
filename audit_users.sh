#!/bin/bash

csv_file="${1:-users.csv}"

records=0
compliant=0
fixed=0
failed=0

log() {
    local message="$1"
    echo "[$(date '+%F %T')] $message" >> /var/log/user_audit.log
}

while IFS=',' read -r username groupname shell; do

    # Skips
    [[ -z "$username" && -z "$groupname" && -z "$shell" ]] && continue
    [[ "$username" == \#* ]] && continue
	    # remove invisible char from username causing failure
    username="${username#$'\ufeff'}"
	    # ignore csv header
    [[ "$username" == "username" && "$groupname" == "groupname" && "$shell" == "shell" ]] && continue

    (( records++ ))

    # records empty
    if [[ -z "$username" || -z "$groupname" || -z "$shell" ]]; then
        log "ERROR: empty field in record"
        (( failed++ ))
        continue
    fi

    # invalid usernames
    if [[ ! "$username" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
        log "ERROR: invalid username '$username'"
        (( failed++ ))
        continue
    fi

    # Check account exists shell matches
    if id "$username" &> /dev/null; then
        current_shell=$(getent passwd "$username" | cut -d: -f7)

        if [[ "$current_shell" == "$shell" ]]; then
            log "COMPLIANT: '$username' shell is '$shell'"
            (( compliant++ ))
        else
            if usermod -s "$shell" "$username"; then
                log "FIXED: '$username' shell changed from '$current_shell' to '$shell'"
                (( fixed++ ))
            else
                log "ERROR: failed to change '$username' shell from '$current_shell' to '$shell'"
                (( failed++ ))
            fi
        fi

    else
        if useradd -m -s "$shell" "$username"; then
            log "FIXED: created '$username' with shell '$shell'"
            (( fixed++ ))
        else
            log "ERROR: failed to create '$username'"
            (( failed++ ))
            continue
        fi
    fi

    # Check group exists
    if getent group "$groupname" &> /dev/null; then
        log "COMPLIANT: group '$groupname' exists"
        (( compliant++ ))
    else
        if groupadd "$groupname"; then
            log "FIXED: created group '$groupname'"
            (( fixed++ ))
        else
            log "ERROR: failed to create group '$groupname'"
            (( failed++ ))
            continue
        fi
    fi

    # Check already member
    if id -nG "$username" | grep -qw "$groupname"; then
        log "COMPLIANT: '$username' is a member of '$groupname'"
        (( compliant++ ))
    else
        if usermod -aG "$groupname" "$username"; then
            log "FIXED: added '$username' to '$groupname'"
            (( fixed++ ))
        else
            log "ERROR: failed to add '$username' to '$groupname'"
            (( failed++ ))
        fi
    fi

    # Check home
    home="/home/$username"

    if [[ ! -d "$home" ]]; then
        if mkdir -p "$home"; then
            log "FIXED: home directory for '$username' was missing"
            (( fixed++ ))
        else
            log "ERROR: failed to create home directory for '$username'"
            (( failed++ ))
            continue
        fi

        if chown "$username:$username" "$home"; then
            log "FIXED: home directory for '$username' had wrong owner"
            (( fixed++ ))
        else
            log "ERROR: failed to set owner of '$home'"
            (( failed++ ))
        fi

        if chmod 700 "$home"; then
            log "FIXED: home directory for '$username' had wrong permissions"
            (( fixed++ ))
        else
            log "ERROR: failed to set permissions on '$home'"
            (( failed++ ))
        fi
    else
        owner=$(stat -c '%U' "$home")
        permissions=$(stat -c '%a' "$home")

        if [[ "$owner" != "$username" ]]; then
            if chown "$username:$username" "$home"; then
                log "FIXED: home directory for '$username' had wrong owner '$owner'"
                (( fixed++ ))
            else
                log "ERROR: failed to fix owner of '$home'"
                (( failed++ ))
            fi
        else
            log "COMPLIANT: home directory for '$username' has correct owner"
            (( compliant++ ))
        fi

        if [[ "$permissions" != "700" ]]; then
            if chmod 700 "$home"; then
                log "FIXED: home directory for '$username' had wrong permissions '$permissions'"
                (( fixed++ ))
            else
                log "ERROR: failed to fix permissions on '$home'"
                (( failed++ ))
            fi
        else
            log "COMPLIANT: home directory for '$username' has mode 700"
            (( compliant++ ))
        fi
    fi

done < "$csv_file"

echo "AUDIT SUMMARY"
echo "Records read : $records"
echo "Already compliant : $compliant"
echo "Remediated : $fixed"
echo "Failed : $failed"

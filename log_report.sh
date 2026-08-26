#!/bin/bash
# log_report.sh - summarise a syslog file
# Usage: ./log_report.sh [logfile]

LOG="${1:-sys_log.txt}"
REPORT="log_report.txt"

# Check: Exists
if [[ ! -f "$LOG" ]]; then
    echo "Error: file does not exist: $LOG" >&2
    exit 1
fi

# Check: Readable
if [[ ! -r "$LOG" ]]; then
    echo "Error: file is not readable: $LOG" >&2
    exit 1
fi

# Check: Not Empty
if [[ ! -s "$LOG" ]]; then
    echo "Error: file is empty: $LOG" >&2
    exit 1
fi

# > replaces, >> appends. this doesnt append
{
    echo "=============================================="
    echo " SYSTEM LOG REPORT"
    echo " Generated : $(date '+%Y-%m-%d %H:%M:%S')"
    echo " Log file : $LOG"
    echo "=============================================="
} > "$REPORT"


# tee goes both to terminal and the report file
say() {
    echo "$1" | tee -a "$REPORT"
}

say ""
	# this line counts newlines - the last line doesnt make a newline so its count -1...
say "Total lines analysed: $(wc -l < "$LOG")"
say ""
say "ACTIVITY BY SERVICE"
awk '{print $5}' "$LOG" | sed 's/\[[0-9]*\]//; s/:$//' | sort | uniq -c | sort -rn | tee -a "$REPORT"
say ""

# select error terms
filtered=$(grep -iE "error|fail|critical|denied|warning" "$LOG")

total=$(wc -l < "$LOG")

# grep = search, -c = count, . = any
problems=$(echo "$filtered" | grep -c .)
percent=$(( problems * 100 / total ))

say ""
say "PROBLEM LINES: $problems of $total ($percent%)"
say ""
say "TOP 5 SERVICES BY PROBLEM LINES"

echo "$filtered" | awk '{print $5}' | sed 's/\[[0-9]*\]//; s/:$//' | sort | uniq -c | sort -rn | head -5 | tee -a "$REPORT"
say ""




#!/bin/bash

has_vowel() {
    local filename="$1"
    if [[ "$filename" =~ [aeiouAEIOU] ]]; then
	return 0;
    else
        return 1;
    fi
}

is_modified_since_last_backup() {
    local file="$1"
    local last_backup_time="$2"
    local file_mtime=$(stat -c %Y "$file")

    if ((file_mtime > last_backup_time)); then
        return 0;
    else
        return 1;
    fi
}

# Main script
while getopts "s:d:o:" opt; do
    case $opt in
        s) source_dir="$OPTARG" ;;
        d) dest_dir="$OPTARG" ;;
        o) stats_file="$OPTARG" ;;
        \?) echo "Option not supported -$OPTARG" >&2; exit 1 ;;
    esac
done

# Create backup dir
backup_dir="$dest_dir/backup_$(date +'%Y-%m-%d_%H-%M-%S')"
mkdir -p "$backup_dir"

# Store metadata
start_time=$(date +%s)


# Last backup logic
timestamps_file="backup_timestamps.txt";
if [ ! -s "$timestamps_file" ]; then
    echo "Timestamps file does not exist yet. Creating..."
    touch "./backup_timestamps.txt"
fi

last_backup_time=$(tail -n 1 "$timestamps_file")

if [ -z "$last_backup_time" ]; then
    echo "Failed to read the last timestamp from the file. Using -30 days as fallback"
    last_backup_time=$(date --date "-30 days" +%s)
fi

# Get script PID
script_pid=$$

# Iterate through files in source directory
find "$source_dir" -type f | while read -r file; do
    filename=$(basename "$file")
    relative_path="${file#$source_dir/}"
    final_dir="$(dirname "$backup_dir/$relative_path")"

	if has_vowel "$filename" && is_modified_since_last_backup "$file" "$last_backup_time"; then
		mkdir -p "$final_dir";
		cp "$file" "$final_dir";
     fi
done

# Some more metadata
end_time=$(date +%s)
runtime=$((end_time - start_time))
echo "$end_time" >> "$timestamps_file"


# Write to the  stats file
echo "PID: $script_pid, Start Time: "$start_time", End Time: "$end_time",  Runtime: $runtime seconds" >> "$stats_file"

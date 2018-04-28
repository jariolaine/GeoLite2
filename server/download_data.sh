#!/bin/bash

# Enviroment variables
PATH="/bin:/usr/bin"

# Remote server download URL
BASE_URL="http://geolite.maxmind.com/download/geoip/database"

# Local data directory
DATA_DIR="${1%/*}"

# File name
FILE_NAME="${1##*/}"

# Log file
LOG_FILE="${DATA_DIR%/*}/log/${FILE_NAME%.*}.log"

# Local file date before download from remote server
OLD_FILE_DATE="$(stat -c %y $1)"

# Download file from remote server if it's changed and write log
wget -N -P $DATA_DIR $BASE_URL/$FILE_NAME 2> $LOG_FILE

# Local file date after download from remote server
NEW_FILE_DATE="$(stat -c %y $1)"

# Check if local file date is changed
if [[ $OLD_FILE_DATE != $NEW_FILE_DATE ]]
then

	# Extract data files from new zip file
	unzip -jo $1 -d $DATA_DIR	>> $LOG_FILE

fi

# Output file date for Oracle external table
echo "\"$FILE_NAME\",\"$NEW_FILE_DATE\""

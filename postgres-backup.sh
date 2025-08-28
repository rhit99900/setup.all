#!/bin/bash

# Set the environment variables
DB_HOST="your_db_host"
DB_NAME="your_db_name"
DB_USER="your_db_user"
DB_PASSWORD="your_db_password"
S3_BUCKET="your_s3_bucket_name"
S3_PATH="s3://$S3_BUCKET/backup_$(date +'%Y-%m-%d').sql.gz"

# Export the PostgreSQL password (so pg_dump won't ask for it)
export PGPASSWORD=$DB_PASSWORD

# Generate the backup file
BACKUP_FILE="/tmp/backup_$(date +'%Y-%m-%d').sql.gz"

echo "Starting backup for database: $DB_NAME"

# Dump the database and compress it
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME | gzip > $BACKUP_FILE

# Check if the backup was created successfully
if [ $? -eq 0 ]; then
    echo "Backup created successfully: $BACKUP_FILE"
else
    echo "Failed to create backup for database: $DB_NAME"
    exit 1
fi

# Upload the backup to S3
echo "Uploading backup to S3: $S3_PATH"
aws s3 cp $BACKUP_FILE $S3_PATH

# Check if the upload was successful
if [ $? -eq 0 ]; then
    echo "Backup uploaded successfully to $S3_PATH"
    # Optionally, you can remove the local backup file after upload
    rm $BACKUP_FILE
else
    echo "Failed to upload backup to S3"
    exit 1
fi

#/bin/bash
mysqldump=/usr/bin/mysqldump
aws=/usr/local/bin/aws

# Get current date
current_date=$(date +%Y%m%d)

DB_USER='root' #example dbusermm
DB_PASS='WCqkG6@$d9C5' #example 123password

S3_BUCKET_NAME="srv-mysql-idstar-backup"
S3_BUCKET_PATH="s3://srv-mysql-idstar-backup" #example s3://example-backup

#Backup location
BACKUP_DIR="/tmp/mysqldump" #example /tmp/dbdump
mkdir -p $BACKUP_DIR

#Create Credential File
MYSQL_CONFIG=/tmp/mysqldump/mysql-credentials.cnf

cat <<EOF > $MYSQL_CONFIG
[client]
user=$DB_USER
password=$DB_PASS
EOF

# Get a list of all databases
databases=$(mysql --defaults-extra-file=$MYSQL_CONFIG -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)")

# Loop through each database and create a separate backup
for db in $databases; do
    # Define the output file path
    output_file="$BACKUP_DIR/$db-$(date +%Y%m%d%H%M%S).sql"

    # Perform the backup using mysqldump and compress with gzip
    mysqldump --defaults-extra-file=$MYSQL_CONFIG --databases $db | gzip > $output_file.gz

    # Check if the backup was successful
    if [ $? -eq 0 ]; then
        echo "Backup of database '$db' completed successfully."
    else
        echo "Error creating backup of database '$db'."
    fi
done

echo $BACKUP_DEST

sudo rm $MYSQL_CONFIG

#Uploading database dump to AWS S3
echo "Checking AWS S3 connection..."
aws s3 ls $S3_BUCKET_NAME

echo "Uploading mysqldump to AWS S3"
aws s3 sync $BACKUP_DIR $S3_BUCKET_PATH

#Cleaning temporary file
echo "Cleaning temporary file"
sudo rm $BACKUP_DIR/*

echo "Database has been backed up to AWS S3"

#/bin/bash
MYSQLDUMP=/opt/bitnami/mysql/bin/mysqldump

#Timestamp
TIME=`/bin/date +%d-%m-%Y-%T`

DB_USER='YOUR_DB_USERNAME' #example dbusermm
DB_PASS='YOUR_DB_PASS' #example 123password
DB_NAME='YOUR_DB_NAME' #example bitnami_example

S3_BUCKET_NAME="example-backup"
S3_BUCKET_PATH="s3://example-backup/mysqldump/" #example s3://example-backup/mysqldump/

#Backup Filename
FILENAME=${DB_NAME}_${TIME}

#Backup location
BACKUP_DIR="/tmp/mysqldump" #example /tmp/dbdump
BACKUP_PATH="$BACKUP_DIR/$FILENAME.sql.gz"
mkdir -p $BACKUP_DIR

#Create Credential File
DB_ACCESS=./tmp/mysqldump/mysql-credentials.cnf

cat <<EOF > $DB_ACCESS
[client]
user=$DB_USER
password=$DB_PASS
EOF

echo $BACKUP_DEST

echo "Database dump $DB_NAME..."
#mysqldump -u [user name] –p [password] [options] [database_name] [tablename] > [dumpfilename.sql]
#login database via credential file for more secure access

$MYSQLDUMP --defaults-extra-file=$DB_ACCESS $DB_NAME | gzip > $BACKUP_PATH

echo "Checking AWS S3 connection..."
aws s3 ls $S3_BUCKET_NAME

echo "Uploading mysqldump to AWS S3"
aws s3 cp $BACKUP_PATH $S3_BUCKET_PATH

#Cleaning temporary file
echo "Cleaning temporary file"
sudo rm $BACKUP_DIR/*

echo "Backup available at $S3_BUCKET_PATH$FILENAME.sql.gz"

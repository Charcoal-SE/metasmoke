#!/bin/bash

METASMOKE_ROOT=/var/railsapps/metasmoke
timestamp=$(date +%s)
filename=dump_metasmoke-$timestamp.sql.gz
username=$1
password=$2

echo "CREATE DATABASE dump_metasmoke" | mysql -u $username --password=$password
mysqldump -u $username --password=$password metasmoke | mysql -u $username --password=$password dump_metasmoke;
mysql -u $username --password=$password dump_metasmoke < $METASMOKE_ROOT/current/dump/redact.sql
mysqldump -u $username --password=$password dump_metasmoke | gzip > $METASMOKE_ROOT/shared/dumps/$filename
echo "DROP DATABASE dump_metasmoke;" | mysql -u $username --password=$password

# Remove old dumps
ls -d $METASMOKE_ROOT/shared/dumps/* | grep -v $filename | xargs rm

#!/bin/bash

METASMOKE_ROOT=/var/railsapps/metasmoke
timestamp=$(date +%s)
filename=dump_metasmoke-$timestamp.sql.gz

echo "CREATE DATABASE dump_metasmoke" | mysql -u root
mysqldump -u root metasmoke | mysql -u root dump_metasmoke;
mysql -u root dump_metasmoke < $METASMOKE_ROOT/current/dump/redact.sql
mysqldump -u root dump_metasmoke | gzip > $METASMOKE_ROOT/shared/dumps/$filename
echo "DROP DATABASE dump_metasmoke;" | mysql -u root

# Remove old dumps
ls -d $METASMOKE_ROOT/shared/dumps/* | grep -v $filename | xargs rm

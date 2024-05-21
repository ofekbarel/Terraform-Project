#!/bin/bash

sudo apt update

sudo apt install postgresql postgresql-contrib -y

sudo -u postgres psql -c "CREATE DATABASE terraform"

sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'Ofek123456789';"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE terraform TO postgres;"

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf

echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf >/dev/null

sudo restart postgresql
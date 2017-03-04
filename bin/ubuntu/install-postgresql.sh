#!/usr/bin/env bash

sudo apt-get -y install postgresql postgresql-contrib

sudo -u postgres psql -c "CREATE USER vagrant WITH PASSWORD 'vagrant';"

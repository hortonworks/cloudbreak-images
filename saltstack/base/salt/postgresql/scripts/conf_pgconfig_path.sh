#!/usr/bin/env bash

echo "Updating /etc/environment to include PostgreSQL binaries on the path..."    
cat /etc/environment
sed -e '/^PATH/s/"$/:\/usr\/pgsql-11\/bin"/g' -i /etc/environment
cat /etc/environment

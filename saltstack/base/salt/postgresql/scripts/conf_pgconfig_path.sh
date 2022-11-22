#!/usr/bin/env bash

echo "Updating /etc/environment to include PostgreSQL binaries on the path..."    
cat /etc/environment
echo 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/pgsql-11/bin' >>/etc/environment
cat /etc/environment

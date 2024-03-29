#!/usr/bin/env bash

if [ "$SUBTYPE" == "Docker" ]; then
    # inside docker container
    CONFIG_FILE=$(find /etc/postgresql /var/lib/pgsql -type f -name postgresql.conf 2>/dev/null | head -1)
else
    CONFIG_FILE=$(psql -c "show config_file;" -t | xargs)
    echo "Config file: $CONFIG_FILE"
fi

set -e
if grep -qR "^listen_addresses =" $CONFIG_FILE; then
    echo "Updating listen_addresses config in the postgresql.conf"
    sed -i.orig "/^listen_addresses =/c\listen_addresses = '*'" $CONFIG_FILE
else
    echo "Adding listen_addresses config to the postgresql.conf"
    echo "listen_addresses = '*'" >> $CONFIG_FILE
fi
set +e

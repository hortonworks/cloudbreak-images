#!/bin/bash

set -x

: ${PARCEL_REPO:=/opt/cloudera/parcel-repo}

parcels=("$PARCEL_REPO"/*.parcel)

for parcel in "${parcels[@]}"; do
	if [[ -f "${parcel}.torrent" ]]; then
		echo "$parcel torrent already exists, skip"
	else
		/usr/local/bin/py3createtorrent "${parcel}" -v -P -o "${parcel}.torrent"
		touch "${parcel}".skiphash
		rm -f "${parcel}"
		touch "${parcel}"
	fi
done

chown -R cloudera-scm:cloudera-scm ${PARCEL_REPO}

echo "Torrent creation successful" >> /tmp/create_torrent.status
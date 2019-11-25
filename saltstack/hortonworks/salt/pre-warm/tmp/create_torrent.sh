#!/bin/bash

set -x

: ${PARCEL_REPO:=/opt/cloudera/parcel-repo}

parcels=("$PARCEL_REPO"/*.parcel)

for parcel in "${parcels[@]}"; do
	mktorrent -l 19 -v -p -a "" -o "${parcel}.torrent" "${parcel}";
	touch "${parcel}".skiphash
done

chown cloudera-scm:cloudera-scm ${PARCEL_REPO}/*.torrent
chown cloudera-scm:cloudera-scm ${PARCEL_REPO}/*.skiphash

echo "Torrent creation successful" >> /tmp/create_torrent.status
#!/bin/bash

set -x

: ${PARCEL_REPO:=/opt/cloudera/parcel-repo}

parcels=("$PARCEL_REPO"/*.parcel)

for parcel in "${parcels[@]}"; do
	if [[ -f "${parcel}.torrent" ]]; then
		echo "$parcel torrent already exists, skip"
	else
		if [[ "$OS" == "redhat9" ]]; then
			#pip3 install py3createtorrent
			/usr/local/bin/py3createtorrent "${parcel}" -v -P -o "${parcel}.torrent"
		else
			mktorrent -l 19 -v -p -a "" -o "${parcel}.torrent" "${parcel}"
		fi
		touch "${parcel}".skiphash
		rm -f "${parcel}"
		touch "${parcel}"
	fi
done

chown -R cloudera-scm:cloudera-scm ${PARCEL_REPO}

echo "Torrent creation successful" >> /tmp/create_torrent.status
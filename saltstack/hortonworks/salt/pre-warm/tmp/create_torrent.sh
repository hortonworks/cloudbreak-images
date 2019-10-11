#!/bin/bash

set -x

: ${PARCEL_REPO:=/opt/cloudera/parcel-repo}

for parcel in $(ls -1 $PARCEL_REPO | grep .parcel | grep -v sha); do
	mktorrent -l 19 -v -p -a "" -o "${PARCEL_REPO}/${parcel}.torrent" "${PARCEL_REPO}/${parcel}";
done

chown cloudera-scm:cloudera-scm *.torrent
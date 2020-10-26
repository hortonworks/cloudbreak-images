#!/bin/bash

set -ex

check_prerequisites() {
  : ${STACK_TYPE:? required}
  : ${STACK_VERSION:? reqired}
  : ${STACK_BASEURL:? reqired}
  : ${STACK_REPOID:? required}
  : ${STACK_REPOSITORY_VERSION:? required}
  : ${CLUSTERMANAGER_VERSION:? reqired}
  : ${OS:? reqired}
  : ${PARCELS_ROOT:? required}
  : ${PARCELS_NAME:? required}
  : ${PARCEL_REPO:=/opt/cloudera/parcel-repo}
}

verify_parcel_checksum() {
  local SHA_TYPE=$1

  echo "Downloading sha file from $STACK_BASEURL/${PARCELS_NAME}.$SHA_TYPE"
   curl -s -S "${STACK_BASEURL}/${PARCELS_NAME}.${SHA_TYPE}" -o "$PARCEL_REPO/$PARCELS_NAME.$SHA_TYPE"
   cp "$PARCEL_REPO/$PARCELS_NAME.$SHA_TYPE" "$PARCEL_REPO/$PARCELS_NAME.sha"
   sed "s/$/  ${PARCELS_NAME}/" "$PARCEL_REPO/$PARCELS_NAME.$SHA_TYPE" |
     tee "$PARCEL_REPO/$PARCELS_NAME.shacheck" > /dev/null

  echo "Verifying parcel checksum"
  COMMAND="${SHA_TYPE}sum"
  if ! eval "cd $PARCEL_REPO && $COMMAND -c \"$PARCELS_NAME.shacheck\""; then
    echo "Checksum verification failed"
    exit 1
  fi
   rm "$PARCEL_REPO/$PARCELS_NAME.shacheck"
}


download_cdh_parcel() {
  id -u cloudera-scm &>/dev/null ||useradd -r cloudera-scm
  mkdir -p ${PARCELS_ROOT} ${PARCEL_REPO} /opt/cloudera/parcel-cache
  cd ${PARCELS_ROOT}

  echo "Downloading parcel from  ${STACK_BASEURL}/${PARCELS_NAME}"
  curl --progress-bar -C - -s -S --create-dirs ${STACK_BASEURL}/${PARCELS_NAME} -o ${PARCEL_REPO}/${PARCELS_NAME}
  # C5 uses SHA-1 and C6 uses SHA-256
  if  curl -sLf "${STACK_BASEURL}/${PARCELS_NAME}.sha1" -o /dev/null; then
    verify_parcel_checksum "sha1"
  elif  curl -sLf "${STACK_BASEURL}/${PARCELS_NAME}.sha256" -o /dev/null; then
    verify_parcel_checksum "sha256"
  else
    echo "Unable to locate sha file."
    exit 1
  fi
}

extract_cdh_parcel() {
  echo "Preextracting parcels..."
  tar zxf "$PARCEL_REPO/$PARCELS_NAME" -C "${PARCELS_ROOT}"
  # Example: CDH-6.2.0-1.cdh6.2.0.p0.967373
  PARCEL_FOLDER="${PARCELS_NAME%-*}"
  # Example: SPARK2, CDH, etc.
  PARCEL_PRODUCT="${PARCELS_NAME%%-*}"
  # Example: 6.2.0-1.cdh6.2.0.p0.967373
  PARCEL_VERSION="${STACK_REPOSITORY_VERSION#*-}"
  ln -s "$PARCEL_FOLDER" ${PARCELS_ROOT}/${PARCEL_PRODUCT}
  touch ${PARCELS_ROOT}/${PARCEL_PRODUCT}/.dont_delete
  echo "Done extracting"

  parcels=("$PARCEL_REPO"/*.parcel)
  for parcel in "${parcels[@]}"; do
    mktorrent -l 19 -v -p -a "" -o "${parcel}.torrent" "${parcel}"
    touch "${parcel}".skiphash
    rm -f "${parcel}"
    touch "${parcel}"
    ln "${parcel}" "/opt/cloudera/parcel-cache/$(basename "$parcel")"
  done

  head -c -1 <<EOF | sudo tee /var/lib/cloudera-scm-agent/active_parcels.json > /dev/null
{"${PARCEL_PRODUCT}": "${PARCEL_VERSION}"}
EOF

  chown -R cloudera-scm:cloudera-scm /opt/cloudera
  sync
  sleep 5
}

install_cdh() {
  download_cdh_parcel
  extract_cdh_parcel
  echo "Installation successful" >> /tmp/install_cdh.status
}

main() {
  if [[ -n "$STACK_VERSION" ]]; then
    check_prerequisites
    install_cdh
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

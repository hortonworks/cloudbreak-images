#!/bin/bash

set -ex -o pipefail

export LUKS_VOLUME_NAME="cdp-luks"
export MOUNT_POINT="/mnt/$LUKS_VOLUME_NAME"

validate_absolute_path() {
  local location="$1"
  if [[ ! "$location" =~ ^/.* ]]
  then
    echo "Location \"$location\" must be an absolute path!"
    exit 1
  fi
}

validate_location_exists() {
  local location="$1"
  if [ ! -d "$location" ]
  then
    echo "Location \"$location\" must be an existing directory!"
    exit 2
  fi
}

create_location_if_necessary() {
  local location="$1"
  local owner=$2
  local group=$3
  local mode=$4
  if [ ! -d "$location" ]
  then
    echo "Location \"$location\" does not exist; creating it with owner \"$owner\", group \"$group\", mode \"$mode\"."
    install -o $owner -g $group -m $mode -d "$location"
  fi
}

create_location_parent_tree_if_necessary() {
  local source_location_parent
  source_location_parent=$(dirname "$1")
  if [ "$source_location_parent" != "/" ]
  then
    echo "Creating source location parent tree \"$source_location_parent\" if necessary."
    source_location_parent="${source_location_parent#/}"
    local source_location=""
    local luks_location="$MOUNT_POINT"
    local line
    while read -r line
    do
      source_location="$source_location/$line"
      rsync -dAogqk "$source_location" "$luks_location"
      luks_location="$luks_location/$line"
    done < <(echo "$source_location_parent" | awk -F / '{for (i=1; i<=NF; i++) print $i}')
  fi
}

process_location() {
  local source_location="$1"
  echo "Processing source location \"$source_location\"."
  validate_absolute_path "$source_location"
  validate_location_exists "$source_location"
  create_location_parent_tree_if_necessary "$source_location"
  local luks_location="$MOUNT_POINT$source_location"
  echo "Moving source location \"$source_location\" into LUKS location \"$luks_location\"."
  local luks_location_parent
  luks_location_parent=$(dirname "$luks_location")
  mv "$source_location" "$luks_location_parent"
  echo "Creating symlink \"$source_location\" pointing to \"$luks_location\"."
  ln -s "$luks_location" "$source_location"
}

process_location_with_create() {
  local location="$1"
  validate_absolute_path "$location"
  create_location_if_necessary "$@"
  process_location "$location"
}

main() {
  if [[ "$IS_GATEWAY" == "true" ]]
  then
    process_location_with_create "/srv/pillar" root root 644
    if [[ -n "$CB_CERT" ]]
    then
      process_location_with_create "/etc/certs" root root 750
    fi
  fi

  if [[ "$IS_CCM_V2_JUMPGATE_ENABLED" == "true" && "$IS_FREEIPA" == "true" || "$IS_CCM_V2_ENABLED" == "true" && "$IS_CCM_V2_JUMPGATE_ENABLED" != "true" ]]
  then
    # TODO Double-check user:group & mode
    process_location_with_create "/etc/ccmv2" root root 750
    process_location "/etc/jumpgate"
  fi

  if [[ "$IS_PROXY_ENABLED" == "true" ]];
  then
    # TODO Double-check user:group & mode
    process_location_with_create "/etc/cdp" root root 750
  fi
}

main

#!/bin/bash

: ${AZURE_SUBSCRIPTION_ID?= required}
: ${AZURE_SOURCE_STORAGE_ACCOUNT_KEY?= required}
: ${AZURE_SOURCE_BLOB?= required}
: ${AZURE_DESTINATION_STORAGE_ACCOUNT_KEY?= required}
: ${AZURE_DESTINATION_BLOB?= required}

if [[ "$TRACE" ]]; then
    set -x
fi

debug() {
  [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

azure_set_subscription_id() {
    declare subscription_id=${1:?required: subscription id}
    az account set --subscription $subscription_id
}

_delete_azure_storage_account_list() {
    rm "$STORAGE_ACCOUNT_LIST_FILE"
}

azure_storage_account_list() {
    STORAGE_ACCOUNT_LIST_FILE=$(mktemp)
    az storage account list --output json > "$STORAGE_ACCOUNT_LIST_FILE"
    trap _delete_azure_storage_account_list EXIT
}

azure_blob_check() {
    declare dest=${1:? required dest: account/container/blob}
    read dest_account dest_container dest_blob <<< "$(echo $dest | sed 's:/: :'| sed 's:/: :')"
    debug "$dest_account"
    debug "$dest_container"
    debug "$dest_blob"
    local dest_key=$(_azure_get_account_key $dest_account) || exit 1
    debug "$dest_key"
    local result=$(az storage blob exists \
    --container-name $dest_container \
    --name $dest_blob \
    --account-name $dest_account \
    --account-key $dest_key \
    --output json | jq .exists)
    echo "$result"  
}

_azure_get_account_group() {
    declare storage=${1:? storage account}
    local account_group=$(cat "$STORAGE_ACCOUNT_LIST_FILE" | jq '.[]|select(.name|startswith("'${storage}'"))|.resourceGroup' -r | head -1)
    if [[ -z "$account_group" ]]; then
        debug "Failed to get account group for storage account ${storage}"
        exit 1
    fi
    echo $account_group
}

_azure_get_account_key() {
    declare storage=${1:?required: storage account}
    declare group=${2}

    if [[ -z "$group" ]]; then
        group=$(_azure_get_account_group ${storage}) || exit 1
    fi

    local account_key=$(az storage account keys list --resource-group $group --account-name $storage --output json | jq -r '.[0].value')
    if [[ -z "$account_key" ]]; then
        debug "Failed to get account key for storage account ${storage} in group ${group}"
        exit 1
    fi
    echo $account_key
}

azure_blob_copy() {

    declare source=${1:? required source: account/container/blob}
    declare dest=${2:? required dest: account/container/blob}
    declare dest_key=${3:? required dest_key: key}

    read source_account source_container source_blob <<< "$(echo $source | sed 's:/: :'| sed 's:/: :')"
    read dest_account dest_container dest_blob <<< "$(echo $dest | sed 's:/: :'| sed 's:/: :')"
    local source_key=$(_azure_get_account_key $source_account) || exit 1

    az storage blob copy start \
    --source-account-name $source_account \
    --source-account-key $source_key \
    --source-blob $source_blob \
    --source-container $source_container \
    --destination-container $dest_container \
    --destination-blob $dest_blob \
    --account-name $dest_account \
    --account-key $dest_key \
    --destination-if-none-match "*" \
    --timeout "${REQUEST_TIMEOUT:-15}" \
    --output json 1>&2

    local checkCmd="az storage blob show --account-name $dest_account --account-key $dest_key --container-name $dest_container --name $dest_blob --output json | jq -r '.properties.copy | .progress, .status'"
    debug "===> CHECK PROGRESS: $checkCmd"
    echo "$dest_account: $checkCmd" >> checks.yml
}

main() {
  
  azure_set_subscription_id $AZURE_SUBSCRIPTION_ID
  azure_storage_account_list

  sourceBlob=$AZURE_SOURCE_BLOB
  destBlob=$AZURE_DESTINATION_BLOB
  destKey=$AZURE_DESTINATION_STORAGE_ACCOUNT_KEY

  check=$(azure_blob_check $sourceBlob) || exit 1

  if [[ $check == true ]] then
    echo "The source image is found."
  else
    echo "The source image could not be found. Please check the parameters!"
    exit 1
  fi

  azure_blob_copy $sourceBlob $destBlob $destKey
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
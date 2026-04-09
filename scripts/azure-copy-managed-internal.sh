#!/bin/bash

# Accepted format is "Region 1:storageaccount1,Region 2:storageaccount2"
: ${AZURE_STORAGE_ACCOUNTS?= required}
: ${AZURE_IMAGE_NAME?= required}
: ${ARM_STORAGE_ACCOUNT?= required}

set -ex -o pipefail

debug() {
  [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

alias r="source $BASH_SOURCE"

azure_login() {
    if [[ "$ARM_CLIENT_ID" ]] && [[ "$ARM_CLIENT_SECRET" ]]; then
      az login --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --service-principal --tenant $ARM_TENANT_ID
    fi
}

_delete_azure_storage_account_list() {
    rm "$STORAGE_ACCOUNT_LIST_FILE"
}

azure_storage_account_list() {
    STORAGE_ACCOUNT_LIST_FILE=$(mktemp)
    az storage account list --output json > "$STORAGE_ACCOUNT_LIST_FILE"
    trap _delete_azure_storage_account_list EXIT
}

azure_set_vars() {
    DEST_KEY=$(_azure_get_account_key $ARM_STORAGE_ACCOUNT) || exit 1
    RG_LOCATION=$(az group show --name ${ARM_STORAGE_ACCOUNT} --query location -o tsv) || exit 1
    MANAGED_IMAGE_ID=$(az image list -g $ARM_STORAGE_ACCOUNT --query "[?name=='$AZURE_IMAGE_NAME'].id" -o tsv) || exit 1
    GALLERY_IMAGE_VERSION=1.0.0
    GALLERY_NAME=${ARM_STORAGE_ACCOUNT}_gallery
    IMAGE_DEF_NAME=temp_${AZURE_IMAGE_NAME}
    DISK_SNAPSHOT_NAME=${AZURE_IMAGE_NAME}-snapshot
    DISK_ID= # will be set later
}

azure_wait_for_blob_copy_to_finish() {
    local pending_wait_time=20

    while true; do
        # Get the current status
        status=$(az storage blob show \
            --container-name images \
            --name ${AZURE_IMAGE_NAME}.vhd \
            --account-name "${ARM_STORAGE_ACCOUNT}" \
            --account-key "${DEST_KEY}" \
            --query "properties.copy.status" \
            -o tsv)

        if [ "$status" == "success" ]; then
            echo "Copy completed successfully!"
            break
        elif [ "$status" == "pending" ]; then
            echo "Copy pending... checking again in $pending_wait_time seconds."
            sleep $pending_wait_time
        else
            echo "Copy failed."
            exit 2
        fi
    done
}

azure_turn_managed_disk_into_blob() {
    trap azure_cleanup EXIT

    echo Managed image id: $MANAGED_IMAGE_ID

    # Temp image definition with dummy values
    az sig image-definition create --resource-group ${ARM_STORAGE_ACCOUNT} \
    --gallery-name $GALLERY_NAME \
    --gallery-image-definition $IMAGE_DEF_NAME \
    --hyper-v-generation V${AZURE_VM_GEN} \
    --os-type Linux --os-state generalized --publisher Cloudera --offer Cloudbreak --sku ${AZURE_IMAGE_NAME}

    # Create version inside image-definition    
    local version_ref=$(az sig image-version create --resource-group "${ARM_STORAGE_ACCOUNT}" \
        --gallery-name "${GALLERY_NAME}" \
        --gallery-image-definition "${IMAGE_DEF_NAME}" \
        --gallery-image-version "${GALLERY_IMAGE_VERSION}" \
        --target-regions "${RG_LOCATION}" \
        --replica-count 1 \
        --managed-image "${MANAGED_IMAGE_ID}" \
        --query id -o tsv)
    
    echo Gallery image version reference: $version_ref

    DISK_ID=$(az disk create --resource-group ${ARM_STORAGE_ACCOUNT} \
    --location $RG_LOCATION \
    --name ${AZURE_IMAGE_NAME} \
    --gallery-image-reference "${version_ref}" \
    --query id -o tsv)

    echo Created managed disk id: $DISK_ID

    # Create snapshot
    az snapshot create \
        --resource-group "${ARM_STORAGE_ACCOUNT}" \
        --name ${DISK_SNAPSHOT_NAME} \
        --source ${AZURE_IMAGE_NAME}
    
    # Disk access
    local access_duration_seconds=$((3600*4))
    local disk_reference_url=$(az disk grant-access \
        --resource-group "${ARM_STORAGE_ACCOUNT}" --name ${AZURE_IMAGE_NAME} --access-level Read \
        --duration-in-seconds ${access_duration_seconds} \
        -o tsv | awk '{print $1}')

    echo Disk reference url: $disk_reference_url

    # Do the copy
    az storage blob copy start \
        --account-name "${ARM_STORAGE_ACCOUNT}" \
        --account-key "${DEST_KEY}" \
        --destination-container images  \
        --destination-blob ${AZURE_IMAGE_NAME}.vhd \
        --source-uri $disk_reference_url
    
    if [ $? -ne 0 ]; then
        echo "Faild to copy blob."
        exit 1
    fi

    azure_wait_for_blob_copy_to_finish    
}

_azure_cleanup() {
    local exit_code=$?
    set +e

    if [ $exit_code -ne 0 ]; then
        echo "Cleaning up after a failure."
    fi

    az disk revoke-access --resource-group ${ARM_STORAGE_ACCOUNT} \
        --name ${AZURE_IMAGE_NAME} || exit_code=1
    
    if [[ -n "$DISK_SNAPSHOT_NAME" ]]; then
        az snapshot delete \
            --resource-group "${ARM_STORAGE_ACCOUNT}" \
            --name ${DISK_SNAPSHOT_NAME} || exit_code=1
    fi

    az disk delete --resource-group ${ARM_STORAGE_ACCOUNT} \
        --name ${AZURE_IMAGE_NAME} -y || exit_code=1

    if [[ -n "$GALLERY_IMAGE_VERSION" ]]; then
        az sig image-version delete --resource-group ${ARM_STORAGE_ACCOUNT} \
            --gallery-name $GALLERY_NAME \
            --gallery-image-definition $IMAGE_DEF_NAME \
            --gallery-image-version $GALLERY_IMAGE_VERSION || exit_code=1
    fi

    if [[ -n "$IMAGE_DEF_NAME" ]]; then
        az sig image-definition delete --resource-group ${ARM_STORAGE_ACCOUNT} \
            --gallery-name $GALLERY_NAME \
            --gallery-image-definition $IMAGE_DEF_NAME || exit_code=1
    fi

    set -e
    exit $exit_code
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

main() {
  : ${DEBUG:=1}
  azure_login
  azure_storage_account_list
  azure_set_vars
  azure_turn_managed_disk_into_blob
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

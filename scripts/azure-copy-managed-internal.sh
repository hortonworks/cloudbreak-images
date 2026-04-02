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

azure_storage_account_list() {
    STORAGE_ACCOUNT_LIST_FILE=$(mktemp)
    az storage account list --output json > "$STORAGE_ACCOUNT_LIST_FILE"
    trap _delete_azure_storage_account_list EXIT
}

azure_wait_for_blob_copy_to_finish() {
    local dest_key=$(_azure_get_account_key $ARM_STORAGE_ACCOUNT) || exit 1
    local pending_wait_time=20

    while true; do
        # Get the current status
        status=$(az storage blob show \
            --container-name images \
            --name ${AZURE_IMAGE_NAME}.vhd \
            --account-name "${ARM_STORAGE_ACCOUNT}" \
            --account-key "${dest_key}" \
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
    local managed_image_id=$(az image list -g $ARM_STORAGE_ACCOUNT --query "[?name=='$AZURE_IMAGE_NAME'].id" -o tsv)
    local gallery_image_version=1.0.0
    local gallery_name=${ARM_STORAGE_ACCOUNT}_gallery
    local img_def_name=temp_${AZURE_IMAGE_NAME}
    local rg_loc=$(az group show --name ${ARM_STORAGE_ACCOUNT} --query location -o tsv)
    local dest_key=$(_azure_get_account_key $ARM_STORAGE_ACCOUNT) || exit 1

    echo Managed image id: $managed_image_id

    # Temp image definition with dummy values
    az sig image-definition create --resource-group ${ARM_STORAGE_ACCOUNT} \
    --gallery-name $gallery_name \
    --gallery-image-definition $img_def_name \
    --hyper-v-generation V1 \
    --os-type Linux --os-state generalized --publisher Cloudera --offer Cloudbreak --sku ${AZURE_IMAGE_NAME}

    # Create version inside image-definition    
    local version_ref=$(az sig image-version create --resource-group "${ARM_STORAGE_ACCOUNT}" \
        --gallery-name "${gallery_name}" \
        --gallery-image-definition "${img_def_name}" \
        --gallery-image-version "${gallery_image_version}" \
        --target-regions "${rg_loc}" \
        --replica-count 1 \
        --managed-image "${managed_image_id}" \
        --query id -o tsv)
    
    echo Gallery image reference: $version_ref

    local disk_id=$(az disk create --resource-group ${ARM_STORAGE_ACCOUNT} \
    --location $rg_loc \
    --name ${AZURE_IMAGE_NAME} \
    --gallery-image-reference "${version_ref}" \
    --query id -o tsv)

    echo Created managed disk id: $disk_id

    # Create snapshot
    local snapshot_name=${AZURE_IMAGE_NAME}-snapshot
    az snapshot create \
        --resource-group "${ARM_STORAGE_ACCOUNT}" \
        --name ${snapshot_name} \
        --source ${AZURE_IMAGE_NAME}
    
    # Disk access
    local access_duration_hours=$((3600*4))
    local disk_reference_url=$(az disk grant-access \
        --resource-group "${ARM_STORAGE_ACCOUNT}" --name ${AZURE_IMAGE_NAME} --access-level Read \
        --duration-in-seconds ${access_duration_hours} \
        -o tsv | awk '{print $1}')

    echo Disk reference url: $disk_reference_url

    # Do the copy
    az storage blob copy start \
        --account-name "${ARM_STORAGE_ACCOUNT}" \
        --account-key "${dest_key}" \
        --destination-container images  \
        --destination-blob ${AZURE_IMAGE_NAME}.vhd \
        --source-uri $disk_reference_url
    
    if [ $? -ne 0 ]; then
        echo "Faild to copy blob."
        exit 1
    fi

    azure_wait_for_blob_copy_to_finish

    # Cleanup
    az disk revoke-access --resource-group ${ARM_STORAGE_ACCOUNT} \
        --name ${AZURE_IMAGE_NAME}

    az snapshot delete \
        --resource-group "${ARM_STORAGE_ACCOUNT}" \
        --name ${snapshot_name}

    az disk delete --resource-group ${ARM_STORAGE_ACCOUNT} \
        --name ${AZURE_IMAGE_NAME} -y

    az sig image-version delete --resource-group ${ARM_STORAGE_ACCOUNT} \
        --gallery-name $gallery_name \
        --gallery-image-definition $img_def_name \
        --gallery-image-version $gallery_image_version

    az sig image-definition delete --resource-group ${ARM_STORAGE_ACCOUNT} \
        --gallery-name $gallery_name \
        --gallery-image-definition $img_def_name
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
  azure_turn_managed_disk_into_blob
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

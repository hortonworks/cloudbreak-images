docker run -it --rm \
    -v ~/.azure:/root/.azure \
    -v $PWD:/work \
    -w /work \
    -e ARM_CLIENT_ID=$ARM_CLIENT_ID \
    -e ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET \
    -e ARM_GROUP_NAME=$ARM_GROUP_NAME \
    -e ARM_STORAGE_ACCOUNT=$ARM_STORAGE_ACCOUNT \
    -e ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID \
    -e ARM_TENANT_ID=$ARM_TENANT_ID \
    -e AZURE_DESTINATION_IMAGE_PREFIX=$AZURE_DESTINATION_IMAGE_PREFIX \
    -e AZURE_USERNAME=$AZURE_USERNAME \
    -e AZURE_PASSWORD=$AZURE_PASSWORD \
    --entrypoint azure-copy \
    sequenceiq/azure-cli-tools:0.9.8-v3
  
docker run -it --rm \
    -v ~/.azure:/root/.azure \
    -v $PWD:/work \
    -w /work \
    --entrypoint pollprogress \
    sequenceiq/azure-cli-tools:0.9.8-v3 \
    checks.yml

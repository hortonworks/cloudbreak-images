
We use this image also for automating the process of azure-rm image copy.

- Azure rm image is built in northeurope region only
- An extra step needed to copy the vhd to all other storage accounts.

## Usage

The script is built into a docker image:

```
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
  --entrypoint azure-copy \
  sequenceiq/azure-cli-tools:0.9.8-v3
```

## Check progress

The `azure-copy` starts the region copies in asynchron. For each region there is
an azure cli script generate which can check the copy progress. The commands are collected into: `checks.yml`


If you want to visually check the progress, and/or block until all copies finished, you can use the 
[pollprogress](https://github.com/lalyos/pollprogress) tools. For easy usage, we also included it into the 
docker image.

To check the progress:

```
docker run -it --rm \
  -v ~/.azure:/root/.azure \
  -v $PWD:/work \
  -w /work \
  --entrypoint pollprogress \
  sequenceiq/azure-cli-tools:0.9.8-v3 \
  checks.yml
```

## Configuration

By default the source image name is queried from atlas, and will be used as the destination image name.

Source images are built by packer into `sequenceiqnortheurope2` storage account in the `system` container.
Destination image will be copied to the `images` container with the name queried from atlas (image_name meta-data)

If you want to customize the destination image name, for example for testimg the process, use the 
`ARM_DESTINATION_IMAGE_PREFIX` env variable.

If you want to use different user than your user on the host, you can pass login information via `ARM_USERNAME` and `ARM_PASSWORD` variables.

For the above docker command you can ad a new `-e` options:

```
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
  -e ARM_DESTINATION_IMAGE_PREFIX=test- \
  -e ARM_USERNAME=$ARM_USERNAME \
  -e ARM_PASSWORD=$ARM_PASSWORD \
  --entrypoint azure-copy \
  sequenceiq/azure-cli-tools:0.9.8-v3
```


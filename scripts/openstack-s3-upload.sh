#!/bin/bash
set -xe

: ${S3_TARGET:=s3://public-repo-1.hortonworks.com/HDP/cloudbreak}
: ${OS_IMAGE_ATLAS_VERSION:=latest}
: ${ATLAS_PROJECT:=cloudbreak}
OS_IMAGE_NAME=$(curl -sL https://atlas.hashicorp.com/api/v1/artifacts/sequenceiq/$ATLAS_PROJECT/openstack.image/search?version=$OS_IMAGE_ATLAS_VERSION | jq '.versions[0].metadata.image_name' -r)
OS_IMAGE_ID=$(glance image-list | sed -n "/$OS_IMAGE_NAME / s/| \([^ ]*\).*/\1/p")
glance image-download --file $OS_IMAGE_NAME.img --progress $OS_IMAGE_ID
aws s3 cp $OS_IMAGE_NAME.img $S3_TARGET --acl public-read
rm -f $OS_IMAGE_NAME.img

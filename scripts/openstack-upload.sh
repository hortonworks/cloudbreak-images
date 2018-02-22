#!/bin/bash
set -xe

: ${S3_TARGET?= required}
: ${OS_IMAGE_NAME?= required}

OS_IMAGE_ID=$(glance image-list | sed -n "/$OS_IMAGE_NAME / s/| \([^ ]*\).*/\1/p")
glance image-download --file $OS_IMAGE_NAME.img --progress $OS_IMAGE_ID
aws s3 cp $OS_IMAGE_NAME.img $S3_TARGET --acl public-read
if [[ $OS_KILO_AUTH_URL ]] && [[ $OS_KILO_PASSWORD ]] && [[ $OS_KILO_TENANT_NAME ]] && [[ $OS_KILO_USERNAME ]]; then
    glance image-create --name "$OS_IMAGE_NAME" --file "$OS_IMAGE_NAME.img"  --disk-format qcow2 --container-format bare \
        --os-username "$OS_KILO_USERNAME" --os-tenant-name "$OS_KILO_TENANT_NAME" --os-auth-url "$OS_KILO_AUTH_URL" --os-password "$OS_KILO_PASSWORD"
fi
rm -f $OS_IMAGE_NAME.img

#!/bin/bash

set -x

: ${OS_USERNAME:? required}
: ${OS_TENANT_NAME:? required}
: ${OS_PASSWORD:? required}
: ${OS_AUTH_URL:? required}
: ${OS_IMAGE_NAME:? required}
: ${AWS_ACCESS_KEY_ID:? required}
: ${AWS_SECRET_ACCESS_KEY:? required}

IMAGE_ID=$(nova --os-username $OS_USERNAME --os-tenant-name $OS_TENANT_NAME --os-password $OS_PASSWORD --os-auth-url $OS_AUTH_URL image-list | sed -n "/$OS_IMAGE_NAME / s/| \([^ ]*\).*/\1/p")
glance --os-username $OS_USERNAME --os-tenant-name $OS_TENANT_NAME --os-password $OS_PASSWORD --os-auth-url $OS_AUTH_URL image-download --file $OS_IMAGE_NAME.img $IMAGE_ID

aws s3 cp $OS_IMAGE_NAME.img s3://cb-openstack-images
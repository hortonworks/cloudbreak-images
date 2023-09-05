#!/bin/bash
set -xe

if [[ "${OS}" == "redhat8" && "$CLOUD_PROVIDER" != "AWS_GOV" ]] ; then
    if [[ "${IMAGE_BURNING_TYPE}" == "base" ]] ; then
        RHEL_VERSION=$(cat /etc/redhat-release | grep -oP "[0-9\.]*")
        RHEL_VERSION=${RHEL_VERSION/.0/}
        REPO_FILE=rhel${RHEL_VERSION}_cldr_mirrors.repo
        find /etc/yum.repos.d -type f ! -name 'pgdg-redhat-all.repo' ! -name $REPO_FILE -delete
    else
        find /etc/yum.repos.d -type f ! -name 'pgdg-redhat-all.repo' -delete
    fi
fi
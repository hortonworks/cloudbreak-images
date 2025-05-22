#!/bin/bash
set -xe

if [[ "$CLOUD_PROVIDER" != "AWS_GOV" ]] ; then
    if [[ "${OS}" == "redhat8" || "${OS}" == "redhat9" ]] ; then
        if [[ "${IMAGE_BURNING_TYPE}" == "base" ]] ; then
            RHEL_VERSION=$(cat /etc/redhat-release | grep -oP "[0-9\.]*")
            RHEL_VERSION=${RHEL_VERSION/.0/}
            REPO_FILE=rhel${RHEL_VERSION}_cldr_mirrors.repo
            find /etc/yum.repos.d -type f ! -name $REPO_FILE -delete
        else
            find /etc/yum.repos.d -type f -delete
        fi
    fi
fi
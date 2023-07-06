#!/bin/bash
set -xe

if [[ "${OS}" == "redhat8" && "$CLOUD_PROVIDER" != "Azure"  && "$CLOUD_PROVIDER" != "AWS_GOV" ]] ; then
    find /etc/yum.repos.d -type f ! -name 'pgdg-redhat-all.repo' ! -name 'rhel8.8_cldr_mirrors.repo' -delete
fi
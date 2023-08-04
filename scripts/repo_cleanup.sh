#!/bin/bash
set -xe

if [[ "${OS}" == "redhat8" && "$CLOUD_PROVIDER" != "AWS_GOV" ]] ; then
    find /etc/yum.repos.d -type f ! -name 'pgdg-redhat-all.repo' -delete
fi
#!/bin/bash
set -xe

if [[ "${OS}" == "centos7" ]] ; then
    rm -f /etc/yum.repos.d/postgres10-el7.repo
elif [[ "${OS}" == "redhat8" && "$CLOUD_PROVIDER" != "AWS_GOV" ]] ; then
    find /etc/yum.repos.d -type f ! -name 'pgdg-redhat-all.repo' -delete
fi
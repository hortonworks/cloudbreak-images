#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}

set -ex -o pipefail -o errexit

function update_yum_repos() {

  if [[ "${OS}" == "redhat8" || "${OS}" == "redhat9" ]] ; then
    # Remove RHEL official repos and use the internal mirror in case of RHEL 8/9
    RHEL_VERSION=$(cat /etc/redhat-release | grep -oP "[0-9\.]*")
    RHEL_VERSION=${RHEL_VERSION/.0/}

    # CB-30236: We need this override, because we only have a 9.5 base image for Azure
    if [[ "${CLOUD_PROVIDER}" == "Azure" && "${RHEL_VERSION}" == "9.5" ]]; then
      RHEL_VERSION="9.6"
    fi

    # For AWS Gov sadly we have an ancient RHEL 8.4 base image, so this needs an override
    if [[ "${CLOUD_PROVIDER}" == "AWS_GOV" && "${RHEL_VERSION}" == "8.4" ]]; then
      RHEL_VERSION="8.10"
    fi


    RHEL_VERSION_MAJOR=${RHEL_VERSION:0:1}
    REPO_FILE=rhel${RHEL_VERSION}_cldr_mirrors.repo
    if [ "${CLOUD_PROVIDER}" != "YARN" ]; then
      rm /etc/yum.repos.d/*.repo -f
    fi
    curl https://mirror.eng.cloudera.com/repos/rhel/server/${RHEL_VERSION_MAJOR}/${RHEL_VERSION}/${REPO_FILE} --fail > /etc/yum.repos.d/${REPO_FILE}
  else
    # Workaround based on the official documentation: https://cloud.google.com/compute/docs/troubleshooting/known-issues#known_issues_for_linux_vm_instances
    if [ "${CLOUD_PROVIDER}" == "GCP" ]; then
      sudo sed -i 's/repo_gpgcheck=1/repo_gpgcheck=0/g' /etc/yum.repos.d/google-cloud.repo
    fi

    # Replace repos on the image that are no longer working
    sudo rm -rf /etc/yum.repos.d/CentOS*.repo
    cp /tmp/repos/RPM-GPG-KEY-CentOS-SIG-SCLo /etc/pki/rpm-gpg/
    cp /tmp/repos/centos-vault.repo /etc/yum.repos.d/
  fi
}

function enable_epel_repository() {

  if [ "${OS}" == "redhat9" ] ; then
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  elif [ "${OS}" == "redhat8" ] ; then
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  elif [ "${OS}" == "centos7" ] ; then
    cp /tmp/repos/RPM-GPG-KEY-CentOS-EPEL /etc/pki/rpm-gpg/
    cp /tmp/repos/centos-epel.repo /etc/yum.repos.d/
  fi
}

update_yum_repos

yum install -y yum-utils yum-plugin-versionlock
yum clean metadata

enable_epel_repository

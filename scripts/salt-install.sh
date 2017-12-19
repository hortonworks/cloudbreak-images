#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}

set -e -o pipefail -o errexit

function install_with_apt() {
  apt-get install -y apt-transport-https

  apt-key add /tmp/repos/saltstack-gpg-key.pub
  cp /tmp/repos/$1 /etc/apt/sources.list.d/$1

  apt-get update
  apt-get -y install salt-minion
  create_temp_minion_config
}

function install_with_yum() {
  yum update -y python
  yum install -y yum-utils

  cp /tmp/repos/$1 /etc/yum.repos.d/$1
  cp /tmp/repos/saltstack-gpg-key.pub /etc/pki/rpm-gpg/saltstack-gpg-key.pub
  yum clean metadata

  # TODO: install python27-pip package only for Centos6
  # yum install -y python27-pip salt-minion
  # Workaround with salt-2017.7.1
  # if [ -f /usr/bin/pip2.7 ]; then
  #  /usr/bin/pip2.7 install --upgrade urllib3 requests[security]
  # fi
  yum install -y salt-minion

  create_temp_minion_config
}

function create_temp_minion_config() {
  echo "requests_lib: True" > /tmp/minion
  echo "backend_requests: True" >> /tmp/minion
}

: ${SALT_INSTALL_OS:=$1}
: ${SALT_REPO_FILE:=$2}

case ${SALT_INSTALL_OS} in
  amazon|centos|redhat)
    echo "Install with yum"
    echo ${SALT_REPO_FILE}
    install_with_yum ${SALT_REPO_FILE}
    ;;
 debian|ubuntu)
   echo "Install with apt"
   echo ${SALT_REPO_FILE}
   install_with_apt ${SALT_REPO_FILE}
   ;;
 *)
  echo "Unsupported platform:" $1
  exit 1
  ;;
esac

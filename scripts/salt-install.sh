#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}

set -e -o pipefail -o errexit

function setting_up_epel() {
  if grep -q -i "Red Hat Enterprise Linux Server release 6." /etc/redhat-release; then
    wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
    yum install -y epel-release-latest-6.noarch.rpm
  elif grep -q -i "Red Hat Enterprise Linux Server release 7." /etc/redhat-release; then
    yum install -y wget
    wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum install -y epel-release-latest-7.noarch.rpm
  else
    yum install -y epel-release
  fi
  yum-config-manager --disable epel
  yum-config-manager epel --setopt "epel.exclude=zeromq* salt* python-zmq*" --save
}

function install_with_apt() {
  apt-key add /tmp/repos/saltstack-gpg-key.pub
  apt-get update
  apt-get install -y apt-transport-https
  cp /tmp/repos/$1 /etc/apt/sources.list.d/$1
  apt-get update
  apt-get -y install salt-minion
  create_temp_minion_config
}

function install_with_yum() {
  yum update -y python
  yum install -y yum-utils
  setting_up_epel
  yum remove -y salt-repo
  cp /tmp/repos/$1 /etc/yum.repos.d/$1
  cp /tmp/repos/saltstack-gpg-key.pub /etc/pki/rpm-gpg/saltstack-gpg-key.pub
  yum clean metadata
  # TODO: install python27-pip package only for Centos6
  yum install -y --disablerepo epel python27-pip salt-minion
  create_temp_minion_config
}

function create_temp_minion_config() {
  echo "requests_lib: True" > /tmp/minion
  echo "backend_requests: True" >> /tmp/minion
}

: ${SALT_INSTALL_OS:=$1}
: ${SALT_REPO_FILE:="$2 $3"}

case ${SALT_INSTALL_OS} in
  amazon|centos|redhat)
    echo "Install with yum"
    echo ${SALT_REPO_FILE}
    echo ${SALT_VERSION}
    install_with_yum ${SALT_REPO_FILE} ${SALT_VERSION}
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

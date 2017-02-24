#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}

set -e -o pipefail -o errexit

#run function
function run {
  debug "$@";
  if [ "${DRY_RUN}" != "--dry-run" ]; then "$@"; fi;
}

#debug function
function debug {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@";
}

function setting_up_epel() {
  yum install -y epel-release
  yum-config-manager --disable epel
  yum-config-manager epel --setopt "epel.exclude=zeromq* salt* python-zmq*" --save
}

function install_with_apt() {
  apt-get install -y
  wget -O - $1/SALTSTACK-GPG-KEY.pub | apt-key add -
  echo deb $1 $2 main >/etc/apt/sources.list.d/salt.list
  apt-get update
  apt-get -y install salt-minion
  create_temp_monion_config
}

function install_with_yum() {
  yum update -y python
  yum install -y yum-utils
  setting_up_epel
  yum remove -y salt-repo
  yum install -y $1
  yum clean metadata
  yum install -y --disablerepo epel salt-minion
  create_temp_monion_config
}

function create_temp_monion_config() {
  echo "requests_lib: True" > /tmp/minion
  echo "backend_requests: True" >> /tmp/minion
}

: ${SALT_INSTALL_OS:=$1}
: ${SALT_INSTALL_REPO:="$2 $3"}

case ${SALT_INSTALL_OS} in
  amazon|centos|redhat)
    echo "Install with yum"
    echo ${SALT_INSTALL_REPO}
    install_with_yum ${SALT_INSTALL_REPO}
    ;;
 debian|ubuntu)
   echo "Install with apt"
   echo ${SALT_INSTALL_REPO}
   install_with_apt ${SALT_INSTALL_REPO}
   ;;
 *)
  echo "Unsupported platform:" $1
  exit 1
  ;;
esac

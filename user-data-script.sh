#!/bin/bash

# let the script fail to cause the image build unsuccessfull
# set -eo pipefail

[[ "$TRACE" ]] && set -x

: ${IMAGES:=sequenceiq/ambari:1.7.0-consul sequenceiq/consul:v0.4.1.ptr}
: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

install_utils() {
  apt-get update && apt-get install -y curl
  curl -o /usr/local/bin/jq http://stedolan.github.io/jq/download/linux64/jq && chmod +x /usr/local/bin/jq
}

install_docker() {
  curl -sSL https://get.docker.com/ | sh
  sudo usermod -aG docker ubuntu
}

pull_images() {
  set -e
  for i in ${IMAGES}; do
    docker pull ${i}
  done
}

install_scripts() {
  local target=${1:-/usr/local}
  local provider=$(get_provider_from_packer)

  debug target=$target
  debug provider=$provider

  # script are copied by packer's file provisioner section
  cp /tmp/register-ambari.sh ${target}
  cp /tmp/disk_mount_$provider.sh ${target}/disk_mount.sh
  cp /tmp/public_host_script_$provider.sh ${target}/public_host_script.sh

  chmod +x ${target}/*.sh
  ls -l $target/*.sh

  cp ${target}/register-ambari.sh /etc/init.d/register-ambari
  chown root:root /etc/init.d/register-ambari
  update-rc.d -f register-ambari defaults
  update-rc.d -f register-ambari enable
}

fix_fstab() {
	sed -i "/dev\/xvdb/ d" /etc/fstab
}

get_provider_from_packer() {
    : ${PACKER_BUILDER_TYPE:? required amazon-ebs/googlecompute/openstack}

    if [[ $PACKER_BUILDER_TYPE =~ amazon ]] ; then
        echo ec2
        return
    fi

    if [[ $PACKER_BUILDER_TYPE == "googlecompute" ]]; then
        echo gce
        return
    fi

    if [[ $PACKER_BUILDER_TYPE == "openstack" ]]; then
        echo openstack
        return
    fi

    if [[ $PACKER_BUILDER_TYPE == "azure" ]]; then
        echo azure
        return
    fi

    echo UNKNOWN_PROVIDER
}

check_params() {
    : ${PACKER_BUILDER_TYPE:? required amazon-ebs/googlecompute/openstack }
}

main() {
    check_params
    install_scripts
    install_utils
    install_docker
    pull_images
    fix_fstab
    touch /tmp/ready
    sync
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

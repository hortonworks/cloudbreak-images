#!/bin/bash

# let the script fail to cause the image build unsuccessfull
# set -e

[[ "$TRACE" ]] && set -x

: ${IMAGES:=sequenceiq/ambari:1.7.0-consul sequenceiq/consul:v0.4.1.ptr}
: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

install_utils() {
  apt-get update && apt-get install -y unzip curl git python-pip dnsutils nmap
  curl -o /usr/local/bin/jq http://stedolan.github.io/jq/download/linux64/jq && chmod +x /usr/local/bin/jq
  pip install awscli
  curl -Lsk https://github.com/progrium/plugn/releases/download/v0.1.0/plugn_0.1.0_linux_x86_64.tgz|tar -xzC /usr/local/bin/
}

install_docker() {
  curl -sSL https://get.docker.com/ | sh
  sudo usermod -aG docker ubuntu
}

install_consul() {
  curl -LO https://dl.bintray.com/mitchellh/consul/0.4.1_linux_amd64.zip \
    && unzip 0.4.1_linux_amd64.zip \
    && mv consul /usr/local/bin
}

pull_images() {
  for i in ${IMAGES}; do
    docker pull ${i}
  done
}

github_raw_content() {

    local output=${1:? required as 1. parameter}
    local path=${2:? reuired as 2. parmeter}

    local repo=sequenceiq/cloudbreak-images

    debug "download raw $repo/$path => $output"
    curl \
        -o ${output} \
        -H "Accept: application/vnd.github.VERSION.raw" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        https://api.github.com/repos/${repo}/contents/${path}
}

install_scripts() {
  local target=${1:-/usr/local}
  local provider=$(get_provider_from_packer)

  debug target=$target
  debug provider=$provider
  
  github_raw_content ${target}/register-ambari.sh scripts/register-ambari.sh
  github_raw_content ${target}/public_host_script.sh scripts/public_host_script_${provider}.sh
  github_raw_content ${target}/disk_mount.sh scripts/disk_mount_${provider}.sh?
  
  chmod +x ${target}/*.sh
  ls -l $target
  
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

    echo UNKNOWN_PROVIDER
}

check_params() {
    : ${GITHUB_TOKEN:? required}
    : ${PACKER_BUILDER_TYPE:? required amazon-ebs/googlecompute/openstack }
}

main() {
    check_params
    install_utils
    install_docker
    pull_images
    install_consul
    install_scripts
    fix_fstab
    touch /tmp/ready
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

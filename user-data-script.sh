#!/bin/bash

[[ "$TRACE" ]] && set -x

: ${IMAGES:=sequenceiq/ambari:1.6.0-consul sequenceiq/consul:v0.4.1.ptr}

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


main() {
    install_utils
    install_docker
    pull_images
    install_consul
    touch /tmp/ready
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

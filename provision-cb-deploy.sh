#!/bin/bash

[[ "$TRACE" ]] && set -x

install_utils() {
  apt-get update && apt-get install -y unzip curl git dnsutils nmap
  curl -o /usr/local/bin/jq http://stedolan.github.io/jq/download/linux64/jq && chmod +x /usr/local/bin/jq
}

install_docker() {
  curl -sSL https://get.docker.com/ | sh
  sudo usermod -aG docker ubuntu
}

create_dirs() {
    for dir in /var/lib /etc /usr/local; do
        mkdir -p ${dir}/cloudbreak
        chmod -R 777 ${dir}/cloudbreak
    done
}

pull_images() {
  docker pull sequenceiq/consul:v0.5.0
  docker pull gliderlabs/registrator:v5
  docker pull gliderlabs/alpine:3.1
  docker pull postgres:9.4.0
  docker pull sequenceiq/uaa:1.8.1-v1
  docker pull sequenceiq/sultans:latest
  docker pull sequenceiq/cloudbreak:0.3.65
  docker pull sequenceiq/cb-shell:0.2.38
}

main() {
    create_dirs
    install_utils
    install_docker
    pull_images
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

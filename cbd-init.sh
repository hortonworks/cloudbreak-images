set -eo pipefail
[[ "$TRACE" ]] && set -x

: ${DEBUG:=1}
: ${OS_USER:=cloudbreak}
: ${CBD_DIR:="/var/lib/cloudbreak-deployment"}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

reset_docker() {
    debug "STOP docker and clean id"
    sudo service docker stop
    debug "Deleting key.json in order to avoid swarm conflicts"
    sudo rm -vf /etc/docker/key.json
}

reset_hostname() {
  debug "Avoid pre-assigned hostname"
  sudo rm -vf /etc/hostname
}

reset_authorized_keys() {
  debug "Deleting authorized_keys files to remove temporary packer entries"
  sudo rm "/root/.ssh/authorized_keys"
  sudo rm "/home/$OS_USER/.ssh/authorized_keys"
}

cbd_init() {
    sudo mkdir -p $CBD_DIR
    sudo chown -R $OS_USER:$OS_USER $CBD_DIR
    cd $CBD_DIR
    
    cbd init
    cbd generate
    cbd pull-parallel

    docker pull hortonworks/cloud-web:${CBD_VERSION}
    docker pull hortonworks/cloud-auth:${CBD_VERSION}
    docker pull hortonworks/cloudbreak-shell:${CBD_VERSION}

    cat >> ~/.bashrc <<"EOF"
eval "$(bash -c 'cd /var/lib/cloudbreak-deployment; cbd bash-complete')"
EOF
    rm -rf certs *.yml *.log
}

cbd_install() {
    : ${CBD_INSTALL_DIR:=/bin}
    : ${CBD_VERSION:?required}
    debug "Install cbd: ${CBD_VERSION} to ${CBD_INSTALL_DIR}"
    curl -Ls s3.amazonaws.com/public-repo-1.hortonworks.com/HDP/cloudbreak/cloudbreak-deployer_${CBD_VERSION:?required}_$(uname)_x86_64.tgz \
        | sudo tar -xz -C ${CBD_INSTALL_DIR}
}

install_utils() {
    sudo yum install -y \
        jq \
        tmux \
        mosh
}

install_hdc_cli() {
  : ${HDC_CLI_VERSION:? required}
  : ${GH_TOKEN:? required}
  : ${GITHUB_REPO:=hortonworks/hdc-cli}
  : ${HDC_CLI_INSTALL_DIR:=/var/lib/cloudbreak/hdc-cli}

  local baseUrl=https://api.github.com/repos/$GITHUB_REPO/releases
  local releaseUrl=$baseUrl/tags/v${HDC_CLI_VERSION}
  if ! curl --fail -sG -o /dev/null -d access_token=$GITHUB_TOKEN $releaseUrl; then
    debug "WARNING: couldnt find hdc cli release: ${HDC_CLI_VERSION}, using latest github release instead"
    releaseUrl=$baseUrl/latest
  fi

  mkdir -p $HDC_CLI_INSTALL_DIR
  cd $HDC_CLI_INSTALL_DIR
  curl -s -G \
   -d access_token=$GITHUB_TOKEN \
   $releaseUrl \
    | jq ".assets[]|[.name,.url][]" -r \
    | xargs -t -n 2 -P 3 curl -sG -d access_token=$GH_TOKEN -H "Accept: application/octet-stream" -Lo
   cd -
}

main() {
    debug "Update to docker 1.10.3"
    sudo service docker stop; sudo curl -Lo /usr/bin/docker https://get.docker.com/builds/Linux/x86_64/docker-1.10.3
    debug "Use overlay storage driver"
    sudo sed -i 's/^DOCKER_STORAGE_OPTIONS=/DOCKER_STORAGE_OPTIONS="-s overlay"/' /etc/sysconfig/docker-storage
    
    debug "START docker ..."
    sudo service docker start

    install_utils
    install_hdc_cli
    cbd_install
    cbd_init
    reset_docker
    reset_hostname
    reset_authorized_keys
    debug "[DONE] $BASH_SOURCE"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

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

cbd_init() {
    sudo mkdir -p $CBD_DIR
    sudo chown -R $OS_USER:$OS_USER $CBD_DIR
    cd $CBD_DIR
    
    cbd init
    cbd generate
    cbd pull-parallel

    docker pull hortonworks/cloud-web:${CBD_VERSION}
    docker pull hortonworks/cloud-auth:${CBD_VERSION}
    docker pull sequenceiq/cb-shell:${CBD_VERSION}

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

install_init_script() {
    curl -Lo ${CBD_DIR}/user-data-${CBD_VERSION}.sh https://s3.amazonaws.com/cbd-quickstart/start-cbd-${CBD_VERSION}.sh
    chmod +x ${CBD_DIR}/user-data-${CBD_VERSION}.sh
}

main() {
    debug "Update to docker 1.10.3"
    sudo service docker stop; sudo curl -Lo /usr/bin/docker https://get.docker.com/builds/Linux/x86_64/docker-1.10.3; sudo service docker start
    
    debug "START docker ..."
    sudo service docker start

    install_utils
    cbd_install
    cbd_init
    install_init_script
    reset_docker
    reset_hostname
    debug "[DONE] $BASH_SOURCE"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

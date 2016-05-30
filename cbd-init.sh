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

    rm -rf certs *.yml *.log
}

cbd_install() {
    : ${CBD_INSTALL_DIR:=/bin}
    : ${CBD_VERSION:?required}
    debug "Install cbd: ${CBD_VERSION} to ${CBD_INSTALL_DIR}"
    curl -Ls s3.amazonaws.com/public-repo-1.hortonworks.com/HDP/cloudbreak/cloudbreak-deployer_${CBD_VERSION:?required}_$(uname)_x86_64.tgz \
        | sudo tar -xz -C ${CBD_INSTALL_DIR}
}

main() {
    debug "START docker ..."
    sudo service docker start

    cbd_install
    cbd_init
    reset_docker
    reset_hostname
    debug "[DONE] $BASH_SOURCE"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

[[ "$TRACE" ]] && set -x

: ${DEBUG:=1}
: ${OS_USER:=cloudbreak}
: ${CBD_DIR:="/var/lib/cloudbreak-deployment"}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

reset_docker() {
    debug "STOP docker and clean id"
    service docker stop
    echo "Deleting key.json in order to avoid swarm conflicts"
    rm -vf /etc/docker/key.json
}

cbd_init() {
    mkdir $CBD_DIR
    cd $_

    echo export PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com) > Profile
    echo "export UAA_DEFAULT_USER_EMAIL=admin@example.com" >> Profile
    echo "export UAA_DEFAULT_USER_PW=cloudbreak" >> Profile
    echo "export UAA_DEFAULT_SECRET=cbsecret2015" >> Profile
    echo "export CB_INSTANCE_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')" >> Profile
    cbd generate
    cbd pull-parallel

    rm -rf Profile certs *.yml *.log
    chown -R $OS_USER:$OS_USER $CBD_DIR
    chown -R $OS_USER:$OS_USER /var/lib/cloudbreak/
}

cbd_install() {
    : ${CBD_INSTALL_DIR:=/bin}
    : ${CBD_VERSION:?required}
    deubg "Install cbd: ${CBD_VERSION:?required} to ${CBD_INSTALL_DIR}"
    curl -Ls s3.amazonaws.com/public-repo-1.hortonworks.com/HDP/cloudbreak/cloudbreak-deployer_${CBD_VERSION:?required}_$(uname)_x86_64.tgz \
        | tar -xz -C ${CBD_INSTALL_DIR}
}

main() {
    debug "START docker ..."
    service docker start

    cbd_install
    cbd_init
    debug "cbd-init successfully finished"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

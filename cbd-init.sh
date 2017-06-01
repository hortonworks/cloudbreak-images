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
    cbd_prepare
    cbd generate
    cbd pull-parallel

    docker pull hortonworks/cloud-web:${CBD_VERSION}
    docker pull hortonworks/cloud-auth:${CBD_VERSION}
    docker pull hortonworks/cloudbreak-shell:${CBD_VERSION}
    docker pull postgres:9.4.1

    cat >> ~/.bashrc <<"EOF"
eval "$(bash -c 'cd /var/lib/cloudbreak-deployment; cbd bash-complete')"
EOF
    rm -rf certs *.yml *.log
}

cbd_prepare() {
  cd $CBD_DIR
  echo "export UAA_DEFAULT_SECRET=fakesecret" >> Profile
  echo "export UAA_DEFAULT_USER_PW=fakepw" >> Profile
}

cbd_cleanup() {
  cd $CBD_DIR
  sed -i.bak '/export UAA_DEFAULT_SECRET=fakesecret/d' ./Profile
  sed -i.bak '/export UAA_DEFAULT_USER_PW=fakepw/d' ./Profile
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

install_openjdk() {
  export JAVA_HOME=/usr/lib/jvm/java

  sudo yum install -y java-1.8.0-openjdk-devel
  sudo yum install -y java-1.8.0-openjdk-javadoc
  sudo yum install -y java-1.8.0-openjdk-src

  sudo mv /usr/lib/jvm/OpenJDK_GPLv2_and_Classpath_Exception.pdf /usr/lib/jvm/java
}


install_hdc_cli() {
  : ${HDC_CLI_VERSION:? required}
  : ${HDC_CLI_INSTALL_DIR:=/var/lib/cloudbreak/hdc-cli}

  mkdir -p $HDC_CLI_INSTALL_DIR
  cd $HDC_CLI_INSTALL_DIR

  curl -LO "https://s3-eu-west-1.amazonaws.com/hdc-cli/hdc-cli_${HDC_CLI_VERSION}_Darwin_x86_64.tgz"
  curl -LO "https://s3-eu-west-1.amazonaws.com/hdc-cli/hdc-cli_${HDC_CLI_VERSION}_Linux_x86_64.tgz"
  curl -LO "https://s3-eu-west-1.amazonaws.com/hdc-cli/hdc-cli_${HDC_CLI_VERSION}_Windows_x86_64.tgz"
   
  sudo tar -xzf hdc-cli_*$(uname)_x86_64.tgz  -C /bin || true

  for osname in Darwin Linux Windows; do
    ln -fs hdc-cli_*_${osname}_x86_64.tgz hdc-cli_${osname}_x86_64.tgz
  done

   hdc --version || echo "Warning: hdc cli installation failed"
   cd -
}

cleanup_aws_marketplace_eula() {
  if [[ "$COPY_AWS_MARKETPLACE_EULA" == false ]]; then
    sudo rm -f /etc/hortonworks/hdcloud*marketplace*
  else
    sudo rm -f /etc/hortonworks/hdcloud*technical-preview*
  fi
}

main() {
    debug "Update to docker 1.10.3"
    sudo service docker stop; sudo curl -Lo /usr/bin/docker https://get.docker.com/builds/Linux/x86_64/docker-1.10.3
    debug "Use overlay storage driver"
    sudo sed -i 's/^DOCKER_STORAGE_OPTIONS=/DOCKER_STORAGE_OPTIONS="-s overlay"/' /etc/sysconfig/docker-storage
    
    debug "START docker ..."
    sudo service docker start

    install_utils
    install_openjdk
    install_hdc_cli
    cbd_install
    cbd_init
    reset_docker
    reset_hostname
    reset_authorized_keys
    cleanup_aws_marketplace_eula
    cbd_cleanup
    debug "[DONE] $BASH_SOURCE"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

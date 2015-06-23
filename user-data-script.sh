
# let the script fail to cause the image build unsuccessfull
# set -eo pipefail

[[ "$TRACE" ]] && set -x

: ${IMAGES:=sequenceiq/ambari:2.0.0-consul sequenceiq/ambari-warmup:2.0.0-consul sequenceiq/consul:v0.5.0-v4 postgres:9.4.1 sequenceiq/docker-consul-watch-plugn:2.0.0-consul swarm:0.2.0 sequenceiq/munchausen:0.3 gliderlabs/alpine:3.1 sequenceiq/registrator:v5.2 sequenceiq/cb-gateway-nginx:0.2 sequenceiq/baywatch:v0.5.1 sequenceiq/baywatch-client:v0.5.1 ehazlett/cert-tool:0.0.3}
: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

permissive_iptables() {
  local provider=$(get_provider_from_packer)
  # need  iptables-services othervise the iptables save wil fail
  yum -y install iptables-services net-tools

  # check whether it can be applied on other cloud platforms
  if [ "openstack" == $provider ]; then
    iptables --flush INPUT
    iptables --flush FORWARD
    service iptables save
  fi
}

permissive_selinux() {
  sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
}

enable_ipforward() {
  sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
}

install_utils() {
  local provider=$(get_provider_from_packer)

  yum -y install unzip curl git wget bind-utils ntp cloud-utils-growpart

  if [ "azure" == $provider ] || [ "ec2" == $provider ]; then
    yum install -y cloud-init
  fi

  curl -o /usr/bin/jq http://stedolan.github.io/jq/download/linux64/jq && chmod +x /usr/bin/jq
}

install_docker() {
  curl -O -sSL https://get.docker.com/rpm/1.7.0/centos-7/RPMS/x86_64/docker-engine-1.7.0-1.el7.centos.x86_64.rpm
  yum -y localinstall --nogpgcheck docker-engine-1.7.0-1.el7.centos.x86_64.rpm
  yum install -y device-mapper-event-libs device-mapper-event device-mapper-event-devel
  systemctl daemon-reload
  systemctl start docker.service

  systemctl stop docker.service
  sed -i '/^ExecStart/s/$/ -H tcp:\/\/0.0.0.0:2376 --selinux-enabled --storage-driver=devicemapper --storage-opt=dm.basesize=30G/' /usr/lib/systemd/system/docker.service
  rm -rf /var/lib/docker
  systemctl start docker.service

  wait_for_docker

  systemctl enable docker.service
  chkconfig docker on
}

wait_for_docker() {
  while ! docker ps ; do
    systemctl start docker.service
    service docker restart
    sleep 20
  done
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
  cp /tmp/public_host_script_$provider.sh ${target}/public_host_script.sh

  chmod +x ${target}/*.sh
  ls -l $target/*.sh

  cp ${target}/register-ambari.sh /etc/init.d/register-ambari
  chown root:root /etc/init.d/register-ambari
  chkconfig register-ambari on
}

reset_hostname() {
  local provider=$(get_provider_from_packer)

  #/etc/sysconfig/network is not used by CentOS 7 anymore
  if [ "ec2" == $provider ] || [ "openstack" == $provider ] || [ "azure" == $provider ]; then
    sed -i '/syslog_fix_perms: ~/a preserve_hostname: true' /etc/cloud/cloud.cfg
  fi

  echo "Avoid pre-assigned hostname"
  rm -f /etc/hostname
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
    permissive_selinux
    permissive_iptables
    enable_ipforward
    install_scripts
    install_utils
    install_docker
    pull_images
    reset_hostname
    fix_fstab
    touch /tmp/ready
    sync
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

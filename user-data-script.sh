
# let the script fail to cause the image build unsuccessfull
# set -eo pipefail

[[ "$TRACE" ]] && set -x

: ${IMAGES:=sequenceiq/ambari:2.0.0-consul sequenceiq/ambari-warmup:2.0.0-consul sequenceiq/ambari:2.1.0-consul sequenceiq/consul:v0.5.0-v5 postgres:9.4.1 sequenceiq/docker-consul-watch-plugn:2.0.0-consul swarm:0.3.0 sequenceiq/munchausen:0.5.3 gliderlabs/alpine:3.1 sequenceiq/registrator:v5.2 sequenceiq/cb-gateway-nginx:0.2 sequenceiq/baywatch:v0.5.3 sequenceiq/baywatch-client:v0.5.3 sequenceiq/logrotate:v0.5.1 ehazlett/cert-tool:0.0.3}
: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

extend_rootfs() {
  yum -y install cloud-utils-growpart

  # Usable on GCP, does not harm anywhere else
  root_fs_device=$(mount | grep ' / ' | cut -d' ' -f 1 | sed s/1//g)
  growpart $root_fs_device 1
  xfs_growfs /
}

permissive_iptables() {
  local provider=$(get_provider_from_packer)
  # need to install iptables-services, othervise the 'iptables save' command will not be available
  yum -y install iptables-services net-tools

  iptables --flush INPUT
  iptables --flush FORWARD
  service iptables save
}

modify_waagent() {
  if [ -f /etc/waagent.conf ]; then
    cp /etc/waagent.conf /etc/waagent.conf.bak
    sed -i 's/Provisioning.SshHostKeyPairType.*/Provisioning.SshHostKeyPairType=ecdsa/' /etc/waagent.conf
    diff /etc/waagent.conf /etc/waagent.conf.bak
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

  yum -y install unzip curl git wget bind-utils ntp

  if [ "azure" == $provider ] || [ "ec2" == $provider ]; then
    yum install -y cloud-init
  fi

  curl -o /usr/bin/jq http://stedolan.github.io/jq/download/linux64/jq && chmod +x /usr/bin/jq
}

install_docker() {
  curl -O -sSL https://get.docker.com/rpm/1.7.0/centos-7/RPMS/x86_64/docker-engine-1.7.0-1.el7.centos.x86_64.rpm
  yum -y localinstall --nogpgcheck docker-engine-1.7.0-1.el7.centos.x86_64.rpm
  # need to check whether we really need these (GCP / OpenStack we don't)
  yum install -y device-mapper-event-libs device-mapper-event device-mapper-event-devel
  service docker start
  service docker stop
  sed -i '/^ExecStart/s/$/ -H tcp:\/\/0.0.0.0:2376 --selinux-enabled --storage-driver=devicemapper --storage-opt=dm.basesize=30G/' /usr/lib/systemd/system/docker.service
  rm -rf /var/lib/docker
  systemctl daemon-reload
  service docker start
  systemctl enable docker.service
}

pull_images() {
  set -e
  for i in ${IMAGES}; do
    docker pull ${i}
  done
  # Until the HDP is not released does not makes sense to Warmup
  docker tag sequenceiq/ambari:2.1.0-consul sequenceiq/ambari-warmup:2.1.0-consul
}

install_scripts() {
  local target=${1:-/usr/local}
  local provider=$(get_provider_from_packer)

  debug target=$target
  debug provider=$provider

  # script are copied by packer's file provisioner section
  cp /tmp/public_host_script_$provider.sh ${target}/public_host_script.sh

  chmod +x ${target}/*.sh
  ls -l $target/*.sh

}

reset_hostname() {
  echo "Avoid pre-assigned hostname"
  rm -vf /etc/hostname
}

configure_cloud_init() {
  if [ -f /etc/cloud/cloud.cfg ]; then
    #/etc/sysconfig/network is not used by CentOS 7 anymore
    cp /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.bak
    sed -i '/syslog_fix_perms: ~/a preserve_hostname: true' /etc/cloud/cloud.cfg
    diff /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.bak
  fi
}

reset_docker() {
  service docker stop
  echo "Deleting key.json in order to avoid swarm conflicts"
  rm -vf /etc/docker/key.json
}

reset_fstab() {
  echo "Removing ephemeral /dev/xvdb from fstab"
  cat /etc/fstab
  sed -i "/dev\/xvdb/ d" /etc/fstab
}

cleanup() {
  reset_hostname
  reset_docker
  reset_fstab
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
    modify_waagent
    extend_rootfs
    permissive_selinux
    permissive_iptables
    enable_ipforward
    install_utils
    install_scripts
    install_docker
    configure_cloud_init
    pull_images
    cleanup
    touch /tmp/ready
    sync
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"


# let the script fail to cause the image build unsuccessfull
# set -eo pipefail

[[ "$TRACE" ]] && set -x

: ${IMAGES:=sequenceiq/ambari:2.1.2-v4 sequenceiq/consul:v0.5.0-v5 postgres:9.4.1 sequenceiq/docker-consul-watch-plugn:1.0 swarm:0.4.0 sequenceiq/munchausen:0.5.5 gliderlabs/alpine:3.1 sequenceiq/registrator:v5.2 sequenceiq/cb-gateway-nginx:0.3 sequenceiq/baywatch:v0.5.3 sequenceiq/baywatch-client:v1.0.0 sequenceiq/logrotate:v0.5.1 sequenceiq/kerberos:2.1.0-consul ehazlett/cert-tool:0.0.3}
: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

update_centos_base_yum_repo() {
  # Use the same CentOS Base yum repo on CentOS images
  if grep "CentOS\|Derived from Red Hat" /etc/redhat-release > /dev/null; then
    cp -v /tmp/yum/CentOS-Base.repo /etc/yum.repos.d/
  fi
}

update_kernel() {
  yum install -y kernel-3.10.0-229.14.1.el7
  yum install -y kernel-tools-3.10.0-229.14.1.el7
  yum install -y systemd-208-20.el7_1.6
}

extend_rootfs() {
  yum -y install cloud-utils-growpart

  # Usable on GCP, does not harm anywhere else
  root_fs_device=$(mount | grep ' / ' | cut -d' ' -f 1 | sed s/1//g)
  growpart $root_fs_device 1 || true
  xfs_growfs / || true
}

permissive_iptables() {
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
    diff /etc/waagent.conf /etc/waagent.conf.bak || true
  fi
}

disable_selinux() {
  setenforce 0
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
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
  cp -v /tmp/docker/docker.repo /etc/yum.repos.d/
  yum install -y docker-engine-1.8.3

  cp -v /usr/lib/systemd/system/docker.service /usr/lib/systemd/system/docker.service.bak
  cp -v /tmp/docker/docker.service /usr/lib/systemd/system

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
}

install_scripts() {
  local target=${1:-/usr/local}
  local provider=$(get_provider_from_packer)

  debug target=$target
  debug provider=$provider

  # script are copied by packer's file provisioner section
  cp -v /tmp/scripts/public_host_script_$provider.sh ${target}/public_host_script.sh

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
    diff /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.bak || true
  fi
}

configure_console() {
  export GRUB_CONFIG='/etc/default/grub'
  if [ -f "$GRUB_CONFIG" ] && grep "GRUB_CMDLINE_LINUX" "$GRUB_CONFIG" | grep -q "console=tty0"; then
    # we want ttyS0 as the default console output, the default RedHat AMI on AWS sets tty0 as well
    sed -i -e '/GRUB_CMDLINE_LINUX/ s/ console=tty0//g' "$GRUB_CONFIG"
    grub2-mkconfig -o /boot/grub2/grub.cfg
  fi
}

copy_hadoop_lib() {
  # /data/jars directory is used because it is shared with the ambari-docker container on cloudbreak vms
  mkdir -p /data/jars
  cp -v /tmp/hadoop-lib/* /data/jars
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
  yum clean all
}

get_provider_from_packer() {
    : ${PACKER_BUILDER_TYPE:? required amazon-ebs/googlecompute/openstack}

    if [[ $PACKER_BUILDER_TYPE =~ amazon ]] ; then
        echo ec2
        return
    fi

    if [[ $PACKER_BUILDER_TYPE == "googlecompute" ]]; then
        echo gcp
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
    update_centos_base_yum_repo
    update_kernel
    modify_waagent
    extend_rootfs
    disable_selinux
    permissive_iptables
    enable_ipforward
    install_utils
    install_scripts
    install_docker
    configure_cloud_init
    configure_console
    pull_images
    copy_hadoop_lib
    cleanup
    sync
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

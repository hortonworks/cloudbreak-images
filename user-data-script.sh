#!/bin/bash

set -eo pipefail

[[ "$TRACE" ]] && set -x

: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

update_centos_base_yum_repo() {
  # Use the same CentOS Base yum repo on CentOS images
  if ! grep "CentOS\|Derived from Red Hat" /etc/redhat-release &> /dev/null; then
    rm -f /etc/yum.repos.d/CentOS-Base.repo
  fi
}

update_kernel() {
  if [[ $PACKER_BUILDER_TYPE == "azure" ]]; then
      mv /etc/yum.repos.d/CentOS-Base.repo.rpmnew /tmp/shared/etc/yum.repos.d/
  fi
  
  yum clean all
  yum update -y
  yum install -y \
    kernel-$YUM_VERSION_KERNEL \
    kernel-tools-$YUM_VERSION_KERNEL \
    systemd-$YUM_VERSION_SYSTEMD
}

extend_rootfs() {
  yum -y install cloud-utils-growpart

  # Usable on GCP, does not harm anywhere else
  root_fs_device=$(mount | grep ' / ' | cut -d' ' -f 1 | sed s/1//g)
  growpart $root_fs_device 1 || :
  xfs_growfs / || :
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
    sed -i 's/Provisioning.DecodeCustomData.*/Provisioning.DecodeCustomData=y/' /etc/waagent.conf
    sed -i 's/Provisioning.ExecuteCustomData.*/Provisioning.ExecuteCustomData=y/' /etc/waagent.conf
    diff /etc/waagent.conf /etc/waagent.conf.bak || :
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

  yum -y install unzip curl git wget bind-utils ntp tmux bash-completion

  if [ "ec2" == $provider ]; then
    yum install -y cloud-init
fi

  curl -o /usr/bin/jq http://stedolan.github.io/jq/download/linux64/jq && chmod +x /usr/bin/jq
}

install_docker() {
  yum install -y docker-engine-$YUM_VERSION_DOCKER

  systemctl daemon-reload
  service docker start
  systemctl enable docker.service

  getent passwd $OS_USER || adduser $OS_USER
  usermod -a -G docker $OS_USER
}

reset_hostname() {
  echo "Avoid pre-assigned hostname"
  rm -vf /etc/hostname
}

configure_cloud_init() {
  if [ -f /etc/cloud/cloud.cfg ]; then
    #/etc/sysconfig/network is not used by CentOS 7 anymore
    sed -i.bak '/syslog_fix_perms: ~/a preserve_hostname: true' /etc/cloud/cloud.cfg
    diff /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.bak || :
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
    install_docker
    configure_cloud_init
    configure_console
    cleanup
    sync
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

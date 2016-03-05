#!/bin/bash

set -eo pipefail

[[ "$TRACE" ]] && set -x

: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

update_centos() {
  # Use the same CentOS Base yum repo on CentOS images
  if grep "Red Hat Enterprise Linux Server" /etc/redhat-release &> /dev/null; then
    rm -f /etc/yum.repos.d/CentOS-Base.repo
  fi
  yum clean all
  yum update -y
}

permissive_iptables() {
  # need to install iptables-services, othervise the 'iptables save' command will not be available
  yum -y install iptables-services net-tools

  iptables --flush INPUT
  iptables --flush FORWARD
  service iptables save
}

disable_selinux() {
  setenforce 0
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
}

enable_ipforward() {
  sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
}

install_utils() {
  yum -y install unzip curl git wget bind-utils ntp tmux bash-completion

  if [[ $PACKER_BUILDER_TYPE =~ amazon ]] ; then
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
  usermod -a -G docker centos || :
  usermod -a -G docker $OS_USER
}

reset_hostname() {
  echo "Avoid pre-assigned hostname"
  rm -vf /etc/hostname
}

grant-sudo-to-os-user() {
    echo "$OS_USER ALL=NOPASSWD: ALL" > /etc/sudoers.d/$OS_USER
    chmod o-r /etc/sudoers.d/$OS_USER
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


check_params() {
    : ${PACKER_BUILDER_TYPE:? required amazon-ebs/googlecompute/openstack }
}

main() {
    check_params
    update_centos
    disable_selinux
    permissive_iptables
    enable_ipforward
    install_utils
    install_docker
    grant-sudo-to-os-user
    configure_console
    cleanup
    sync
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

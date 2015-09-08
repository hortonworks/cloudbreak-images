#!/bin/bash

[[ "$TRACE" ]] && set -x

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

set_resourcelimits_for_docker() {
  sed -i 's/LimitNOFILE=.*/LimitNOFILE=200000/' /usr/lib/systemd/system/docker.service
  sed -i 's/LimitNPROC=.*/LimitNPROC=16384/' /usr/lib/systemd/system/docker.service
}

disable_ipv6() {
  echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
  echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
  echo 'NETWORKING_IPV6=no' >> /etc/sysconfig/network
  echo 'IPV6INIT="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
  systemctl disable ip6tables.service
  sed -i 's/#AddressFamily any/AddressFamily inet/' /etc/ssh/sshd_config
}

disable_thp() {
  mkdir -p /etc/tuned/custom
  mv /tmp/scripts/disable_thp_defrag.sh /etc/tuned/custom
  cat << EOF > /etc/tuned/custom/tuned.conf
[main]
include=virtual-guest

[vm]
transparent_hugepages=never

[script]
script=disable_thp_defrag.sh
EOF
  tuned-adm profile custom
}

disable_swap() {
  echo 'vm.swappiness = 0' >> /etc/sysctl.conf
}

set_dirty_ratio () {
  echo 'vm.dirty_background_ratio = 10' >> /etc/sysctl.conf
  echo 'vm.dirty_ratio = 20' >> /etc/sysctl.conf
}

main() {
  set_resourcelimits_for_docker
  disable_ipv6
  disable_thp
  disable_swap
  set_dirty_ratio
  sync
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

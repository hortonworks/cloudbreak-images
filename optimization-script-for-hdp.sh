#!/bin/bash

[[ "$TRACE" ]] && set -x

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

disable_ipv6() {
  echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
  echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
  echo 'NETWORKING_IPV6=no' >> /etc/sysconfig/network
  echo 'IPV6INIT="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
  systemctl disable ip6tables.service
  sed -i 's/#AddressFamily any/AddressFamily inet/' /etc/ssh/sshd_config
}

disable_swap() {
  echo 'vm.swappiness = 0' >> /etc/sysctl.conf
}

set_dirty_ratio () {
  echo 'vm.dirty_background_ratio = 10' >> /etc/sysctl.conf
  echo 'vm.dirty_ratio = 20' >> /etc/sysctl.conf
}

main() {
  disable_ipv6
  tuned-adm profile custom
  disable_swap
  set_dirty_ratio
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

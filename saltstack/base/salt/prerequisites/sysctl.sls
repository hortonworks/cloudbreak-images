vm.swappiness:
  sysctl.present:
    - value: 0

net.ipv4.ip_local_reserved_ports:
  sysctl.present:
    - value: "41000-51000"

net.ipv4.ip_local_port_range:
  sysctl.present:
    - value: "32768 61000"

net.core.netdev_max_backlog:
   sysctl.present:
    - value: 20000

net.core.somaxconn:
   sysctl.present:
    - value: 16384

net.ipv4.conf.lo.forwarding:
   sysctl.present:
    - value: 0

net.ipv4.tcp_rmem:
   sysctl.present:
    - value: "4096 65536 134217728"

net.ipv4.tcp_wmem:
   sysctl.present:
    - value: "4096 65536 134217728"

net.ipv4.tcp_mtu_probing:
   sysctl.present:
    - value: 1

net.ipv4.tcp_fin_timeout:
   sysctl.present:
    - value: 4

vm.dirty_background_ratio:
  sysctl.present:
    - value: 80

vm.dirty_ratio:
  sysctl.present:
    - value: 80
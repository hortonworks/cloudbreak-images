vm.swappiness:
  sysctl.present:
    - value: 0

net.ipv4.ip_local_reserved_ports:
  sysctl.present:
    - value: "41000-51000"

net.ipv4.ip_local_port_range:
  sysctl.present:
    - value: "32768 61000"

vm.dirty_background_ratio:
  sysctl.present:
    - value: 10

vm.dirty_ratio:
  sysctl.present:
    - value: 20
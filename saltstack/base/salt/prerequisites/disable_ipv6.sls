net.ipv6.conf.default.disable_ipv6:
  sysctl.present:
    - value: 1

net.ipv6.conf.all.disable_ipv6:
  sysctl.present:
    - value: 1

net.ipv6.conf.lo.disable_ipv6:
  sysctl.present:
    - value: 1

net.ipv6.conf.eth0.disable_ipv6:
  sysctl.present:
    - value: 1

{% if grains['os_family'] == 'RedHat' %}
/etc/sysconfig/network:
  file.replace:
    - name: /etc/sysconfig/network
    - pattern: "^NETWORKING_IPV6.*"
    - repl: "NETWORKING_IPV6=\"no\""
    - append_if_not_found: True

/etc/sysconfig/network-scripts/ifcfg-eth0:
  file.replace:
    - name: /etc/sysconfig/network-scripts/ifcfg-eth0
    - pattern: "^IPV6INIT.*"
    - repl: "IPV6INIT=\"no\""
    - append_if_not_found: True

ip6tables_uninstall:
  service.dead:
    - name: ip6tables
    - enable: False
  pkg.purged:
    - name: ip6tables
{% endif %}

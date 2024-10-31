{% if pillar['subtype'] != 'Docker' %}
net.ipv6.conf.default.disable_ipv6:
  sysctl.present:
    - value: 1

net.ipv6.conf.all.disable_ipv6:
  sysctl.present:
    - value: 1

net.ipv6.conf.lo.disable_ipv6:
  sysctl.present:
    - value: 1

net.ipv6.conf.{{ pillar['network_interface'] }}.disable_ipv6:
  sysctl.present:
    - value: 1
{% endif %}

{% if grains['os_family'] == 'RedHat' %}
/etc/sysconfig/network:
  file.replace:
    - name: /etc/sysconfig/network
    - pattern: "^NETWORKING_IPV6.*"
    - repl: "NETWORKING_IPV6=\"no\""
    - append_if_not_found: True


create_missing_ifcfg_file:
  cmd.run:
    - name: touch /etc/sysconfig/network-scripts/ifcfg-{{ pillar['network_interface'] }}

/etc/sysconfig/network-scripts/ifcfg-{{ pillar['network_interface'] }}:
  file.replace:
    - name: /etc/sysconfig/network-scripts/ifcfg-{{ pillar['network_interface'] }}
    - pattern: "^IPV6INIT.*"
    - repl: "IPV6INIT=\"no\""
    - append_if_not_found: True
{% endif %}

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

disable-init-ipv6-eth0:
  file.replace:
    - name: /etc/sysconfig/network-scripts/ifcfg-{{ pillar['network_interface'] }}
    - pattern: "^IPV6INIT.*"
    - repl: "IPV6INIT=\"no\""
    - append_if_not_found: True

disable-dhcp-ipv6-eth0:
  file.replace:
    - name: /etc/sysconfig/network-scripts/ifcfg-{{ pillar['network_interface'] }}
    - pattern: "^DHCPV6C.*"
    - repl: "DHCPV6C=\"no\""
    - append_if_not_found: True

{% if salt['environ.get']('OS') == 'redhat8' %}
/etc/cloud/cloud.cfg.d/99-disable-ipv6.cfg:
  file.managed:
    - user: root
    - group: root
    - source:
      - salt://{{ slspath }}/etc/cloud/cloud.cfg.d/99-disable-ipv6.cfg
    - mode: 755
    - template: jinja
    - defaults:
        network_interface: {{ pillar['network_interface'] }}
{% endif %}
{% endif %}

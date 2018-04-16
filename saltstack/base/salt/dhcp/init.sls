{% if grains['os_family'] == 'Suse' %}

enable_dhcp_set_hostname:
  file.replace:
    - name: /etc/sysconfig/network/dhcp
    - pattern: "^DHCLIENT_SET_HOSTNAME=*"
    - repl: "DHCLIENT_SET_HOSTNAME=\"yes\""
    - append_if_not_found: True

/etc/netconfig.d/dns-resolver:
  file.managed:
    - source: salt://{{ slspath }}/etc/netconfig.d/dns-resolver
    - include_empty: True
    - mode: 755

{% else %}

/etc/dhcp:
  file.recurse:
    - source: salt://{{ slspath }}/etc/dhcp/
    - template: jinja
    - include_empty: True
    - file_mode: 755

/etc/NetworkManager:
  file.recurse:
    - source: salt://{{ slspath }}/etc/NetworkManager/
    - file_mode: 755
    - include_empty: True

{% endif %}

{% if pillar['subtype'] == 'Docker' %}
/etc/resolv.conf:
  file.managed:
    - name: /etc/resolv.conf.ycloud
    - source: salt://{{ slspath }}/etc/resolv.conf.ycloud
{% endif %}

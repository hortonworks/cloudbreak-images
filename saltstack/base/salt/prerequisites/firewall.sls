{% if grains['os_family'] == 'RedHat' and grains['osmajorrelease'] | int == 6  %}

disable_iptables_service:
  service.dead:
    - name: iptables
    - enable: False

disable_ip6tables_service:
  service.dead:
    - name: ip6tables
    - enable: False

remove_ip6tables:
  pkg.purged:
    - name: ip6tables

{% endif %}
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

{% elif pillar['OS'] == 'redhat7' %}

disable_firewalld_service:
  service.dead:
    - name: firewalld
    - enable: False

mask_firewalld_service:
  service.masked:
    - name: firewalld

{% elif grains['os_family'] == 'Suse' %}

disable_susefirewall_setup_service:
  service.dead:
    - name: SuSEfirewall2_setup
    - enable: False

disable_susefirewall_init_service:
  service.dead:
    - name: SuSEfirewall2_init
    - enable: False

disable_susefirewall_service:
  service.dead:
    - name: SuSEfirewall2
    - enable: False

{% endif %}
base:
  '*':
    - prerequisites
{% if not salt['file.file_exists']('/etc/waagent.conf') %}
    - cloud-init
{% endif %}
    - unbound
    - salt-bootstrap
    - salt
    - monitoring
{% if pillar['subtype'] != 'Docker' %}
{% if grains['os_family'] == 'Debian' %}
    - resolvconf
{% else %}
    - dhcp
{% endif %}
{% endif %}
    - performance
    - custom

base:
  '*':
    - prerequisites
{% if not salt['file.file_exists']('/etc/waagent.conf') %}
    - cloud-init
{% endif %}
    - unbound
    - nginx
    - salt-bootstrap
    - salt
    - postgresql
    - unbound
    - monitoring
    - dhcp
    - performance
    - custom

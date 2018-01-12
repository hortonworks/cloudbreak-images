base:
  '*':
    - prerequisites
{% if salt['file.file_exists']('/etc/waagent.conf') %}
    - waagent
{% else %}
    - cloud-init
{% endif %}
    - unbound
    - nginx
    - salt-bootstrap
    - salt
    - postgres-jdbc-driver
    - unbound
    - monitoring
    - dhcp
    - performance
    - custom
base:
  '*':
    - prerequisites
{% if not salt['file.file_exists']('/etc/waagent.conf') %}
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
    - pre-warm
    - monitoring
    - dhcp
    - performance
    - custom

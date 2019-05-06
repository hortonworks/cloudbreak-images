base:
  '*':
    - prerequisites
{% if not salt['file.file_exists']('/etc/waagent.conf') %}
    - cloud-init
{% endif %}
    - nginx
    - salt-bootstrap
    - salt
    - postgresql
    - monitoring
    - performance
    - custom

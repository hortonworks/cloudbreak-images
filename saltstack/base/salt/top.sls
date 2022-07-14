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
    - telemetry
    - ccm-client
    - ccmv2
    - custom
    - mount
{% if not salt['file.directory_exists']('/yarn-private') %}
    - chrony
{% endif %}

base:
  '*':
    - prerequisites
{% if not salt['file.file_exists']('/etc/waagent.conf') %}
    - cloud-init
{% endif %}
    - nginx
    - python3
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
{% if salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' %}
    - luks
{% endif %}
{% if pillar['subtype'] != 'Docker' or pillar['OS'] == 'redhat8' %}
    - chrony
{% endif %}

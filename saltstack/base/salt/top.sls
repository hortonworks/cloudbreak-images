base:
  '*':
    - prerequisites
{% if not salt['file.file_exists']('/etc/waagent.conf') %}
    - cloud-init
{% endif %}
    - hostname
    - nginx
    - python3
    - salt-bootstrap
    - salt
{% if salt['environ.get']('CUSTOM_IMAGE_TYPE') != 'freeipa' %}
    - postgresql
{% endif %}
    - monitoring
    - performance
    - telemetry
    - ccmv2
    - custom
    - mount
{% if salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' %}
    - luks
    - userdata-secrets
{% endif %}
{% if pillar['subtype'] != 'Docker' or pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' %}
    - chrony
{% endif %}
{% if pillar['subtype'] != 'Docker' and (pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9') %}
    - selinux
{% endif %}

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
{% if pillar['subtype'] != 'Docker' and pillar['OS'] == 'redhat8' %}
    - selinux
{% endif %}
{% if salt['environ.get']('CUSTOM_IMAGE_TYPE') != 'freeipa' %}
    - postgresql
{% endif %}
    - monitoring
    - performance
    - telemetry
    - ccm-client
    - ccmv2
    - custom
    - mount
{% if salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' %}
    - luks
    - userdata-secrets
{% endif %}
{% if pillar['subtype'] != 'Docker' or pillar['OS'] == 'redhat8' %}
    - chrony
{% endif %}

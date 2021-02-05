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
{% if salt['environ.get']('INCLUDE_FLUENT') == 'Yes' %}
    - fluent
{% endif %}
    - ccm-client
    - ccmv2-inverting-proxy-agent
{% if salt['environ.get']('INCLUDE_CIS') == 'Yes' %}
    - cis-controls
{% endif %}
    - custom

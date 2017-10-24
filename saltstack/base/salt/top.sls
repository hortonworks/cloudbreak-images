base:
  '*':
    - prerequisites
    - cloud-init
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
    - waagent
    - custom
    {% if pillar['CUSTOM_IMAGE_TYPE'] == 'base' %}
    - validate
    - cleanup
    {% endif %}

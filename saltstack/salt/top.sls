base:
  '*':
    - prerequisites
    - eula
    - cloud-init
    - selinux
    - unbound
    - consul
    - consul-template
    - service-registration
    - nginx
    - haveged
    - kerberos
    - salt-bootstrap
    - salt
    - java
    - jdbc-drivers
    - unbound
    - consul
    - consul-template
    - node_exporter
    - jmx_exporter
{% if grains['os_family'] == 'RedHat' %}
    {% if pillar['AMBARI_VERSION'] and pillar['AMBARI_BASEURL'] and pillar['AMBARI_GPGKEY'] %}
    - ambari
    - grafana
    - smartsense
    {% if  pillar['HDP_STACK_VERSION'] and  pillar['HDP_VERSION'] and  pillar['HDP_BASEURL'] and  pillar['HDP_REPOID'] %}
    - pre-warm
    {% endif %}
    {% endif %}
{% endif %}
    - prometheus
    - dhcp
    - performance
    - waagent
    - cleanup

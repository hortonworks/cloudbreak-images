base:
  '*':
    - prerequisites
    - simple-webserver
    - eula
{% if not salt['file.file_exists']('/etc/waagent.conf') %}
    - cloud-init
{% endif %}
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
    - custom
{% if salt['file.file_exists']('/etc/waagent.conf') %}
    - waagent
{% endif %}
    - cleanup

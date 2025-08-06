hortonworks:
  '*':
    - unbound
{% if pillar['subtype'] != 'Docker' %}
    - dhcp
{% endif %}
    - eula
    - kerberos
    - java
    - pre-warm
{% if salt['environ.get']('INCLUDE_METERING') == 'Yes' %}
    - metering
{% endif %}

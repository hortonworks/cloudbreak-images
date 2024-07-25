hortonworks:
  '*':
    - unbound
{% if pillar['subtype'] != 'Docker' %}
    - dhcp
{% endif %}
    - simple-webserver
    - eula
    - kerberos
    - java
    - pre-warm

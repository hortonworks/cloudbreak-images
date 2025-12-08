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
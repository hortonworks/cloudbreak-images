hortonworks:
  '*':
    - unbound
{% if pillar['subtype'] != 'Docker' %}
{% if grains['os_family'] == 'Debian' %}
    - resolvconf
{% else %}
    - dhcp
{% endif %}
{% endif %}
    - simple-webserver
    - eula
    - kerberos
{% if not pillar['oracle_java'] %}
    - java
{% endif %}
    - pre-warm
{% if salt['environ.get']('INCLUDE_FLUENT') == 'Yes' %}
    - fluent
{% endif %}

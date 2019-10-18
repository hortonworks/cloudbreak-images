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
{% if salt['environ.get']('INCLUDE_METERING') == 'Yes' %}
    - metering
{% if grains['os_family'] == 'Suse' and grains['osmajorrelease'] | int == 12 %}
    - autossh
{% endif %}
{% endif %}

hortonworks:
  '*':
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

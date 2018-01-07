hortonworks:
  '*':
    - simple-webserver
    - eula
    - kerberos
{% if not pillar['oracle_java'] %}
    - java
{% endif %}

JAVA_HOME:
{% if grains['os_family'] == 'RedHat' %}
  {{ salt['environ.get']('PREINSTALLED_JAVA_HOME') | default('/usr/java/default', True) }}
{% else %}
  /usr/lib/jvm/java-8-oracle
{% endif %}

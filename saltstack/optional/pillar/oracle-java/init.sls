{% if salt['environ.get']('PREINSTALLED_JAVA_HOME', '') != "" %}
JAVA_HOME: {{ salt['environ.get']('PREINSTALLED_JAVA_HOME') }}
{% else %}
JAVA_HOME: /usr/java/default
{% endif %}
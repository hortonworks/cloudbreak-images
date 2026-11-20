{% set default_java_home = '/usr/lib/jvm/java' %}

JAVA_HOME: {{ salt['environ.get']('PREINSTALLED_JAVA_HOME') | default(default_java_home, True) }}
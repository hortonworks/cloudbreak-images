JAVA_HOME: {{ salt['environ.get']('PREINSTALLED_JAVA_HOME') | default('/usr/java/default', True) }}

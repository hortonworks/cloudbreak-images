{% set default_java_home = '/usr/lib/jvm/java' %}

JAVA_HOME: {{ salt['environ.get']('PREINSTALLED_JAVA_HOME') | default(default_java_home, True) }}

openjdk_packages:
{% if salt['environ.get']('OS') == 'redhat9' %}
  - java-17-openjdk-headless
  - java-17-openjdk-devel
  - java-21-openjdk-headless
  - java-21-openjdk-devel
{% elif salt['environ.get']('OS') == 'redhat8' %}
{% if salt['environ.get']('STACK_VERSION').split('.') | map('int') | list < '7.3.2'.split('.') | map('int') | list %}
{% if salt['environ.get']('ARCHITECTURE') != 'arm64' %}
  - java-1.8.0-openjdk-headless
  - java-1.8.0-openjdk-devel
{% endif %}
{% if salt['environ.get']('STACK_VERSION').split('.') | map('int') | list < '7.3.1'.split('.') | map('int') | list %}
  - java-11-openjdk-headless
  - java-11-openjdk-devel
{% endif %}
{% endif %}
  - java-17-openjdk-headless
  - java-17-openjdk-devel
{% else %}
  - java-1.8.0-openjdk-headless
  - java-1.8.0-openjdk-devel
  - java-1.8.0-openjdk-javadoc
  - java-1.8.0-openjdk-src
  - java-11-openjdk-headless
  - java-11-openjdk-devel
  - java-11-openjdk-javadoc
  - java-11-openjdk-src
{% endif %}

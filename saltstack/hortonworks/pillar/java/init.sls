{% set default_java_home = '/usr/lib/jvm/java' %}

JAVA_HOME: {{ salt['environ.get']('PREINSTALLED_JAVA_HOME') | default(default_java_home, True) }}

openjdk_packages:
{% if salt['environ.get']('OS') == 'redhat7' %}
  - java-1.8.0-openjdk-headless
  - java-1.8.0-openjdk-devel
  - java-11-openjdk-headless
  - java-11-openjdk-devel
{% elif salt['environ.get']('OS') == 'redhat8' %}
  - java-1.8.0-openjdk-headless
  - java-1.8.0-openjdk-devel
  - java-11-openjdk-headless
  - java-11-openjdk-devel
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


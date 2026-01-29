{% set default_java_home = '/usr/lib/jvm/java' %}

JAVA_HOME: {{ salt['environ.get']('PREINSTALLED_JAVA_HOME') | default(default_java_home, True) }}

# amazon-ebs.aws-redhat8:     - No version matching '17.0.17*' found for package 'java-17-openjdk-headless' (available: 1:17.0.18.0.8-1.el8, 1:17.0.17.0.10-1.el8, 1:17.0.16.0.8-2.el8, 1:17.0.15.0.6-2.el8, 1:17.0.14.0.7-3.el8, 1:17.0.13.0.11-3.el8, 1:17.0.12.0.7-2.el8, 1:17.0.11.0.9-2.el8, 1:17.0.10.0.7-2.el8, 1:17.0.9.0.9-2.el8, 1:17.0.8.0.7-2.el8, 1:17.0.7.0.7-3.el8, 1:17.0.7.0.7-1.el8_7, 1:17.0.6.0.10-3.el8_7, 1:17.0.5.0.8-2.el8_6, 1:17.0.5.0.8-1.el8_7, 1:17.0.4.1.1-6.el8, 1:17.0.4.1.1-2.el8_6, 1:17.0.4.0.8-2.el8_6, 1:17.0.3.0.7-2.el8_6, 1:17.0.3.0.6-2.el8_5, 1:17.0.2.0.8-15.el8, 1:17.0.2.0.8-4.el8_5, 1:17.0.1.0.12-2.el8_5, 1:17.0.0.0.35-4.el8)
# amazon-ebs.aws-redhat8:     - No version matching '17.0.17*' found for package 'java-17-openjdk-devel' (available: 1:17.0.18.0.8-1.el8, 1:17.0.17.0.10-1.el8, 1:17.0.16.0.8-2.el8, 1:17.0.15.0.6-2.el8, 1:17.0.14.0.7-3.el8, 1:17.0.13.0.11-3.el8, 1:17.0.12.0.7-2.el8, 1:17.0.11.0.9-2.el8, 1:17.0.10.0.7-2.el8, 1:17.0.9.0.9-2.el8, 1:17.0.8.0.7-2.el8, 1:17.0.7.0.7-3.el8, 1:17.0.7.0.7-1.el8_7, 1:17.0.6.0.10-3.el8_7, 1:17.0.5.0.8-2.el8_6, 1:17.0.5.0.8-1.el8_7, 1:17.0.4.1.1-6.el8, 1:17.0.4.1.1-2.el8_6, 1:17.0.4.0.8-2.el8_6, 1:17.0.3.0.7-2.el8_6, 1:17.0.3.0.6-2.el8_5, 1:17.0.2.0.8-15.el8, 1:17.0.2.0.8-4.el8_5, 1:17.0.1.0.12-2.el8_5, 1:17.0.0.0.35-4.el8)

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
  - java-17-openjdk-headless: '1:17.0.17.0.10-1.el8'
  - java-17-openjdk-devel: '1:17.0.17.0.10-1.el8'
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

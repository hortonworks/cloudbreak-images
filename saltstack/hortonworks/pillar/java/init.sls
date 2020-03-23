{% if grains['os_family'] == 'Suse' %}
    {% set default_java_home = '/usr/lib64/jvm/java-openjdk' %}
{% else %}
    {% set default_java_home = '/usr/lib/jvm/java' %}
{% endif %}

JAVA_HOME: {{ salt['environ.get']('PREINSTALLED_JAVA_HOME') | default(default_java_home, True) }}
oracle_java: {{ salt['environ.get']('OPTIONAL_STATES', '') == 'oracle-java' }}

{% if (grains['os'] == 'Debian' and grains['osmajorrelease'] | int == 7) or
      (grains['os'] == 'Ubuntu' and grains['osmajorrelease'] | int <= 14)
%}
  {% set openjdk_version = 7 %}
{% else %}
  {% set openjdk_version = 11 %}
{% endif %}

openjdk_version: {{ openjdk_version }}

openjdk_packages:
{% if grains['os_family'] == 'Debian' %}
  - openjdk-{{ openjdk_version }}-jre-headless
  - openjdk-{{ openjdk_version }}-doc
  - openjdk-{{ openjdk_version }}-source
  - openjdk-{{ openjdk_version }}-jdk
{% elif grains['os_family'] == 'Suse' %}
  - java-1_8_0-openjdk
  - java-1_8_0-openjdk-devel
  - java-1_8_0-openjdk-headless
{% else %}
  - java-1.8.0-openjdk-headless
  - java-1.8.0-openjdk-devel
  - java-1.8.0-openjdk-javadoc
  - java-1.8.0-openjdk-src
{% endif %}

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
  {% if salt['environ.get']('JAVA_VERSION') is defined %}
    {% set openjdk_version = salt['environ.get']('JAVA_VERSION') %}
  {% else %}
    {% set openjdk_version = 8 %}
  {% endif %}
{% endif %}

openjdk_version: {{ openjdk_version }}
openjdk_packages:
{% if grains['os_family'] == 'Debian' %}
  - openjdk-{{ openjdk_version }}-jre-headless
  - openjdk-{{ openjdk_version }}-doc
  - openjdk-{{ openjdk_version }}-source
  - openjdk-{{ openjdk_version }}-jdk
{% elif grains['os_family'] == 'Suse' %}
  - java-{{ openjdk_version }}-openjdk
  - java-{{ openjdk_version }}-openjdk-devel
  - java-{{ openjdk_version }}-openjdk-headless
{% else %}
  - java-{{ openjdk_version }}-openjdk-headless
  - java-{{ openjdk_version }}-openjdk-devel
  - java-{{ openjdk_version }}-openjdk-javadoc
  - java-{{ openjdk_version }}-openjdk-src
{% endif %}

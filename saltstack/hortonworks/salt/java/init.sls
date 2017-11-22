{% if grains['os_family'] == 'RedHat' %}
remove_openjdk17:
  pkg.removed:
    - name: java-1.7.0-openjdk

{% if grains['osmajorrelease'] == 7 and grains['os'] =='RedHat' %}
enable_redhat_rhui_repos:
  file.replace:
    - name: /etc/yum.repos.d/redhat-rhui.repo
    - pattern: '^enabled=[0,1]'
    - repl: 'enabled=1'
{% endif %}
{% endif %}

set_java_home_user:
  file.managed:
    - name: /etc/profile.d/java.sh
    - source: salt://{{ slspath }}/etc/profile.d/java.sh
    - mode: 755

{% set preinstalled_java_home=salt['environ.get']('PREINSTALLED_JAVA_HOME') %}

{% if preinstalled_java_home %}

{% if grains['init'] == 'systemd' %}
set_java_home_systemd:
  file.replace:
    - name: /etc/systemd/system.conf
    - pattern: \#+DefaultEnvironment=.*
    - repl: DefaultEnvironment=JAVA_HOME={{ preinstalled_java_home }}
{% endif %}

set_custom_java_home:
  file.replace:
    - name: /etc/profile.d/java.sh
    - pattern: .*JAVA_HOME.*
    - repl: export JAVA_HOME={{ preinstalled_java_home }}

{% else %}
install_openjdk:
  pkg.installed:
    - pkgs:
      {% if grains['os_family'] == 'RedHat' %}
      - java-1.8.0-openjdk-headless
      - java-1.8.0-openjdk-devel
      - java-1.8.0-openjdk-javadoc
      - java-1.8.0-openjdk-src
      {% elif grains['os_family'] == 'Debian' %}
        - openjdk-8-jre-headless
        - openjdk-8-doc
        - openjdk-8-source
        - openjdk-8-jdk
      {% endif %}


{% if grains['init'] == 'systemd' %}
set_java_home_systemd:
  file.replace:
    - name: /etc/systemd/system.conf
    - pattern: \#+DefaultEnvironment=.*
    - repl: DefaultEnvironment=JAVA_HOME=/usr/lib/jvm/java
{% endif %}

add_openjdk_gplv2:
  file.managed:
    {% if grains['os_family'] == 'RedHat' %}
    - name: /usr/lib/jvm/OpenJDK_GPLv2_and_Classpath_Exception.pdf
    {% elif grains['os_family'] == 'Debian' %}
    - name: /usr/lib/jvm/java-7-openjdk-amd64/OpenJDK_GPLv2_and_Classpath_Exception.pdf

    {% endif %}
    - source: salt://java/usr/lib/jvm/OpenJDK_GPLv2_and_Classpath_Exception.pdf

{% endif %}
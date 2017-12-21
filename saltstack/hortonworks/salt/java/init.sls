set_java_home_user:
  file.managed:
    - name: /etc/profile.d/java.sh
    - mode: 755
    - contents: |
        export JAVA_HOME={{ pillar['JAVA_HOME'] }}

{% if grains['init'] == 'systemd' -%}
set_java_home_systemd:
  file.replace:
    - name: /etc/systemd/system.conf
    - pattern: \#+DefaultEnvironment=.*
    - repl: DefaultEnvironment=JAVA_HOME={{ pillar['JAVA_HOME'] }}
{% endif %}

{% if grains['os_family'] == 'RedHat' %}

{% if grains['os'] == 'RedHat' and grains['osmajorrelease'] | int == 7 %}
enable_redhat_rhui_repos:
  file.replace:
    - name: /etc/yum.repos.d/redhat-rhui.repo
    - pattern: '^enabled=[0,1]'
    - repl: 'enabled=1'
{% endif %}

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

{% endif %}
install_openjdk:
  pkg.installed:
    - pkgs:
      - java-1.8.0-openjdk-headless
      - java-1.8.0-openjdk-devel
      - java-1.8.0-openjdk-javadoc
      - java-1.8.0-openjdk-src

{% elif grains['os_family'] == 'Debian' %}

{% if (grains['os'] == 'Debian' and grains['osmajorrelease'] | int == 7) or
      (grains['os'] == 'Ubuntu' and grains['osmajorrelease'] | int <= 14)
%}
install_openjdk:
  pkg.installed:
    - pkgs:
      - openjdk-7-jre-headless
      - openjdk-7-doc
      - openjdk-7-source
      - openjdk-7-jdk

create_jvm_symlink:
  file.symlink:
    - name: /usr/lib/jvm/java
    - target: /usr/lib/jvm/java-7-openjdk-amd64

{% else %}
install_openjdk:
  pkg.installed:
    - pkgs:
      - openjdk-8-jre-headless
      - openjdk-8-doc
      - openjdk-8-source
      - openjdk-8-jdk

create_jvm_symlink:
  file.symlink:
    - name: /usr/lib/jvm/java
    - target: /usr/lib/jvm/java-8-openjdk-amd64
{% endif %}

{% endif %}

add_openjdk_gplv2:
  file.managed:
    - name: /usr/lib/jvm/OpenJDK_GPLv2_and_Classpath_Exception.pdf
    - source: salt://java/usr/lib/jvm/OpenJDK_GPLv2_and_Classpath_Exception.pdf

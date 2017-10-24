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

install_openjdk:
  pkg.installed:
    - pkgs:
      {% if grains['os_family'] == 'RedHat' %}
      - java-1.8.0-openjdk-headless
      - java-1.8.0-openjdk-devel
      - java-1.8.0-openjdk-javadoc
      - java-1.8.0-openjdk-src
      {% elif grains['os_family'] == 'Debian' %}
        - openjdk-7-jre-headless
        - openjdk-7-doc
        - openjdk-7-source
        - openjdk-7-jdk
      {% endif %}

set_java_home:
  environ.setenv:
    - name: JAVA_HOME
    {% if grains['os_family'] == 'RedHat' %}
    - value: /usr/lib/jvm/java
    {% elif grains['os_family'] == 'Debian' %}
    - value: /usr/lib/jvm/java-7-openjdk-amd64
    {% endif %}
    - update_minion: True

add_openjdk_gplv2:
  file.managed:
    {% if grains['os_family'] == 'RedHat' %}
    - name: /usr/lib/jvm/OpenJDK_GPLv2_and_Classpath_Exception.pdf
    {% elif grains['os_family'] == 'Debian' %}
    - name: /usr/lib/jvm/java-7-openjdk-amd64/OpenJDK_GPLv2_and_Classpath_Exception.pdf

    {% endif %}
    - source: salt://java/usr/lib/jvm/OpenJDK_GPLv2_and_Classpath_Exception.pdf

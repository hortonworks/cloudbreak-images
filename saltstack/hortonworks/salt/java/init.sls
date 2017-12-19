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
    - repl: DefaultEnvironment=JAVA_HOME={{ JAVA_HOME }}
{% endif %}

{% if grains['os_family'] == 'RedHat' %}

{% if grains['osmajorrelease'] | int == 7 %}
enable_redhat_rhui_repos:
  file.replace:
    - name: /etc/yum.repos.d/redhat-rhui.repo
    - pattern: '^enabled=[0,1]'
    - repl: 'enabled=1'
{% endif %}

install_openjdk:
  pkg.installed:
    - pkgs:
      - java-1.8.0-openjdk-headless
      - java-1.8.0-openjdk-devel
      - java-1.8.0-openjdk-javadoc
      - java-1.8.0-openjdk-src

{% elif grains['os_family'] == 'Debian' %}

install_openjdk:
 pkg.installed:
  - pkgs:
    - openjdk-8-jre-headless
    - openjdk-8-doc
    - openjdk-8-source
    - openjdk-8-jdk

{% endif %}

add_openjdk_gplv2:
  file.managed:
    {% if grains['os_family'] == 'RedHat' %}
    - name: /usr/lib/jvm/OpenJDK_GPLv2_and_Classpath_Exception.pdf
    {% elif grains['os_family'] == 'Debian' %}
    - name: /usr/lib/jvm/java-7-openjdk-amd64/OpenJDK_GPLv2_and_Classpath_Exception.pdf
    {% endif %}
    - source: salt://java/usr/lib/jvm/OpenJDK_GPLv2_and_Classpath_Exception.pdf
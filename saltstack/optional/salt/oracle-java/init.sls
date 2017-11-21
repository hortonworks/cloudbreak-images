
remove_openjdk:
  pkg.removed:
    - pkgs: 
    {% if grains['os_family'] == 'RedHat' %}
      - java-1.7.0-openjdk
      - java-1.7.0-openjdk-headless
      - java-1.7.0-openjdk-devel
      - java-1.7.0-openjdk-javadoc
      - java-1.7.0-openjdk-src
      - java-1.8.0-openjdk
      - java-1.8.0-openjdk-headless
      - java-1.8.0-openjdk-devel
      - java-1.8.0-openjdk-javadoc
      - java-1.8.0-openjdk-src
    {% elif grains['os_family'] == 'Debian' %}
      - openjdk-7-jre-headless
      - openjdk-7-doc
      - openjdk-7-source
      - openjdk-7-jdk
      - openjdk-8-jre-headless
      - openjdk-8-doc
      - openjdk-8-source
      - openjdk-8-jdk
    {% endif %}


{% if grains['os_family'] == 'RedHat' %}
download_oracle_jdk:
  {% set jdk_url = salt['environ.get']('ORACLE_JDK8_URL_RPM') %}
  {% set download_jdk_cmd = ['\'wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "',
                             jdk_url,
                             '" -O /tmp/oracle_jdk_install.rpm\'' ] %}
  cmd.run:
    - name: {{ download_jdk_cmd | join('') }}
    - unless: test -e /tmp/oracle_jdk_install.rpm

install_oracle_jdk:
  pkg.installed:
    - sources:
      - jdk1.8: /tmp/oracle_jdk_install.rpm


set_java_home_user:
  file.managed:
    - name: /etc/profile.d/java.sh
    - source: salt://{{ slspath }}/etc/profile.d/java.sh
    - mode: 755

{% if grains['init'] == 'systemd' %}
set_java_home_systemd:
  file.replace:
    - name: /etc/systemd/system.conf
    - pattern: \#*DefaultEnvironment=.*
    - repl: DefaultEnvironment=JAVA_HOME=/usr/java/default
{% endif %}

{% endif %}
{% if grains['os_family'] == 'RedHat' and grains['osmajorrelease'] | int == 7 %}
set_java_home_user:
  file.managed:
    - name: /etc/profile.d/java.sh
    - mode: 755
    - contents: |
        export JAVA_HOME={{ pillar['JAVA_HOME'] }}

set_java_home_systemd:
  file.replace:
    - name: /etc/systemd/system.conf
    - pattern: \#+DefaultEnvironment=.*
    - repl: DefaultEnvironment=JAVA_HOME={{ pillar['JAVA_HOME'] }}

download_oracle_jdk:
  cmd.run:
    - name: |
        wget -c -q --no-cookies --no-check-certificate \
             --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
             {{ salt['environ.get']('ORACLE_JDK8_URL_RPM') }} \
             -O /tmp/oracle_jdk_install.rpm

install_oracle_jdk:
  pkg.installed:
    - sources:
      - jdk1.8: /tmp/oracle_jdk_install.rpm
{% else %}
    {{ salt.test.exception("Doesn't support oracle-java state.") }}
{% endif %}
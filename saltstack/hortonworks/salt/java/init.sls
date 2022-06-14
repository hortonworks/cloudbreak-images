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
    - pattern: (DefaultEnvironment=.*)
    - repl: \1 JAVA_HOME={{ pillar['JAVA_HOME'] }}
{% endif %}

{% if grains['os_family'] == 'RedHat' %}
remove_openjdk17:
  pkg.removed:
    - name: java-1.7.0-openjdk
{% endif %}

{% if grains['os'] == 'RedHat' and grains['osmajorrelease'] | int == 7 %}
enable_redhat_rhui_repos:
  file.replace:
    - name: /etc/yum.repos.d/redhat-rhui.repo
    - pattern: '^enabled=[0,1]'
    - repl: 'enabled=1'
    - ignore_if_missing: True
{% endif %}

install_openjdk:
  pkg.installed:
    - pkgs: {{ pillar['openjdk_packages'] }}

set_openjdk_version_11:
  file.append:
    - name: /etc/profile.d/java.sh
    - text:
      - "sudo alternatives --set java java-11-openjdk.x86_64"
      - "sudo ln -sfn /etc/alternatives/java_sdk_11 /usr/lib/jvm/java"
      - "sudo mkdir -p /etc/alternatives/java_sdk_11/jre/lib/security"
      - "sudo ln -fs /etc/alternatives/java_sdk_11/conf/security/java.security /etc/alternatives/java_sdk_11/jre/lib/security/java.security"

{% if grains['os_family'] == 'Debian' %}
create_jvm_symlink:
  file.symlink:
    - name: /usr/lib/jvm/java
    - target: /usr/lib/jvm/java-{{ pillar['openjdk_version'] }}-openjdk-amd64
{% endif %}

add_openjdk_gplv2:
  file.managed:
    - name: {{ pillar['JAVA_HOME'] }}/OpenJDK_GPLv2_and_Classpath_Exception.pdf
    - source: salt://java/usr/lib/jvm/java/OpenJDK_GPLv2_and_Classpath_Exception.pdf
    - follow_symlinks: True
    - makedirs: True

run_java_sh:
  cmd.run:
    - name: . /etc/profile.d/java.sh

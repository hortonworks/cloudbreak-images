{% set cloud_provider = salt['environ.get']('CLOUD_PROVIDER') %}

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
    - pattern: \#*(DefaultEnvironment=.*)
    - repl: \1 JAVA_HOME={{ pillar['JAVA_HOME'] }}
{% endif %}

{% if grains['os_family'] == 'RedHat' %}
remove_openjdk1_7:
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

{% if grains['os'] == 'RedHat' and grains['osmajorrelease'] | int == 8 %}
{% if salt['environ.get']('IMAGE_BURNING_TYPE') == 'base' or salt['environ.get']('STACK_VERSION').split('.') | map('int') | list >= '7.2.18'.split('.') | map('int') | list %}
install_openjdk21:
  cmd.run:
    - name: |
        dnf install -y -v java-21-openjdk-headless java-21-openjdk-devel
{% endif %}
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

{% if cloud_provider == "AWS_GOV" %}
fips_disable_default_keystore:
  file.replace:
    - name: {{ pillar['JAVA_HOME'] }}/jre/lib/security/java.security
    - pattern: "^fips.keystore.type=PKCS11"
    - repl: "# fips.keystore.type=PKCS11"
    - append_if_not_found: False
{% endif %}

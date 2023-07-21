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

{% if pillar['OS'] == 'centos7' %}
openjdk17-centos7:
  archive.extracted:
    - name: /usr/lib/jvm/
    - source: https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz
    - source_hash: sha256=0022753d0cceecacdd3a795dd4cea2bd7ffdf9dc06e22ffd1be98411742fbb44
openjdk17-centos7-java-binary:
  alternatives.install:
    - name: java
    - link: /usr/bin/java
    - path: /usr/lib/jvm/jdk-17.0.2/bin/java
    - priority: 1
openjdk17-centos7-javac-binary:
  alternatives.install:
    - name: javac
    - link: /usr/bin/javac
    - path: /usr/lib/jvm/jdk-17.0.2/bin/javac
    - priority: 1
{% endif %}

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

{% if cloud_provider == "AWS_GOV" %}
fips_disable_default_keystore:
  file.replace:
    - name: {{ pillar['JAVA_HOME'] }}/jre/lib/security/java.security
    - pattern: "^fips.keystore.type=PKCS11"
    - repl: "# fips.keystore.type=PKCS11"
    - append_if_not_found: False
{% endif %}

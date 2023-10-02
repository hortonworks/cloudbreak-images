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

{# Temporarily removed - will adjust and re-enable once JDK21 gets a RedHat package repo
{% if salt['environ.get']('OS') == 'redhat8' %}
openjdk21-rhel8:
  archive.extracted:
    - name: /usr/lib/jvm/
    - source: https://download.java.net/java/GA/jdk21/fd2272bbf8e04c3dbaee13770090416c/35/GPL/openjdk-21_linux-x64_bin.tar.gz
    - source_hash: sha256=a30c454a9bef8f46d5f1bf3122830014a8fbe7ac03b5f8729bc3add4b92a1d0a
openjdk21-rhel8-java-binary:
  alternatives.install:
    - name: java
    - link: /usr/bin/java
    - path: /usr/lib/jvm/jdk-21/bin/java
    - priority: 1
openjdk21-rhel8-javac-binary:
  alternatives.install:
    - name: javac
    - link: /usr/bin/javac
    - path: /usr/lib/jvm/jdk-21/bin/javac
    - priority: 1
{% endif %}
#}

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

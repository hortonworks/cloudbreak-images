{# ### JDK installation rules:                                                    #}
{#  7.2.18 --- JDK 8 (full) + JDK 11 (full) + JDK 17 (minimal) + JDK 21 (minimal) #}
{#  7.3.1  --- JDK 8 (full) + JDK 17 (minimal) + JDK 21 (minimal)                 #}
{#  7.3.2+ --- JDK 17 (minimal) + JDK 21 (minimal)                                #}

{% if salt['environ.get']('OS') == 'redhat8' %}

{% if salt['environ.get']('STACK_VERSION').split('.') | map('int') | list < '7.3.2'.split('.') | map('int') | list %}

{% if salt['environ.get']('ARCHITECTURE') != 'arm64' %}
install_openjdk8:
  pkg.installed:
    - pkgs:
      - java-1.8.0-openjdk-headless
      - java-1.8.0-openjdk-devel
{% endif %}

{% if salt['environ.get']('STACK_VERSION').split('.') | map('int') | list < '7.3.1'.split('.') | map('int') | list %}
install_openjdk11:
  pkg.installed:
    - pkgs:
      - java-11-openjdk-headless
      - java-11-openjdk-devel
{% endif %}

{% endif %}

{% endif %}

install_openjdk17_and_21:
  cmd.run:
    - name: dnf install -y --setopt=install_weak_deps=False java-17-openjdk-headless java-17-openjdk-devel java-21-openjdk-headless java-21-openjdk-devel

{% if salt['environ.get']('DEFAULT_JAVA_MAJOR_VERSION') == '17' or salt['environ.get']('STACK_VERSION').split('.') | map('int') | list >= '7.3.2'.split('.') | map('int') | list %}
set_openjdk_version_17:
  cmd.run:
    - name: | 
        alternatives --set java java-17-openjdk.{{ grains['osarch'] }}
        ln -sfn /etc/alternatives/java_sdk_17 /usr/lib/jvm/java
        mkdir -p /etc/alternatives/java_sdk_17/jre/lib/security
        ln -sfn /etc/alternatives/java_sdk_17/conf/security/java.security /etc/alternatives/java_sdk_17/jre/lib/security/java.security
        ln -sfn /etc/pki/java/cacerts /etc/alternatives/java_sdk_17/jre/lib/security/cacerts
        mkdir -p /etc/alternatives/java_sdk_17/jre/lib/ext
{% endif %}
# Else: we're staying with JDK 8 as default for now...

add_openjdk_gplv2:
  file.managed:
    - name: {{ pillar['JAVA_HOME'] }}/OpenJDK_GPLv2_and_Classpath_Exception.pdf
    - source: salt://java/usr/lib/jvm/java/OpenJDK_GPLv2_and_Classpath_Exception.pdf
    - follow_symlinks: True
    - makedirs: True

{% if salt['environ.get']('CLOUD_PROVIDER') == "AWS_GOV" %}
fips_disable_default_keystore:
  file.replace:
    - name: {{ pillar['JAVA_HOME'] }}/jre/lib/security/java.security
    - pattern: "^fips.keystore.type=PKCS11"
    - repl: "# fips.keystore.type=PKCS11"
    - append_if_not_found: False
{% endif %}

set_java_home_user:
  file.managed:
    - name: /etc/profile.d/java.sh
    - mode: 755
    - contents: |
        export JAVA_HOME={{ pillar['JAVA_HOME'] }}
        export OPENSEARCH_JAVA_HOME=/usr/lib/jvm/java-21-openjdk

set_java_home_systemd:
  file.replace:
    - name: /etc/systemd/system.conf
    - pattern: \#*(DefaultEnvironment=.*)
    - repl: \1 JAVA_HOME={{ pillar['JAVA_HOME'] }} OPENSEARCH_JAVA_HOME=/usr/lib/jvm/java-21-openjdk

run_java_sh:
  cmd.run:
    - name: . /etc/profile.d/java.sh
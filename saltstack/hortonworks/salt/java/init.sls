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
{% endif %}

install_openjdk:
  pkg.installed:
    - pkgs: {{ pillar['openjdk_packages'] }}

{% if grains['os_family'] == 'Debian' %}
create_jvm_symlink:
  file.symlink:
    - name: /usr/lib/jvm/java
    - target: /usr/lib/jvm/java-{{ pillar['openjdk_version'] }}-openjdk-amd64
{% endif %}

{% if (not salt['environ.get']('OPTIONAL_STATES', '') == 'oracle-java' 
       and salt['environ.get']('JAVA_VERSION') is defined
       and salt['environ.get']('JAVA_VERSION') == '11') %}

# make folder structure backward compatibility with java-1.8
# used when reaching "java.security" file, see the diff:
# /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.252.b09-2.el7_8.x86_64/jre/lib/security/java.security
# /usr/lib/jvm/java-11-openjdk-11.0.7.10-4.el7_8.x86_64/conf/security/java.security

create_java11_java8_folder_compatibility_print:
  cmd.run:
    - name: echo "Build Java11->Java8 folder-structure compatibility..."

create_java11_java8_folder_compatibility_dir:
  file.directory:
    - name:  /usr/lib/jvm/java/jre
    - mode:  755
    - follow_symlinks: True
    - makedirs: True

create_java11_java8_folder_compatibility_symlink:
  file.symlink:
    - name: /usr/lib/jvm/java/jre/lib
    - target: /usr/lib/jvm/java/conf
    - follow_symlinks: True

create_java11_java8_cacerts_symlink:
  file.symlink:
    - name: /usr/lib/jvm/java/jre/lib/security/cacerts
    - target: /etc/pki/java/cacerts
    - follow_symlinks: True

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

{% if salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' %}
update-packages:
  cmd.run:
    - name: dnf update -y --releasever=8.8 --nobest
{% elif pillar['subtype'] != 'Docker' %}
update-packages:
  pkg.uptodate:
    - refresh: True
{% endif %}

# Apparently "yum update" on CentOS 7 puts these back in...
{% if pillar['OS'] == 'centos7' %}
remove_dead_repos_again:
  cmd.run:
    - name: sudo rm -rf /etc/yum.repos.d/CentOS*.repo
{% endif %}

{% if pillar['OS'] == 'redhat8' %}
remove_unused_rhel8_packages:
  pkg.removed:
    - pkgs:
      # Apparently we have this on Azure RHEL8 images by default and it causes problems...
      - sssd-krb5
      # Not used but adds warnings to register system
      - insights-client
      # Enforces automatic updates that can end up destabilizing the instance
      - dnf-automatic
{% endif %}


packages_install:
  pkg.installed:
    - refresh: False
    - pkgs:
      - wget
      - tar
      - unzip
      - curl
      - net-tools
      - git
  {% if pillar['OS'] != 'redhat8' %}  
      - ntp
      - deltarpm
  {% endif %}
      - iptables
      - ruby
  {% if grains['os_family'] == 'RedHat' %}
      - snappy
      - cloud-utils-growpart
    {% if pillar['OS'] != 'redhat7' and pillar['OS'] != 'redhat8' %}
      - snappy-devel
    {% endif %}
      - bind-utils
    {% if grains['osmajorrelease'] | int == 7 %}
      - iptables-services
    {% endif %}
    {% if pillar['OS'] == 'redhat8' and pillar['subtype'] == 'Docker' and salt['environ.get']('RHEL_VERSION') == '8.8' %}
      - NetworkManager
    {% endif %}
    {% if pillar['OS'] == 'redhat8' %}
      - sos
      {% if pillar['subtype'] != 'Docker' %}
      - setools-console
      {% endif %}
    {% endif %}
  {% endif %}
  {% if salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' %}
      - cryptsetup
  {% endif %}
      - nvme-cli
      - openssl
      - autossh
      - ipa-client
      - openldap
      - openldap-clients
      - openldap-devel
      - nmap-ncat
      - tcpdump
      - sysstat
      - goaccess
      - httpd-tools
    {% if salt['environ.get']('CLOUD_PROVIDER') != 'AWS_GOV' and salt['environ.get']('OS') != 'centos7' and pillar['subtype'] != 'Docker' %}
      - iscsi-initiator-utils
    {% endif %}

{% if pillar['subtype'] != 'Docker' %}

{% if salt['environ.get']('CLOUD_PROVIDER') == '' %}
missing_cloudprovider:
  cmd.run:
    - name: echo 'CLOUD_PROVIDER environment variable is missing!' && exit 1
{% elif salt['environ.get']('CLOUD_PROVIDER').startswith('AWS') %}

download_awscli:
  cmd.run:
    - name: wget https://awscli.amazonaws.com/awscli-exe-linux-{{ grains['osarch'] }}.zip -q -O /tmp/awscli.zip && unzip -q -d /tmp/awscli/ /tmp/awscli.zip && rm -f /tmp/awscli.zip

install_awscli:
  cmd.run:
    - name: /tmp/awscli/aws/install -b /usr/bin

remove_awscli_extract:
  cmd.run:
    - name: rm -rf /tmp/awscli
{% elif salt['environ.get']('CLOUD_PROVIDER') == 'Azure' %}

download_azcopy:
  archive.extracted:
    - name: /tmp/azcopy
    - source:  https://aka.ms/downloadazcopy-v10-linux
    - archive_format: tar
    - skip_verify: true
    - options: "--strip 1"
    - enforce_toplevel: false

/usr/local/bin/azcopy:
  file.managed:
    - source: /tmp/azcopy/azcopy
    - user: root
    - group: root
    - mode: 755

remove_azcopy_extract:
  file.directory:
    - name: /tmp/azcopy
    - clean: True
{% endif %}

# Security patches for RHEL 8.8 + 7.2.17 / 7.2.18 / FreeIPA / Base
# They are actually being pulled from a 8.10 repository, but we'll need these patches to tackle Azure's security checks.

{% if pillar['OS'] == 'redhat8' and salt['environ.get']('RHEL_VERSION') == '8.8' %}
{% if pillar['CUSTOM_IMAGE_TYPE'] == 'freeipa' or salt['environ.get']('STACK_VERSION').split('.') | map('int') | list <= '7.2.18'.split('.') | map('int') | list %}

rhel88_security_add_repo:
  file.managed:
    - name: /etc/yum.repos.d/rhel8_cldr_mirrors.repo
    - source: https://mirror.infra.cloudera.com/repos/rhel/server/8/8/rhel8_cldr_mirrors.repo
    - skip_verify: True

{% if salt['environ.get']('ARCHITECTURE') == 'arm64' %} # ubi-8-supplementary-cldr and ubi-8-codeready-builder-cldr are not yet available for arm64
rhel88_security_remove_unavailable_repos:
  cmd.run:
    - name: sed -i '16,$ d' /etc/yum.repos.d/rhel8_cldr_mirrors.repo
{% endif %}

rhel88_security_apply_patches:
  cmd.run:
    - name: sudo dnf update-minimal -y --security --nobest

rhel88_security_remove_repo:
  file.absent:
    - name: /etc/yum.repos.d/rhel8_cldr_mirrors.repo

{% endif %}
{% endif %}

{% endif %}
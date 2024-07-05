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
    {% if pillar['OS'] == 'redhat8' and pillar['subtype'] == 'Docker' %}
      - NetworkManager
    {% endif %}
    {% if pillar['OS'] == 'redhat8' %}
      - sos
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

{% if pillar['subtype'] != 'Docker' %}

{% if salt['environ.get']('CLOUD_PROVIDER') == '' %}
missing_cloudprovider:
  cmd.run:
    - name: echo 'CLOUD_PROVIDER environment variable is missing!' && exit 1
{% elif salt['environ.get']('CLOUD_PROVIDER').startswith('AWS') %}

download_awscli:
  cmd.run:
    - name: wget https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -q -O /tmp/awscli.zip && unzip -q -d /tmp/awscli/ /tmp/awscli.zip && rm -f /tmp/awscli.zip

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

{% endif %}
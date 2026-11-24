# CB-30236: We need this distro upgrade, because we only have a 9.5 base image for Azure
{% if salt['environ.get']('CLOUD_PROVIDER') == 'Azure' and salt['environ.get']('RHEL_VERSION') == '9.6' %}
distro-upgrade:
  cmd.run:
    - name: |
        dnf clean all
        dnf upgrade -y --releasever=9.6
{% elif salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' and pillar['OS'] == 'redhat8' %}
update-packages:
  cmd.run:
    - name: dnf update -y --releasever=8.8 --nobest
{% elif pillar['subtype'] != 'Docker' %}
update-packages:
  pkg.uptodate:
    - refresh: True
{% endif %}

remove_unused_rhel_packages:
  pkg.removed:
    - pkgs:
      # Apparently we have this on Azure RHEL8 images by default and it causes problems...
      - sssd-krb5
      # Not used but adds warnings to register system
      - insights-client
      # Enforces automatic updates that can end up destabilizing the instance
      - dnf-automatic

packages_install:
  pkg.installed:
    - refresh: False
    - pkgs:
  {% if pillar['OS'] == 'redhat9' or pillar['OS'] == 'redhat10' %}
      # chkconfig is legacy, but needed by CM and it creates /etc/init.d which is also needed by /saltstack/base/salt/performance/thp.sls
      # on RHEL 8 and CentOS 7 it is installed by default.
      - chkconfig
      # Not installed starting with RHEL 9, but still needed for backward compatibility
      - krb5-devel
  {% endif %}
      - wget
      - tar
      - unzip
      - curl
      - net-tools
      - git
  {% if pillar['OS'] == 'redhat8' %}
      - iptables
  {% endif %}
      - ruby
      - snappy
      - cloud-utils-growpart
      - bind-utils
  {% if pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' or pillar['OS'] == 'redhat10' %}
      - sos
      {% if pillar['subtype'] != 'Docker' %}
      - setools-console
      {% endif %}
  {% endif %}
  {% if salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' or salt['environ.get']('CLOUD_PROVIDER') == 'AWS' %}
      - cryptsetup
  {% endif %}
      - nvme-cli
  {% if salt['environ.get']('CLOUD_PROVIDER') == 'Openstack' %}
      - glibc-langpack-en
  {% endif %}
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
    {% if salt['environ.get']('CLOUD_PROVIDER') != 'AWS_GOV' and pillar['subtype'] != 'Docker' %}
      - iscsi-initiator-utils
    {% endif %}
      - rsync

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

{% endif %}
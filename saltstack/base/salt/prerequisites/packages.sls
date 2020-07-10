{% if pillar['subtype'] != 'Docker' %}
update-packages:
  pkg.uptodate:
    - refresh: True
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
  {% if grains['os_family'] == 'Suse' %}
      - git-core
      - man
      - libxml2-tools
  {% else %}
      - git
      - tmux
  {% endif %}
  {% if pillar['OS'] in ('ubuntu18') or pillar['OS'] in ('centos8') %}
      - chrony
  {% else %}
      - ntp
  {% endif %}
  {% if grains['os'] != 'Amazon' %}
      - bash-completion
  {% endif %}
      - iptables
      - mc
      - ruby
  {% if grains['os_family'] == 'RedHat' %}
      - snappy
      - cloud-utils-growpart
    {% if pillar['OS'] != 'redhat7' and pillar['OS'] != 'centos8' %}
      - snappy-devel
    {% endif %}
      - bind-utils
    {% if grains['osmajorrelease'] | int == 7 %}
      - iptables-services
    {% endif %}
  {% elif grains['os_family'] == 'Debian' %}
      - iptables-persistent
      - dnsutils
  {% endif %}
      {% if grains['os_family'] == 'RedHat' and grains['osmajorrelease'] | int != 8  %}
      - deltarpm
      {% endif %}
      - nvme-cli
      - openssl
  {% if pillar['OS'] in ('centos7', 'centos6', 'redhat7') %}
      - vim-common
  {% else %}
      - vim
  {% endif %}
  {% if  pillar['OS'] != 'centos8' and grains['os_family'] != 'Suse' and grains['osmajorrelease'] |int != 12 %}
      - autossh
  {% endif %}
     {% if pillar['OS'] != 'centos8' and grains['os_family'] != 'Suse'%}
      - awscli
      {% endif %}
    {% if pillar['OS'] in ('ubuntu16', 'ubuntu18') %}
      - unattended-upgrades
      - update-notifier-common
      - freeipa-client
      - slapd
      - ldap-utils
      - libnss-ldap
      - libpam-ldap
      - ldap-utils
    {% elif pillar['OS'] in ('sles12') %}
      - openldap2
      - openldap2-client
    {% elif pillar['OS'] in ('debian9') %}
      - unattended-upgrades
      - slapd
      - libnss-ldap
      - libpam-ldap
      - ldap-utils
    {% else %}
      - ipa-client
      - openldap
      - openldap-clients
    {% endif %}

{% if pillar['subtype'] != 'Docker' %}

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

{% if grains['os_family'] == 'Suse' %}
remove_snappy:
  pkg.removed:
    - pkgs:
      - libsnappy1
      - snappy-devel

install_hostname:
  cmd.run:
    - name: zypper in --replacefiles -y hostname
{% endif %}

{% if grains['os'] == 'Amazon' %}
install_bash_completion:
  pkg.installed:
    - refresh: False
    - fromrepo: epel
    - pkgs:
      - bash-completion
{% endif %}

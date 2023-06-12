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
  {% if pillar['OS'] != 'redhat8' %}  
      - ntp
      - deltarpm
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
    {% if pillar['OS'] != 'redhat7' and pillar['OS'] != 'redhat8' %}
      - snappy-devel
    {% endif %}
    {% if grains['osmajorrelease'] | int == 7 %}
      - iptables-services
    {% endif %}
  {% elif grains['os_family'] == 'Debian' %}
      - iptables-persistent
      - dnsutils
  {% endif %}
      - nvme-cli
      - openssl
  {% if pillar['OS'] in ('centos7', 'redhat7', 'redhat8') %}
      - vim-common
  {% else %}
      - vim
  {% endif %}
  {% if grains['os_family'] != 'Suse' and grains['osmajorrelease'] |int != 12 %}
      - autossh
  {% endif %}
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


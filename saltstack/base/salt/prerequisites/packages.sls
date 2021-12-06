{% if pillar['subtype'] != 'Docker' %}

# Added this to see in the logs if the old packages are still there 
# if not anymore, then the next 4 entries including this one can be removed
check-sssd:
  cmd.run:
    - name: yum list installed | grep -i libsss

# Clean up old dependencies (and old SSSD, just in case)
remove-old-libsss_idmap:
  pkg.removed:
    - name: libsss_idmap
    - version: 1.16.2-13.el7_6.8
remove-old-libsss_nss_idmap:
  pkg.removed:
    - name: libsss_nss_idmap
    - version: 1.16.2-13.el7_6.8
remove-old-sssd:
  pkg.removed:
    - name: sssd

# We need this yum plugin to lock the SSSD version in place
install-yum-versionlock:
  cmd.run:
    - name: yum install yum-plugin-versionlock

# Force install the correct version of SSSD (this installs 1.16.5-10.el7_9.10) 
# before the update
install-sssd:
  pkg.installed:
    - refresh: True
    - allow_updates: True
    - hold: False
    - name: sssd

# Let's check the versions again, just in case - we need to see 1.16.5-10.el7_9.10
# as version for those libs
check-sssd-again:
  cmd.run:
    - name: yum list installed | grep -i libsss

# Let's make sure that 1.16.5-10.el7_9.10 version of these libs won't get updated 
# to 1.16.5-10.el7_9.11
lock-sssd-libs-1:
  cmd.run:
    - name: yum versionlock libsss_*

# libipa_hbac is a dependency installed during installation of SSSD, but for some reason
# it also gets bumped one version and so, fails to satisfy the requirements of SSSD.
# Because of this, we need to lock it too.
lock-sssd-libs-2:
  cmd.run:
    - name: yum versionlock libipa_hbac

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
      - ntp
  {% if grains['os'] != 'Amazon' %}
      - bash-completion
  {% endif %}
      - iptables
      - mc
      - ruby
  {% if grains['os_family'] == 'RedHat' %}
      - snappy
      - cloud-utils-growpart
    {% if pillar['OS'] != 'redhat7' %}
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
      - deltarpm
      - nvme-cli
      - openssl
  {% if pillar['OS'] in ('centos7', 'redhat7') %}
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
      - telnet
      - tcpdump
      - sysstat
      - goaccess

{% if pillar['subtype'] != 'Docker' %}

download_awscli:
  archive.extracted:
    - name: /tmp/awscli
    - source: https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
    - archive_format: zip
    - skip_verify: true
    - enforce_toplevel: false

install_awscli:
  cmd.run:
    - name: /tmp/awscli/aws/install -b /usr/bin

remove_awscli_extract:
  file.directory:
    - name: /tmp/awscli
    - clean: True

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


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
  {% if pillar['OS'] in ('centos7', 'centos6', 'redhat7') %}
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

{% if grains['os_family'] == 'RedHat' %}
install-psycopg2:
  cmd.run:
    - name: pip install psycopg2==2.7.5 --ignore-installed
{% endif %}

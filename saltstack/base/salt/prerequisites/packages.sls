pkg.upgrade:
  module.run:
    - refresh: True

packages_install:
  pkg.installed:
    - refresh: False
    - pkgs:
      - wget
      - net-tools
      - tar
      - unzip
      - curl
      - git
      - ntp
      - tmux
    {% if grains['os'] != 'Amazon' %}
      - bash-completion
    {% endif %}
      - iptables
      - mc
      - ruby
    {% if grains['os_family'] == 'RedHat' %}
      - snappy
      - snappy-devel
      - bind-utils
    {% if grains['osmajorrelease'] | int == 7 %}
      - iptables-services
    {% endif %}
    {% elif grains['os_family'] == 'Debian' %}
      - iptables-persistent
      - dnsutils
    {% endif %}

{% if grains['os'] == 'Amazon' %}
install_bash_completion:
  pkg.installed:
    - refresh: False
    - fromrepo: epel
    - pkgs:
      - bash-completion
{% endif %}

install_jq:
  file.managed:
    - name: /usr/bin/jq
    - source: http://stedolan.github.io/jq/download/linux64/jq
    - skip_verify: True
    - mode: 755

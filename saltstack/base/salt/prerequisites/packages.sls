{% if pillar['subtype'] != 'Docker' %}
update-packages:
  pkg.uptodate:
    - refresh: True
{% endif %}

packages_install:
    test.succeed_without_changes:
          - pkg.installed:
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


{% if grains['os_family'] == 'Debian' %}
{% if grains['osmajorrelease'] == 7 %}
install_wheezy_backports_repository:
  pkgrepo.managed:
  - humanname: Wheezy backports components repo
  - name: deb http://ftp.debian.org/debian wheezy-backports main contrib non-free
  - dist: wheezy-backports
  - file: /etc/apt/sources.list.d/wheezy_backports.list
  - require_in:
  - pkg: install_cloud-init_packages
  - gpgcheck: 1
  - unless: ls /etc/waagent.conf
{% endif %}
{% endif %}


install_cloud-init_packages:
  pkg.installed:
    - pkgs:
      - cloud-init
    {% if grains['os_family'] == 'Debian' %}
    {% if grains['osmajorrelease'] == 7 %}
    - fromrepo: wheezy-backports
    {% endif %}
    {% endif %}
    - unless: ls /etc/waagent.conf


preserve_hostname_false:
  file.replace:
    - name: /etc/cloud/cloud.cfg
    - pattern: "^preserve_hostname.*"
    - repl: "preserve_hostname: true"
    - append_if_not_found: True
    - unless: ls /etc/waagent.conf

create_cloudbreak_files:
  file.managed:
    - user: root
    - group: root
    - name: /etc/cloud/cloud.cfg.d/50_cloudbreak.cfg
    - source: salt://{{ slspath }}/etc/cloud/cloud.cfg.d/50_cloudbreak.cfg
    - unless: ls /etc/waagent.conf

{% if grains['init'] == 'systemd' %}
create_cloud-init_service_files:
  file.managed:
    - user: root
    - group: root
    - name: /etc/systemd/system/cloud-init.service
    - source: salt://{{ slspath }}/etc/systemd/system/cloud-init.service
    - unless: ls /etc/waagent.conf
{% endif %}
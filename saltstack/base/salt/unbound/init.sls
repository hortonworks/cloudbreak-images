{% if grains['os'] == 'Amazon' %}
create_centos_os_repo:
  pkgrepo.managed:
    - name: centos-os
    - enabled: True
    - humanname: "CentOS-6 - OS"
    - mirrorlist: http://mirrorlist.centos.org/?release=6&arch=$basearch&repo=os&infra=$infra
    - gpgcheck: 1
    - gpgkey: "http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-6"
{% endif %}

{% if grains['os'] == 'Amazon' %}
install_pyhton26:
  pkg.installed:
    - pkgs:
      - compat-libevent
      - libpcap
      - python26
      - python26-libs
{% endif %}

install_unbound_server:
  pkg.installed:
    {% if grains['os'] == 'Amazon' %}
    - fromrepo: centos-os
    {% elif grains['os_family'] == 'Debian' and  grains['osmajorrelease'] | int == 7 %}
    - fromrepo: wheezy-backports
    {% endif %}
    - pkgs:
      {% if grains['os_family'] == 'RedHat' %}
      - ldns
      - unbound-libs
      - unbound
      {% elif grains['os_family'] == 'Debian' %}
      - unbound-anchor
      - unbound
      {% endif %}

{% if grains['os'] == 'Amazon' %}
disable_centos_os_repo:
  pkgrepo.managed:
    - name: centos-os
    - enabled: False
{% endif %}

config_unbound_server:
  file.managed:
    - user: root
    - group: root
    - name: /etc/unbound/unbound.conf
    - source: salt://{{ slspath }}/etc/unbound/unbound.conf
    - mode: 644

{% if grains['os_family'] == 'Debian' %}

create_unbound_local_d:
  file.directory:
    - name: /etc/unbound/local.d/

create_unbound_conf_d:
  file.directory:
    - name: /etc/unbound/conf.d/

config_example_unbound_local_d:
  file.managed:
    - user: root
    - group: root
    - name: /etc/unbound/local.d/block.conf.example
    - source: salt://{{ slspath }}/etc/unbound/local.d/block.conf.example
    - mode: 644

config_example_unbound_conf_d:
  file.managed:
    - user: root
    - group: root
    - name: /etc/unbound/conf.d/zone.conf.example
    - source: salt://{{ slspath }}/etc/unbound/conf.d/zone.conf.example
    - mode: 644
{% endif %}

{% if grains['init'] == 'systemd' %}

unbound_service:
  file.managed:
    - name: /etc/systemd/system/unbound.service
    - source: salt://{{ slspath }}/etc/systemd/system/unbound.service

{% elif grains['init'] == 'upstart' %}

config_unbound_upstart:
  file.managed:
    - name: /etc/init/unbound.conf
    - source:
      - salt://{{ slspath }}/etc/init/unbound.conf
    - mode: 644

{% endif %}

enable_unbound:
  service.running:
    - name: unbound
    - enable: True

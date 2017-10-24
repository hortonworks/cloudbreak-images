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
    {% endif %}
    - pkgs:
      {% if grains['os_family'] == 'RedHat' %}
      - ldns
      - unbound-libs
      - unbound
      {% elif grains['os_family'] == 'Debian' %}
      - libldns1
      - libpython2.7
      - libunbound2
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

{% if grains['init'] == 'systemd' %}

unbound_service:
  file.managed:
    - name: /etc/systemd/system/unbound.service
    - source: salt://{{ slspath }}/etc/systemd/system/unbound.service

{% endif %}

{% if grains['init'] == 'upstart' %}

config_unbound_upstart:
  file.managed:
    - name: /etc/init/unbound.conf
    - source:
      - salt://{{ slspath }}/etc/init/unbound.conf
    - mode: 644

{% endif %}

enable_unbound:
  service.enabled:
    - name: unbound
{% if grains['os'] == 'Amazon' %}
create_centos_extra_repo:
  pkgrepo.managed:
    - name: centos-extras
    - humanname: "CentOS-6 - Extras"
    - mirrorlist: http://mirrorlist.centos.org/?release=6&arch=$basearch&repo=extras&infra=$infra
    - gpgcheck: 1
    - gpgkey: "http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-6"
{% endif %}

install_unbound_server:
  pkg.installed:
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

config_unbound_server:
  file.managed:
    - user: root
    - group: root
    - name: /etc/unbound/unbound.conf
    - source: salt://{{ slspath }}/etc/unbound/unbound.conf
    - mode: 644

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
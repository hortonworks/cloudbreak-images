install_unbound_server:
  pkg.installed:
    - pkgs:
      - ldns
      - unbound-libs
      - unbound

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

enable_unbound:
  service.running:
    - name: unbound
    - enable: True

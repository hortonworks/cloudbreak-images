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

# This is needed because of CB-30897
{% if salt['environ.get']('OS') == 'redhat9' and salt['environ.get']('CLOUD_PROVIDER') == 'GCP' %}
config_unbound_for_rhel9_on_gcp:
  cmd.run:
    - name: rm /etc/unbound/conf.d/unbound-local-root.conf
{% endif %}

{% if grains['init'] == 'systemd' %}
unbound_service:
  file.managed:
    - name: /etc/systemd/system/unbound.service
    - source: salt://{{ slspath }}/etc/systemd/system/unbound.service
{% endif %}

enable_unbound:
{% if pillar['subtype'] != 'Docker' %}
  service.running:
    - name: unbound
    - enable: True
{% else %}
  cmd.run:
    - name: systemctl enable --now unbound
{% endif %}

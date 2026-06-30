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

# CB-30897 / CB-33549: RHEL 9 unbound ships unbound-local-root.conf which activates an
# auth-zone "." (local root copy). auth-zone outranks our forward-zones, so the node-local
# caching forwarder answers root queries locally instead of forwarding to the VPC resolver,
# breaking resolution of internal-only TLDs. Affects all cloud providers on RHEL 9, not just GCP.
{% if salt['environ.get']('OS') == 'redhat9' %}
config_unbound_for_rhel9:
  file.absent:
    - name: /etc/unbound/conf.d/unbound-local-root.conf
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

{% if grains['os'] == 'Debian' %}
install_resolvconf_package:
  pkg.installed:
    - pkgs:
      - resolvconf
{% endif %}

{% if grains['init'] == 'systemd' %}
set_resolvconf_unbound:
  file.managed:
    - name: /etc/resolvconf/update.d/unbound
    - source: salt://{{ slspath }}/etc/resolvconf/update.d/unbound
    - skip_verify: True
    - mode: 755

resolvconf_service:
  file.managed:
    - name: /etc/systemd/system/resolvconf.service
    - source: salt://{{ slspath }}/etc/systemd/system/resolvconf.service
{% endif %}

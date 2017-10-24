/etc/init.d/disable-thp:
  file.managed:
    - source: salt://{{ slspath }}/etc/init.d/disable-thp
    - mode: 755

{% if grains['init'] == 'systemd' %}

disable_thp_service:
  file.managed:
    - name: /etc/systemd/system/disable-thp.service
    - source: salt://{{ slspath }}/etc/systemd/system/disable-thp.service

{% endif %}

ensure_disable_thp_enabled:
  service.enabled:
    - name: disable-thp
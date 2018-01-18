{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
/etc/init.d/disable-thp:
  file.managed:
    - source:
      - salt://{{ slspath }}/etc/init.d/disable-thp.{{ grains['os'] | lower }}
      - salt://{{ slspath }}/etc/init.d/disable-thp
    - mode: 755
{% elif grains['init'] == 'systemd' %}

disable_thp_service:
  file.managed:
    - name: /etc/systemd/system/disable-thp.service
    - source:
      - salt://{{ slspath }}/etc/systemd/system/disable-thp.service

{% endif %}

ensure_disable_thp_enabled:
  service.enabled:
    - name: disable-thp
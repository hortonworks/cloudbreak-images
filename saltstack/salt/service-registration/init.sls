download_service_registration:
  file.managed:
    - name: /tmp/service-registration.tgz
    - source: https://github.com/hortonworks/service-registration/releases/download/v0.8/service-registration_0.8_Linux_x86_64.tgz
    - skip_verify: True
    - unless: ls -1 /tmp/service-registration.tgz

unpack_service_registration:
  cmd.run:
    - name: cd /tmp && tar -zxf service-registration.tgz && chmod +x service-registration && mv service-registration /usr/local/bin/
    - unless: ls -1 /usr/local/bin/service-registration

{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
/etc/init.d/service-registration:
  file.managed:
    - makedirs: True
    - mode: 755
    - source:
      - salt://{{ slspath }}/etc/init.d/service-registration.{{ grains['os_family'] | lower }}
      - salt://{{ slspath }}/etc/init.d/service-registration
{% elif grains['init'] == 'systemd' %}
    service_registration_service:
      file.managed:
        - name: /etc/systemd/system/service-registration.service
        - source: salt://{{ slspath }}/etc/systemd/system/service-registration.service
{% endif %}

ensure_service_registration_enabled:
  service.enabled:
    - name: service-registration

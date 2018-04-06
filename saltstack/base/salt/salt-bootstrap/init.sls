install_saltbootstrap:
  archive.extracted:
    - name: /usr/sbin/
    - source: https://github.com/hortonworks/salt-bootstrap/releases/download/v0.12.3/salt-bootstrap_0.12.3_Linux_x86_64.tgz
    - archive_format: tar
    - enforce_toplevel: false
    - skip_verify: True
    - if_missing: /usr/sbin/salt-bootstrap

create_saltbootstrap_service_files:
  file.managed:
    - user: root
    - group: root
{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
    - name: /etc/init.d/salt-bootstrap
    - source:
      - salt://{{ slspath }}/etc/init.d/salt-bootstrap.{{ grains['os_family'] | lower }}
      - salt://{{ slspath }}/etc/init.d/salt-bootstrap
    - mode: 755
{% elif grains['init'] == 'systemd' %}
    - name: /etc/systemd/system/salt-bootstrap.service
    - template: jinja
    - source: salt://{{ slspath }}/etc/systemd/system/salt-bootstrap.service
{% endif %}

salt-bootstrap:
  service.running:
    - enable: True
    - require:
      - install_saltbootstrap
      - create_saltbootstrap_service_files

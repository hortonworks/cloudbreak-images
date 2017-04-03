install_saltbootstrap:
  archive.extracted:
    - name: /usr/sbin/
    - source: https://github.com/hortonworks/salt-bootstrap/releases/download/v0.11.0/salt-bootstrap_0.11.0_Linux_x86_64.tgz
    - archive_format: tar
    - source_hash: md5=bf18fb354d9799485f94a8ec6a867c7d
    - enforce_toplevel: false
    - if_missing: /usr/sbin/salt-bootstrap

create_saltbootstrap_service_files:
  file.managed:
    - user: root
    - group: root
{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
    - name: /etc/init.d/salt-bootstrap
    - source:
      - salt://{{ slspath }}/etc/init.d/salt-bootstrap.{{ grains['os'] | lower }}
      -  salt://{{ slspath }}/etc/init.d/salt-bootstrap
    - mode: 755
{% elif grains['init'] == 'systemd' %}
    - name: /etc/systemd/system/salt-bootstrap.service
    - source: salt://{{ slspath }}/etc/systemd/system/salt-bootstrap.service
{% endif %}

salt-bootstrap:
  service.running:
    - enable: True
    - require:
      - install_saltbootstrap
      - create_saltbootstrap_service_files

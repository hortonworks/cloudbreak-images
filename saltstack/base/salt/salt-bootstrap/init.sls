{% set version = salt['environ.get']('SALTBOOT_VERSION') %}
{% set url = 'https://github.com/hortonworks/salt-bootstrap/releases/download/v' ~ version ~ '/salt-bootstrap_' ~ version ~ '_Linux_' ~ salt['environ.get']('ARCHITECTURE') ~ '.tgz' %}

install_saltbootstrap:
  archive.extracted:
    - name: /usr/sbin/
    - source: {{ url }}
    - source_hash: {{ url }}.sha256
    - archive_format: tar
    - enforce_toplevel: false
    - user: root
    - group: root
    - skip_verify: True
    - if_missing: /usr/sbin/salt-bootstrap

ensure_saltbootstrap_executable:
  file.managed:
    - name: /usr/sbin/salt-bootstrap
    - user: root
    - group: root
    - mode: 755

saltbootstrap_hardcoded_package:
  file.append:
    - name: /tmp/hardcoded-packages.csv
    - text: |
        salt-bootstrap;{{ version }};Hardcoded;Apache License 2.0;Cloudera Inc.;{{ url }};Tool for bootstrapping VMs launched by Cloudbreak.

create_saltbootstrap_service_files:
  file.managed:
    - user: root
    - group: root
    - name: /etc/systemd/system/salt-bootstrap.service
    - template: jinja
    - source: salt://{{ slspath }}/etc/systemd/system/salt-bootstrap.service

salt-bootstrap:
{% if pillar['subtype'] != 'Docker' %}
  service.running:
    - enable: True
{% else %}
  cmd.run:
    - name: systemctl enable salt-bootstrap
{% endif %}
    - require:
      - install_saltbootstrap
      - create_saltbootstrap_service_files

install_saltbootstrap:
  archive.extracted:
    - name: /usr/sbin/
    - source: https://github.com/hortonworks/salt-bootstrap/releases/download/v0.13.6/salt-bootstrap_0.13.6_Linux_x86_64.tgz
    - source_hash: sha256=ebb0a9f978c2a112622420359f6eb8afda0d36c8eff3ebb54c7d6e49ba823240
    - archive_format: tar
    - enforce_toplevel: false
    - user: root
    - group: root
    - skip_verify: True
    - if_missing: /usr/sbin/salt-bootstrap

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

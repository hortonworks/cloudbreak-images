{% set version = '0.1.4' %}
{% set url = 'https://github.infra.cloudera.com/cloudbreak/certm/releases/download/v' ~ version ~ '/certm_' ~ version ~ '_Linux_' ~ salt['environ.get']('ARCHITECTURE') ~ '.tgz' %}

install_certm:
  archive.extracted:
    - name: /sbin/
    - source: {{ url }}
    - source_hash: {{ url }}.sha256
    - archive_format: tar
    - enforce_toplevel: false
    - skip_verify: True
    - if_missing: /sbin/certm
    - user: root
    - group: root

certm_hardcoded_package:
  file.append:
    - name: /tmp/hardcoded-packages.csv
    - text: |
        certm;{{ version }};Hardcoded;UNKNOWN;Cloudera Inc.;{{ url }};CertM is a simple tool to generate TLS certificates and keys.

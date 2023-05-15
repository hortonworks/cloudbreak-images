{% set version = '1.3.1' %}
{% set path = 'https://github.com/prometheus/node_exporter/releases/download/v' ~ version %}
{% set architecture = 'arm64' if salt['environ.get']('ARCHITECTURE') == 'arm64' else 'amd64' %}
{% set url = path ~ '/node_exporter-' ~ version ~ '.linux-' ~ architecture ~ '.tar.gz' %}

/opt/node_exporter:
  file.directory:
    - name: /opt/node_exporter
    - user: root
    - group: root
    - mode: 700

install_node_exporter:
  archive.extracted:
    - name: /opt/node_exporter/
    - source: {{ url }}
    - source_hash: {{ path }}/sha256sums.txt
    - archive_format: tar
    - enforce_toplevel: False
    - options: --strip-components=1
    - user: root
    - group: root

node_exporter_hardcoded_package:
  file.append:
    - name: /tmp/hardcoded-packages.csv
    - text: |
        node_exporter;{{ version }};Hardcoded;Apache License 2.0;Prometheus;{{ url }};Prometheus exporter for hardware and OS metrics exposed by *NIX kernels, written in Go with pluggable metric collectors.

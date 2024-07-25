{% set version = '0.19.0' %}
{% set path = 'https://github.com/prometheus/blackbox_exporter/releases/download/v' ~ version %}
{% set architecture = 'arm64' if salt['environ.get']('ARCHITECTURE') == 'arm64' else 'amd64' %}
{% set url = path ~ '/blackbox_exporter-' ~ version ~ '.linux-' ~ architecture ~ '.tar.gz' %}

/opt/blackbox_exporter:
  file.directory:
    - name: /opt/blackbox_exporter
    - user: root
    - group: root
    - mode: 700

install_blackbox_exporter:
  archive.extracted:
    - name: /opt/blackbox_exporter/
    - source: {{ url }}
    - source_hash: {{ path }}/sha256sums.txt
    - archive_format: tar
    - enforce_toplevel: False
    - options: --strip-components=1
    - user: root
    - group: root

blackbox_exporter_hardcoded_package:
  file.append:
    - name: /tmp/hardcoded-packages.csv
    - text: |
        blackbox_exporter;{{ version }};Hardcoded;Apache License 2.0;Prometheus;{{ url }};The blackbox exporter allows blackbox probing of endpoints over HTTP, HTTPS, DNS, TCP, ICMP and gRPC.

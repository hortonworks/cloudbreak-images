{% set version = '2.54.1' %}
{% set path = 'https://github.com/prometheus/prometheus/releases/download/v' ~ version %}
{% set architecture = 'arm64' if salt['environ.get']('ARCHITECTURE') == 'arm64' else 'amd64' %}
{% set url = path ~ '/prometheus-' ~ version ~ '.linux-' ~ architecture ~ '.tar.gz' %}

install_prometheus:
  archive.extracted:
    - name: /opt/cdp-prometheus/
    - source: {{ url }}
    - source_hash: {{ path }}/sha256sums.txt
    - archive_format: tar
    - enforce_toplevel: False
    - options: --strip-components=1 --exclude='promtool'

prometheus_hardcoded_package:
  file.append:
    - name: /tmp/hardcoded-packages.csv
    - text: |
        prometheus;{{ version }};Hardcoded;Apache License 2.0;Prometheus;{{ url }};The Prometheus monitoring system and time series database.

/opt/cdp-prometheus:
  file.directory:
    - name: /opt/cdp-prometheus
    - user: root
    - group: root
    - mode: 700
    - recurse:
      - user
      - group

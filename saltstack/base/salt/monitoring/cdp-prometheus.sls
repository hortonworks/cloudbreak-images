/opt/cdp-prometheus:
  file.directory:
    - name: /opt/cdp-prometheus
    - user: root
    - group: root
    - mode: 700

install_prometheus:
  archive.extracted:
    - name: /opt/cdp-prometheus/
    - source: https://github.com/prometheus/prometheus/releases/download/v2.36.2/prometheus-2.36.2.linux-amd64.tar.gz
    - source_hash: sha256=3f558531c6a575d8372b576b7e76578a98e2744da6b89982ea7021b6f000cddd
    - archive_format: tar
    - enforce_toplevel: False
    - options: --strip-components=1 --exclude='promtool'
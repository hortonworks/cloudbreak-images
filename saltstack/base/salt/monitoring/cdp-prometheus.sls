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
    - source_hash: md5=f85cbfb9b2c4266ac4ece5a43efe28d2
    - archive_format: tar
    - enforce_toplevel: False
    - options: --strip-components=1 --exclude='promtool'
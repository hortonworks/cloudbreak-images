/opt/blackbox_exporter:
  file.directory:
    - name: /opt/blackbox_exporter
    - user: root
    - group: root
    - mode: 700

install_blackbox_exporter:
  archive.extracted:
    - name: /opt/blackbox_exporter/
    - source: https://github.com/prometheus/blackbox_exporter/releases/download/v0.19.0/blackbox_exporter-0.19.0.linux-amd64.tar.gz
    - source_hash: md5=18097589ff31140747563a9a9e1a0785
    - archive_format: tar
    - enforce_toplevel: False
    - options: --strip-components=1

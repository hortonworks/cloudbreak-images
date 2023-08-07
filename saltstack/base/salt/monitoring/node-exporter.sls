/opt/node_exporter:
  file.directory:
    - name: /opt/node_exporter
    - user: root
    - group: root
    - mode: 700

install_node_exporter:
  archive.extracted:
    - name: /opt/node_exporter/
    - source: https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
    - source_hash: sha256=68f3802c2dd3980667e4ba65ea2e1fb03f4a4ba026cca375f15a0390ff850949
    - archive_format: tar
    - enforce_toplevel: False
    - options: --strip-components=1
    - user: root
    - group: root
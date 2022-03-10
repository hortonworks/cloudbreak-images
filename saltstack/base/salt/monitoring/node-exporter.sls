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
    - source_hash: md5=9ed75103b9bc65b30e407d4f238f9dea
    - archive_format: tar
    - enforce_toplevel: False
    - options: --strip-components=1
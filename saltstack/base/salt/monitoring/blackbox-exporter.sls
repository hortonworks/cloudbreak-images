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
    - source_hash: sha256=af2ae1394c4f9b46962ac1510e1dacac78115c11e625991fb6c54825d2240896
    - archive_format: tar
    - enforce_toplevel: False
    - options: --strip-components=1
    - user: root
    - group: root
install_node_exporter:
  archive.extracted:
    - name: /usr/local/bin/
    - source: https://github.com/prometheus/node_exporter/releases/download/0.12.0/node_exporter-0.12.0.linux-amd64.tar.gz
    - source_hash: md5=efe49b6fae4b1a5cb75b24a60a35e1fc
    - archive_format: tar
    - enforce_toplevel: False
    - options: --strip-components=1

create_node_exporter_service_files:
  file.managed:
    - user: root
    - group: root
{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
    - name: /etc/init.d/node_exporter
    - source: 
      - salt://{{ slspath }}/etc/init.d/node_exporter.{{ grains['os_family'] | lower }}
      - salt://{{ slspath }}/etc/init.d/node_exporter
    - mode: 755
{% elif grains['init'] == 'systemd' %}
    - name: /etc/systemd/system/node_exporter.service
    - source: salt://{{ slspath }}/etc/systemd/system/node_exporter.service
{% endif %}

config_node_exporter_default:
  file.managed:
    - user: root
    - group: root
    - name: /etc/default/node_exporter
    - source: salt://{{ slspath }}/etc/default/node_exporter
    - mode: 644

config_consul_node_exporter:
  file.managed:
    - user: root
    - group: root
    - name: /etc/consul.d/node-exporter.json
    - source: salt://{{ slspath }}/etc/consul.d/node-exporter.json
    - mode: 644

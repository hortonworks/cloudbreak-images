install_consul:
  archive.extracted:
    - name: /usr/local/bin/
    - source: https://releases.hashicorp.com/consul/0.7.3/consul_0.7.3_linux_amd64.zip
    - archive_format: zip
    - enforce_toplevel: False
    - skip_verify: True
    - if_missing: /usr/local/bin/consul

create_consuld_directory:
  file.directory:
    - name: /etc/consul.d

create_consul_opt_directory:
  file.directory:
    - name: /opt/consul

create_consul_service_files:
  file.managed:
    - user: root
    - group: root
{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
    - name: /etc/init.d/consul
    - source:
      - salt://{{ slspath }}/etc/init.d/consul.{{ grains['os'] | lower }}
      - salt://{{ slspath }}/etc/init.d/consul
    - mode: 755
{% elif grains['init'] == 'systemd' %}
    - name: /etc/systemd/system/consul.service
    - source: salt://{{ slspath }}/etc/systemd/system/consul.service
{% endif %}

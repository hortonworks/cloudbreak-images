install_consul_template:
  archive.extracted:
    - name: /usr/local/bin/
    - source: https://releases.hashicorp.com/consul-template/0.16.0/consul-template_0.16.0_linux_amd64.zip
    - source_hash: md5=4637fb989af3b10a2cc34a0fa5fd414d
    - archive_format: zip
    - enforce_toplevel: False
    - skip_verify: True
    - if_missing: /usr/local/bin/consul-template

create_consul_template_service_files:
  file.managed:
    - user: root
    - group: root
{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
    - name: /etc/init.d/consul-template
    - source: salt://{{ slspath }}/etc/init.d/consul-template
    - mode: 755
{% elif grains['init'] == 'systemd' %}
    - name: /etc/systemd/system/consul-template.service
    - source: salt://{{ slspath }}/etc/systemd/system/consul-template.service
{% endif %}

/etc/consul-template.d:
  file.directory:
    - user: root
    - mode: 755
    - makedirs: True

config_consul_template_prometheus_alerting:
  file.managed:
    - user: root
    - group: root
    - name: /etc/consul-template.d/prometheus-alerting
    - source: salt://{{ slspath }}/etc/consul-template.d/prometheus-alerting
    - mode: 644

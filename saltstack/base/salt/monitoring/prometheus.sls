install_prometheus:
  archive.extracted:
    - name: /usr/local/bin/
    - source: https://github.com/prometheus/prometheus/releases/download/v1.4.1/prometheus-1.4.1.linux-amd64.tar.gz
    - source_hash: md5=6cfb712ef7f33f42611bf7ebb02bc740
    - archive_format: tar
    - enforce_toplevel: False
    - options: --strip-components=1
    - if_missing: /usr/local/bin/prometheus

install_jmx_javaagent_exporter:
  file.managed:
    - name: /opt/jmx_javaagent.jar
    - source: https://sequenceiq.s3.amazonaws.com/jmx_prometheus_javaagent-0.8-SNAPSHOT.jar
    - source_hash: md5=09f61e70f8800535e42746a85c898c72
    - if_missing: /opt/jmx_javaagent.jar

create_prometheus_service_files:
  file.managed:
    - user: root
    - group: root
{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
    - name: /etc/init.d/prometheus
    - source:
      - salt://{{ slspath }}/etc/init.d/prometheus.{{ grains['os'] | lower }}
      - salt://{{ slspath }}/etc/init.d/prometheus
    - mode: 755
{% elif grains['init'] == 'systemd' %}
    - name: /etc/systemd/system/prometheus.service
    - source: salt://{{ slspath }}/etc/systemd/system/prometheus.service
{% endif %}

/etc/prometheus/templates/:
  file.directory:
    - mode: 755
    - user: root
    - group: root
    - makedirs: True

config_prometheus_template:
  file.managed:
    - user: root
    - group: root
    - name: /etc/prometheus/templates/alerting.rule.ctmpl
    - source: salt://{{ slspath }}/etc/prometheus/templates/alerting.rule.ctmpl
    - mode: 644

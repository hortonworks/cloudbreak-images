/opt/jmx_javaagent.jar:
  file.managed:
    - source: https://s3.eu-central-1.amazonaws.com/hortonworks-prometheus/jmx_prometheus_javaagent-0.10.jar
    - skip_verify: True
    - user: root
    - group: root
    - mode: 644

/etc/jmx_exporter:
  file.recurse:
    - source: salt://{{ slspath }}/etc/jmx_exporter
    - include_empty: True

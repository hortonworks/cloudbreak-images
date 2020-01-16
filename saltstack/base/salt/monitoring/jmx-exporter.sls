/opt/jmx_javaagent.jar:
  file.managed:
    - source: https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.2.0/jmx_prometheus_javaagent-0.2.0.jar
    - source_hash: md5=5aed7dd0f6ed8bdf62a303db5d18410d
    - user: root
    - group: root
    - mode: 644

/etc/jmx_exporter:
  file.recurse:
    - source: salt://{{ slspath }}/etc/jmx_exporter
    - include_empty: True

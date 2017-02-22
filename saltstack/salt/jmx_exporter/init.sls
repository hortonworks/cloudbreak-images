/opt/jmx_javaagent.jar:
  file.managed:
    - source: https://sequenceiq.s3.amazonaws.com/jmx_prometheus_javaagent-0.8-SNAPSHOT.jar
    - user: root
    - group: root
    - mode: 644
    - source_hash: md5=09f61e70f8800535e42746a85c898c72

/etc/jmx_exporter:
  file.recurse:
    - source: salt://{{ slspath }}/etc/jmx_exporter
    - include_empty: True
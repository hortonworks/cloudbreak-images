/cdp/bin/ccmv2/generate-config.sh:
  file.managed:
    - name: /cdp/bin/ccmv2/generate-config.sh
    - makedirs: True
    - source: salt://{{ slspath }}/cdp/bin/ccmv2/generate-config.sh
    - mode: 740

/etc/logrotate.d/ccmv2:
  file.managed:
    - name: /etc/logrotate.d/ccmv2
    - source: salt://{{ slspath }}/etc/logrotate.d/ccmv2
    - user: root
    - group: root
    - mode: 644

install_jumpgate_agent:
  pkg.installed:
    - sources:
      - jumpgate-agent: http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/14100647/inverting-proxy/1.x/redhat7/yum/tars/inverting-proxy/jumpgate-agent.rpm

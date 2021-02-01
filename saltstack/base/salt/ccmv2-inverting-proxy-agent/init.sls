/cdp/bin/ccmv2/run-inverting-proxy-agent.sh:
  file.managed:
    - name: /cdp/bin/ccmv2/run-inverting-proxy-agent.sh
    - makedirs: True
    - source: salt://{{ slspath }}/cdp/bin/ccmv2/run-inverting-proxy-agent.sh
    - mode: 740

/cdp/bin/ccmv2/update-inverting-proxy-agent-values.sh:
  file.managed:
    - name: /cdp/bin/ccmv2/update-inverting-proxy-agent-values.sh
    - makedirs: True
    - source: salt://{{ slspath }}/cdp/bin/ccmv2/update-inverting-proxy-agent-values.sh
    - mode: 740

/etc/systemd/system/ccmv2-inverting-proxy-agent@.service:
  file.managed:
    - name: /etc/systemd/system/ccmv2-inverting-proxy-agent@.service
    - makedirs: True    
    - source: salt://{{ slspath }}/etc/systemd/system/ccmv2-inverting-proxy-agent@.service

/cdp/bin/ccmv2/inverting-proxy-agent:
  file.managed:
    - makedirs: True
    - source: http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/9337444/inverting-proxy/1.x/redhat7/yum/tars/inverting-proxy/inverting-proxy-forwarding-agent
    - source_hash: md5=7447818e45cc25e2c1e9cbd70b1cd4bb
    - mode: 740

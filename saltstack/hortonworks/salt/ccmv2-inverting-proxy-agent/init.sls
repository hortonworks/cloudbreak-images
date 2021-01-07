/cdp/bin/ccmv2/inverting-proxy-agent:
  file.managed:
    - makedirs: True
    - source: http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/7630277/inverting-proxy/1.x/redhat7/yum/tars/inverting-proxy/inverting-proxy-forwarding-agent 
    - source_hash: md5=c52126bcf800aa7f1d144eb8f183090f
    - mode: 740

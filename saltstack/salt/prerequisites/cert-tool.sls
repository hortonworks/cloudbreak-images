/sbin/cert-tool :
  file.managed:
    - source: https://github.com/ehazlett/certm/releases/download/0.1.2/certm_linux_amd64 
    - user: root
    - group: root
    - mode: 755
    - source_hash: md5=9a2afe90c41cc645e6ea6e731ac20850

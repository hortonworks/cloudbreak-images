/sbin/cert-tool :
  file.managed:
    - source: https://github.com/ehazlett/certm/releases/download/v0.0.1/cert-tool_linux_amd64
    - user: root
    - group: root
    - mode: 755
    - source_hash: md5=986784535ed40745be95009b7314c657

/sbin/certm :
  file.managed:
    - source: https://github.com/ehazlett/certm/releases/download/0.1.2/certm_linux_amd64 
    - user: root
    - group: root
    - mode: 755
    - source_hash: md5=9a2afe90c41cc645e6ea6e731ac20850

/sbin/cert-tool :
  file.managed:
    - source: https://github.com/ehazlett/certm/releases/download/v0.0.1/cert-tool_linux_amd64
    - user: root
    - group: root
    - mode: 755
    - source_hash: md5=986784535ed40745be95009b7314c657
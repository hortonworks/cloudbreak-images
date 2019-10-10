/sbin/cert-tool :
  file.managed:
    - source: https://github.com/ehazlett/certm/releases/download/v0.0.1/cert-tool_linux_amd64
    - user: root
    - group: root
    - mode: 755
    - source_hash: md5=986784535ed40745be95009b7314c657

install_certm:
  archive.extracted:
    - name: /sbin/
    - source: https://github.com/keyki/certm/releases/download/v0.1.3/certm_0.1.3_Linux_x86_64.tgz
    - source_hash: md5=7aafdb92c4d17e842f2167c51451412c
    - archive_format: tar
    - enforce_toplevel: false
    - skip_verify: True
    - if_missing: /sbin/certm
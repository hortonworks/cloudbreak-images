/sbin/cert-tool :
  file.managed:
    - source: https://github.com/ehazlett/certm/releases/download/v0.0.1/cert-tool_linux_amd64
    - user: root
    - group: root
    - mode: 755
    - source_hash: sha256=fe23e9c34c82c5e2df2871e361e1544c39abb7366a0546a2f82a8d8ed550a3aa

install_certm:
  archive.extracted:
    - name: /sbin/
    - source: https://github.com/keyki/certm/releases/download/v0.1.3/certm_0.1.3_Linux_x86_64.tgz
    - source_hash: sha256=e96494ac4d485c1c06f8872bf00558ad95bb87e463c46fce071d8f24f0c4e3d6
    - archive_format: tar
    - enforce_toplevel: false
    - skip_verify: True
    - if_missing: /sbin/certm
    - user: root
    - group: root
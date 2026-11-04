# certm compatible wrapper around openssl, it replaces the certm binary that was downloaded here before.
# Cloudbreak calls certm on the nodes, so the command has to stay available with the same flags.
install_certm:
  file.managed:
    - name: /usr/sbin/certm
    - source: salt://{{ slspath }}/usr/sbin/certm
    - user: root
    - group: root
    - mode: 755

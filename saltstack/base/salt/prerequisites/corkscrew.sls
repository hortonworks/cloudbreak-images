install_corkscrew:
{% if pillar['OS'] != 'centos8' or pillar['OS'] != 'debian9' %}
  pkg.installed:
    - sources:
      - corkscrew: http://ftp.altlinux.org/pub/distributions/ALTLinux/Sisyphus/x86_64/RPMS.classic/corkscrew-2.0-alt1.qa1.x86_64.rpm
{% else %}
  cmd.script:
    - name: salt://prerequisites/corkscrew/install_corkscrew.sh
    - output_loglevel: DEBUG
    - timeout: 9000
    - failhard: True
{% endif %}

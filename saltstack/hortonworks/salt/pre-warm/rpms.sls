install_rpms:
  cmd.script:
    - name: salt://pre-warm/tmp/install_rpms.sh
    - template: jinja
    - env:
      - PRE_WARM_RPMS: {{ pillar['PRE_WARM_RPMS'] }}
    - output_loglevel: DEBUG
    - timeout: 9000
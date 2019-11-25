install_parcels:
  cmd.script:
    - name: salt://pre-warm/tmp/pre_warm_parcels.py
    - template: jinja
    - env:
      - OS: {{ pillar['OS'] }}
      - PRE_WARM_PARCELS: '{{ pillar['PRE_WARM_PARCELS'] }}'
      - PRE_WARM_CSD: '{{ pillar['PRE_WARM_CSD'] }}'
      - PARCELS_ROOT: {{ pillar['PARCELS_ROOT'] }}
    - output_loglevel: DEBUG
    - timeout: 9000
    - failhard: True

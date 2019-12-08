install_cdh:
  cmd.script:
    - name: salt://pre-warm/tmp/install_cdh.sh
    - template: jinja
    - env:
      - STACK_TYPE: "{{ pillar['STACK_TYPE'] }}"
      - STACK_VERSION: {{ pillar['STACK_VERSION'] }}
      - STACK_BASEURL: {{ pillar['STACK_BASEURL'] }}
      - STACK_REPOID: {{ pillar['STACK_REPOID'] }}
      - STACK_REPOSITORY_VERSION: {{ pillar['STACK_REPOSITORY_VERSION'] }}
      - CLUSTERMANAGER_VERSION: {{ pillar['CLUSTERMANAGER_VERSION'] }}
      - OS: {{ pillar['OS'] }}
      - PARCELS_ROOT: {{ pillar['PARCELS_ROOT'] }}
      - PARCELS_NAME: {{ pillar['PARCELS_NAME'] }}
    - output_loglevel: DEBUG
    - timeout: 9000
    - unless: ls /tmp/install_cdh.status
    - failhard: True

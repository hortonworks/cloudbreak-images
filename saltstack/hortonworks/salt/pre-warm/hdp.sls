install_hdp:
  cmd.script:
    - name: salt://pre-warm/tmp/install_hdp.sh
    - template: jinja
    - env:
      - HDP_STACK_VERSION: "{{ pillar['HDP_STACK_VERSION'] }}"
      - HDP_VERSION: {{ pillar['HDP_VERSION'] }}
      - HDP_BASEURL: {{ pillar['HDP_BASEURL'] }}
      - HDP_REPOID: {{ pillar['HDP_REPOID'] }}
      - VDF: {{ pillar['VDF'] }}
      - REPOSITORY_VERSION: {{ pillar['REPOSITORY_VERSION'] }}
    - output_loglevel: DEBUG
    - timeout: 4800
    - unless: ls /tmp/install_hdp.status
    - failhard: True

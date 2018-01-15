add_install_hdp_sh:
  file.managed:
    - name: /tmp/install_hdp.sh
    - source: salt://{{ slspath }}/tmp/install_hdp.sh
    - template: jinja
    - skip_verify: True
    - makedirs: True
    - mode: 755

set_env_for_install_hdp_sh:
  environ.setenv:
    - name: set_env_for_install_hdp_sh
    - value:
        HDP_STACK_VERSION: "{{ pillar['HDP_STACK_VERSION'] }}"
        HDP_VERSION: {{ pillar['HDP_VERSION'] }}
        HDP_BASEURL: {{ pillar['HDP_BASEURL'] }}
        HDP_REPOID: {{ pillar['HDP_REPOID'] }}
    - update_minion: True

run_install_hdp_sh:
  cmd.run:
    - name: sh -x /tmp/install_hdp.sh 2>&1 | tee -a /var/log/install_hdp_sh.log && exit ${PIPESTATUS[0]}
    - unless: ls /var/log/install_hdp_sh.log
    - require:
      - file: add_install_hdp_sh
      - environ: set_env_for_install_hdp_sh

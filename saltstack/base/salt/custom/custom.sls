add_custom_script:
  file.managed:
    - name: /usr/local/bin/custom.sh
    - source: salt://{{ slspath }}/usr/local/bin/custom.sh
    - skip_verify: True
    - makedirs: True
    - mode: 755

run_custom_sh:
  cmd.run:
    - name: sh -x /usr/local/bin/custom.sh 2>&1 | tee -a /var/log/custom_sh.log && exit ${PIPESTATUS[0]}
    - shell: /bin/bash
    - unless: ls /var/log/custom_sh.log
    - require:
      - file: add_custom_script

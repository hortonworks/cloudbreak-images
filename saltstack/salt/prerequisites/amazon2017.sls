add_amazon2017_patch_script:
  file.managed:
    - name: /tmp/amazon2017.sh
    - source: salt://{{ slspath }}/tmp/amazon2017.sh
    - skip_verify: True
    - makedirs: True
    - mode: 755

run_amazon2017_sh:
  cmd.run:
    - name: sh -x /tmp/amazon2017.sh 2>&1 | tee -a /var/log/amazon2017_sh.log && exit ${PIPESTATUS[0]}
    - unless: ls /var/log/amazon2017_sh.log
    - require:
      - file: add_amazon2017_patch_script
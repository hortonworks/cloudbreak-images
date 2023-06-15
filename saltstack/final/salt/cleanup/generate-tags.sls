add_generate_tags_script:
  file.managed:
    - name: /tmp/generate-tags.sh
    - source: salt://{{ slspath }}/tmp/generate-tags.sh
    - skip_verify: True
    - makedirs: True
    - mode: 755

run_generate_tags:
  cmd.run:
    - name: /tmp/generate-tags.sh 2>&1 >>/var/log/generate-tags.sh.log
    - unless: /var/log/generate-tags.sh.log
    - require:
      - file: add_generate_tags_script

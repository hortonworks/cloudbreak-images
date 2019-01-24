add_generate_package_versions_script:
  file.managed:
    - name: /tmp/generate-package-versions.sh
    - source: salt://{{ slspath }}/tmp/generate-package-versions.sh
    - skip_verify: True
    - makedirs: True
    - mode: 755

run_generate_package_versions:
  cmd.run:
    - name: sh -x /tmp/generate-package-versions.sh {{ salt['pillar.get']('package_versions', '') }} 2>&1 | tee -a /var/log/generate-package-versions.sh.log && exit ${PIPESTATUS[0]}
    - unless: /var/log/generate-package-versions.sh.log
    - require:
      - file: add_generate_package_versions_script

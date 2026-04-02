add_generate_package_versions_script:
  file.managed:
    - name: /tmp/generate-package-versions.sh
    - source: salt://{{ slspath }}/tmp/generate-package-versions.sh
    - skip_verify: True
    - makedirs: True
    - mode: 755

run_generate_package_versions:
  cmd.run:
    - name: /tmp/generate-package-versions.sh {{ salt['pillar.get']('package_versions', '') }} 2>&1 >>/tmp/package-versions.log
    - env:
      - CLOUD_PROVIDER: {{ salt['environ.get']('CLOUD_PROVIDER') }}
    - require:
      - file: add_generate_package_versions_script

publish_package_versions_json:
  cmd.run:
    - name: chmod 644 /tmp/package-versions.json

publish_package_versions_log:
  cmd.run:
    - name: chmod 644 /tmp/package-versions.log
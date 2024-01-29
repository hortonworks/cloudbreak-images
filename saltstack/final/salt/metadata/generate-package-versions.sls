add_generate_package_versions_script:
  file.managed:
    - name: /tmp/generate-package-versions.sh
    - source: salt://{{ slspath }}/tmp/generate-package-versions.sh
    - skip_verify: True
    - makedirs: True
    - mode: 755

run_generate_package_versions:
  cmd.run:
    - name: /tmp/generate-package-versions.sh {{ salt['pillar.get']('package_versions', '') }} 2>&1 >>/var/log/generate-package-versions.sh.log
    - unless: /var/log/generate-package-versions.sh.log
    - env:
      - CLOUD_PROVIDER: {{ salt['environ.get']('CLOUD_PROVIDER') }}
    - require:
      - file: add_generate_package_versions_script

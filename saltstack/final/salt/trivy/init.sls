{% set trivy_version = '0.76.0' %}
{% if grains['osarch'] == 'aarch64' %}
  {% set trivy_arch = 'ARM64' %}
  {% set trivy_sha256 = 'aab21e677a7b7071fc79f1711480840754c18a1b9d9cefa7ccd06af63a0e8f4c' %}
{% else %}
  {% set trivy_arch = '64bit' %}
  {% set trivy_sha256 = 'e24b1c51293c1b15e4ba8d45bbc7891ba053f90278ec2698f3562c993e145fe7' %}
{% endif %}
{% set trivy_tarball = 'trivy_' ~ trivy_version ~ '_Linux-' ~ trivy_arch ~ '.tar.gz' %}
{% set trivy_home = '/opt/trivy-scanner' %}

trivy_scan:
  file.directory:
    - name: /tmp/trivy
    - mode: 755

trivy_install:
  cmd.run:
    - name: |
        mkdir -p {{ trivy_home }} && \
        cd {{ trivy_home }} && \
        curl -sfL -o {{ trivy_tarball }} https://github.com/aquasecurity/trivy/releases/download/v{{ trivy_version }}/{{ trivy_tarball }} && \
        echo "{{ trivy_sha256 }}  {{ trivy_tarball }}" | sha256sum -c - && \
        tar -xzf {{ trivy_tarball }} trivy && \
        rm -f {{ trivy_tarball }}

# The scanner and its vulnerability DB cache can't live in /tmp as it is mounted noexec (and might be a small tmpfs),
# so they are kept in a dedicated dir which is skipped from the scan and removed afterwards. Only the report stays in /tmp.
trivy_run_vuln_scan:
  cmd.run:
    - name: |
        {{ trivy_home }}/trivy rootfs \
          --cache-dir {{ trivy_home }}/cache \
          --scanners vuln \
          --severity HIGH,CRITICAL \
          --skip-dirs /proc,/sys,/dev,/tmp,{{ trivy_home }} \
          --timeout 60m \
          --no-progress \
          --skip-version-check \
          -f json \
          -o /tmp/trivy/trivy_vuln_report.json \
          /
    - require:
      - cmd: trivy_install
      - file: trivy_scan

trivy_report_chmod:
  cmd.run:
    - name: chmod 644 /tmp/trivy/trivy_*
    - require:
      - cmd: trivy_run_vuln_scan

# No requisites on purpose: the scanner is removed even if the scan failed
trivy_scan_cleanup:
  file.absent:
    - name: {{ trivy_home }}

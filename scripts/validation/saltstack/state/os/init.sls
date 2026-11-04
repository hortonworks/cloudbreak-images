{% set package_versions_file = '/tmp/package-versions.json' %}
{% set os = pillar['OS'] %}
{% set is_rhel = os in ['redhat8', 'redhat9'] %}
{% set package_versions = {} %}
{% if is_rhel and salt['file.file_exists'](package_versions_file) %}
{% set package_versions = salt['file.read'](package_versions_file) | load_json %}
{% endif %}
{% set expected_version = package_versions.get('os-version') %}

check_os:
{%- if not is_rhel %}
  test.succeed_without_changes:
    - name: "OS {{ os }} is not RHEL, no 'os-version' in package-versions.json, skipping OS validation"
{%- elif not expected_version %}
  test.fail_without_changes:
    - name: "{{ package_versions_file }} is missing or has no 'os-version' entry, cannot validate the OS version"
{%- else %}
  cmd.run:
    - name: |
        set -e
        cat /etc/redhat-release
        # Same parsing as scripts/salt-final.sh, which produces the 'os-version' entry
        actual_version=$(grep -oP "[0-9\.]*" /etc/redhat-release)
        actual_version=${actual_version/.0/}
        if [[ "$actual_version" != "{{ expected_version }}" ]]; then
          echo "OS version mismatch: expected {{ expected_version }} (package-versions.json), found $actual_version"
          exit 1
        fi
        echo "OS version $actual_version matches package-versions.json"
    - shell: /bin/bash
{%- endif %}

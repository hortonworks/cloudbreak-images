{% set package_versions_file = '/tmp/package-versions.json' %}
{% set package_versions = {} %}
{% if salt['file.file_exists'](package_versions_file) %}
{% set package_versions = salt['file.read'](package_versions_file) | load_json %}
{% endif %}
{% set expected_default = package_versions.get('python') %}
{% set expected_full = '' %}
{% if expected_default %}
{% set expected_full = package_versions.get('python' ~ expected_default[0] ~ expected_default[2:], '').split('-')[0] %}
{% endif %}

check_python:
{%- if not expected_default %}
  test.fail_without_changes:
    - name: "{{ package_versions_file }} is missing or has no 'python' entry, cannot validate the default Python"
{%- else %}
  cmd.run:
    - name: |
        set -e
        python_version_output=$(python --version 2>&1)
        echo "$python_version_output"
        actual_default=$(echo "$python_version_output" | grep -oP 'Python\s+\K\d+\.\d+')
        actual_full=$(echo "$python_version_output" | grep -oP 'Python\s+\K\S+')
        if [[ "$actual_default" != "{{ expected_default }}" ]]; then
          echo "Default Python version mismatch: expected {{ expected_default }} (package-versions.json), found $actual_default"
          exit 1
        fi
        {%- if expected_full %}
        if [[ "$actual_full" != "{{ expected_full }}" ]]; then
          echo "Default Python full version mismatch: expected {{ expected_full }} (package-versions.json python{{ expected_default | replace('.', '') }}), found $actual_full"
          exit 1
        fi
        {%- endif %}
        echo "Default Python version $actual_full matches package-versions.json"
    - shell: /bin/bash
{%- endif %}

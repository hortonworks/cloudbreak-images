{% set package_versions_file = '/tmp/package-versions.json' %}
{% set is_freeipa = pillar['IMAGE_TYPE'] == 'freeipa' %}
{% set stack_version = pillar['STACK_VERSION'] %}
{% set is_old_stack = stack_version != '' and stack_version.split('.') | map('int') | list < '7.2.15'.split('.') | map('int') | list %}
{% set package_versions = {} %}
{% if not is_freeipa and not is_old_stack and salt['file.file_exists'](package_versions_file) %}
{% set package_versions = salt['file.read'](package_versions_file) | load_json %}
{% endif %}
{% set expected_major = package_versions.get('java') %}
{% set expected_full = package_versions.get('java' ~ expected_major, '') %}

{% set skip_reason = '' %}
{% if is_freeipa %}
{% set skip_reason = 'FreeIPA image' %}
{% elif is_old_stack %}
{% set skip_reason = 'Stack version ' ~ stack_version ~ ' is below 7.2.15, no default JDK in package-versions.json' %}
{% endif %}

check_jdk:
{%- if skip_reason %}
  test.succeed_without_changes:
    - name: "{{ skip_reason }}, skipping JDK validation"
{%- elif not expected_major %}
  test.fail_without_changes:
    - name: "{{ package_versions_file }} is missing or has no 'java' entry, cannot validate the default JDK"
{%- else %}
  cmd.run:
    - name: |
        set -e
        java_version_output=$(java -version 2>&1)
        echo "$java_version_output"
        actual_major=$(echo "$java_version_output" | grep -oP 'version [^0-9]?(1\.)?\K\d+')
        actual_full=$(echo "$java_version_output" | grep -oP 'version\s"\K[^"]+')
        if [[ "$actual_major" != "{{ expected_major }}" ]]; then
          echo "Default JDK major version mismatch: expected {{ expected_major }} (package-versions.json), found $actual_major"
          exit 1
        fi
        {%- if expected_full %}
        if [[ "$actual_full" != "{{ expected_full }}" ]]; then
          echo "Default JDK version mismatch: expected {{ expected_full }} (package-versions.json java{{ expected_major }}), found $actual_full"
          exit 1
        fi
        {%- endif %}
        echo "Default JDK version $actual_full matches package-versions.json"
    - shell: /bin/bash
{%- endif %}

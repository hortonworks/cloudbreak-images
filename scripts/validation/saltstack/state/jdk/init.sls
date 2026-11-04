{% from 'macros/version.jinja' import package_versions, check_version with context %}
{% set java_version_output = salt['cmd.run']('java -version 2>&1', python_shell=True) %}
# Same parsing as saltstack/final/salt/metadata/tmp/generate-package-versions.sh, which produces the 'java' entries
{% set actual_major = (java_version_output | regex_search('version [^0-9]?(?:1\\.)?(\\d+)') or [''])[0] %}
{% set actual_full = (java_version_output | regex_search('version\\s"([^"]+)"') or [''])[0] %}
{% set expected_major = package_versions.get('java', '') %}
{% set full_key = 'java' ~ expected_major %}
{% set expected_full = package_versions.get(full_key, '') %}

# Version checks against the package-versions
{{ check_version('check_jdk_major', 'Default JDK major', 'java', expected_major, actual_major, False, False) }}
{{ check_version('check_jdk', 'Default JDK', full_key, expected_full, actual_full, False, False) }}

# Hardcoded version checks based on image type and OS
{% if salt['environ.get']('IMAGE_TYPE') != 'runtime' %}
{% if salt['environ.get']('OS') == 'redhat8' %}
{{ check_version('base_rhel8_check_jdk', 'Base RHEL8 Default JDK', full_key, '1.8.', actual_full, True, True) }}
{% elif salt['environ.get']('OS') == 'redhat9' %}
{{ check_version('base_rhel9_check_jdk', 'Base RHEL9 Default JDK', full_key, '17.', actual_full, True, True) }}
{% endif %}
{% else %}
{{ check_version('runtime_check_jdk', 'Runtime Default JDK', full_key, '17.', actual_full, True, True) }}
{% endif %}

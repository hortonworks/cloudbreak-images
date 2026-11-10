{% from 'macros/version.jinja' import package_versions, check_version with context %}
{% set python_version_output = salt['cmd.run']('python --version 2>&1', python_shell=True) %}
# Same parsing as saltstack/final/salt/metadata/tmp/generate-package-versions.sh, which produces the 'python' entry
{% set actual_default = (python_version_output | regex_search('Python\\s+(\\d+\\.\\d+)') or [''])[0] %}
{% set actual_full = (python_version_output | regex_search('Python\\s+(\\S+)') or [''])[0] %}
{% set expected_default = package_versions.get('python', '') %}
{% set full_key = 'python' ~ expected_default | replace('.', '') %}
{% set expected_full = package_versions.get(full_key, '').split('-')[0] %}

# Version checks against the package-versions
{{ check_version('check_python_default', 'Default Python', 'python', expected_default, actual_default, False) }}
{{ check_version('check_python', 'Default Python', full_key, expected_full, actual_full, False) }}

# Hardcoded version checks based on OS
{% if salt['environ.get']('OS') == 'redhat8' %}
{{ check_version('rhel8_check_python', 'RHEL8 Default Python', full_key, '3.6.8', actual_full, True, False) }}
{% elif salt['environ.get']('OS') == 'redhat9' %}
{% if salt['environ.get']('STACK_VERSION') == '7.3.2' %}
{{ check_version('rhel9_7_3_2_check_python', 'RHEL9 (7.3.2) Default Python', full_key, '3.9.21', actual_full, True, False) }}
{% else %}
{{ check_version('rhel9_check_python', 'RHEL9 Default Python', full_key, '3.9.25', actual_full, True, False) }}
{% endif %}
{% endif %}

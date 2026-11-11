{% from 'macros/version.jinja' import package_versions, check_version with context %}
{% set redhat_release = salt['file.read']('/etc/redhat-release') if salt['file.file_exists']('/etc/redhat-release') else '' %}
# Same parsing as scripts/salt-final.sh, which produces the 'os-version' entry
{% set actual_version = (redhat_release | regex_search('([0-9.]+)') or [''])[0] | replace('.0', '', 1) %}
{% set expected_version = package_versions.get('os-version', '') %}

# Version checks against the package-versions
{{ check_version('check_os', 'OS', 'os-version', expected_version, actual_version, False, False) }}

# Hardcoded version checks based on OS
{% if salt['environ.get']('OS') == 'redhat8' %}
{{ check_version('rhel8_check_os', 'RHEL8 OS', 'os-version', '8.10', actual_version, True, True) }}
{% elif salt['environ.get']('OS') == 'redhat9' %}
{% if salt['environ.get']('STACK_VERSION') == '7.3.2' %}
{{ check_version('rhel9_7_3_2_check_os', 'RHEL9 (7.3.2) OS', 'os-version', '9.6', actual_version, True, True) }}
{% else %}
{{ check_version('rhel9_check_os', 'RHEL9 OS', 'os-version', '9.8', actual_version, True, True) }}
{% endif %}
{% endif %}

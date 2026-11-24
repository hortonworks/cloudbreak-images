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

# Allowlist of the Python interpreters that are intentionally installed (see install_python_pip in scripts/salt-install.sh).
# Downstream services (e.g. Hue) pick the newest interpreter on the host, so any other interpreter (e.g. one pulled in
# transitively by a -devel package) would be selected without a matching psycopg2 driver and break the cluster.
{% set is_freeipa = salt['environ.get']('IMAGE_TYPE') == 'freeipa' %}
{% set allowed_pythons = [] %}
{% if salt['environ.get']('OS') == 'redhat9' %}
{% set allowed_pythons = allowed_pythons + ['3.9', '3.11'] %}
{% if not is_freeipa %}
{% set allowed_pythons = allowed_pythons + ['3.12'] %}
{% endif %}
{% elif salt['environ.get']('OS') == 'redhat8' %}
{% set allowed_pythons = allowed_pythons + ['3.6', '3.11'] %}
{% if not is_freeipa %}
{% set allowed_pythons = allowed_pythons + ['3.8', '3.9', '3.12'] %}
{% endif %}
{% endif %}

print_allowed_pythons:
  test.succeed_without_changes:
    - name: "Allowed python versions: {{ allowed_pythons | join(', ') }}."

{% set found_pythons = [] %}
# Check for python binaries
{% set python_binaries = salt['cmd.run']('find / -path "/boot" -prune -o -path "/dev" -prune -o -path "/proc" -prune -o -path "/run" -prune -o -path "/sys" -prune -o -path "/opt/cloudera" -prune -o -type f -executable -regextype posix-extended -regex ".*/python3\.[0-9]+$" -print 2>/dev/null', python_shell=True) %}
{% for binary in python_binaries.splitlines() %}
{% set match = binary.split('/')[-1] | regex_search('^python(\\d+\\.\\d+)$') %}
{% if match and match[0] not in found_pythons %}
{% do found_pythons.append(match[0]) %}
{% endif %}
{% endfor %}

print_found_pythons:
  test.succeed_without_changes:
    - name: "Found python versions: {{ found_pythons | join(', ') }}."

# Identify the unintended versions
{% set unintended_pythons = found_pythons | reject('in', allowed_pythons) | list %}
{% if unintended_pythons != [] %}
check_unintended_pythons:
  test.fail_without_changes:
    - name: "Unintended Python interpreter {{ unintended_pythons | join(', ') }} found on the image (allowed: {{ allowed_pythons | join(', ') }}). Remove them, or install it deliberately with a psycopg2 driver and add it to the allowlist."
{% endif %}

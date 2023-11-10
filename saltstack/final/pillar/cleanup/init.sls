package_versions: {{ salt['environ.get']('PACKAGE_VERSIONS')  | default('', True) }}

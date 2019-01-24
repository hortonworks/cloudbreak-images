subtype: {{ salt['grains.get']('virtual_subtype') | default('', True) }}
package_versions: {{ salt['environ.get']('PACKAGE_VERSIONS')  | default('', True) }}

os_user: {{ salt['environ.get']('OS_USER') }}
subtype: {{ salt['grains.get']('virtual_subtype') | default('', True) }}
subtype: {{ salt['grains.get']('virtual_subtype') | default('', True) }}

PARCELS_ROOT: {{ salt['environ.get']('PARCELS_ROOT') | default('/opt/cloudera/parcels', True) }}  
PARCELS_NAME: {{ salt['environ.get']('PARCELS_NAME', "") }}
PRE_WARM_PARCELS: '{{ salt['environ.get']('PRE_WARM_PARCELS', "[]") }}'
PRE_WARM_CSD: '{{ salt['environ.get']('PRE_WARM_CSD', "[]") }}'
PRE_WARM_RPMS: '{{ salt['environ.get']('PRE_WARM_RPMS', "[]") }}'

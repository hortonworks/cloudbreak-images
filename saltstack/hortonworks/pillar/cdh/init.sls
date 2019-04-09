PARCELS_ROOT: {{ salt['environ.get']('PARCELS_ROOT') | default('/opt/cloudera/parcels', True) }}  
PARCELS_NAME: {{ salt['environ.get']('PARCELS_NAME', "") }}

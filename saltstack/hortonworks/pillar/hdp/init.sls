STACK_TYPE: {{ salt['environ.get']('STACK_TYPE', "HDP") }}
STACK_VERSION: {{ salt['environ.get']('STACK_VERSION', False) }}
STACK_BASEURL: {{ salt['environ.get']('STACK_BASEURL', False) }}
STACK_REPOID: {{ salt['environ.get']('STACK_REPOID', False) }}
MPACK_URLS: {{ salt['environ.get']('MPACK_URLS', "") }}
STACK_REPOSITORY_VERSION: {{ salt['environ.get']('STACK_REPOSITORY_VERSION', False) }}
VDF: {{ salt['environ.get']('VDF', False) }}
CLUSTERMANAGER_VERSION: {{ salt['environ.get']('CLUSTERMANAGER_VERSION', False) }}
CLUSTERMANAGER_BASEURL: {{ salt['environ.get']('CLUSTERMANAGER_BASEURL', False) }}
CLUSTERMANAGER_GPGKEY: {{ salt['environ.get']('CLUSTERMANAGER_GPGKEY', False) }}
OS: {{ salt['environ.get']('OS', False) }}
LOCAL_URL_AMBARI: {{ salt['environ.get']('LOCAL_URL_AMBARI', False) }}
LOCAL_URL_HDP: {{ salt['environ.get']('LOCAL_URL_HDP', False) }}
LOCAL_URL_HDP_UTILS: {{ salt['environ.get']('LOCAL_URL_HDP_UTILS', False) }}
LOCAL_URL_VDF: {{ salt['environ.get']('LOCAL_URL_VDF', False) }}
REPOSITORY_TYPE : {{ salt['environ.get']('REPOSITORY_TYPE', "remote") }}
PRE_WARM_PARCELS: '{{ salt['environ.get']('PRE_WARM_PARCELS', "[]") }}'
PRE_WARM_CSD: '{{ salt['environ.get']('PRE_WARM_CSD', "[]") }}'

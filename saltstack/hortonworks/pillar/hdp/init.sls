STACK_TYPE: {{ salt['environ.get']('STACK_TYPE', "HDP") }}
HDP_STACK_VERSION: {{ salt['environ.get']('HDP_STACK_VERSION', False) }}
HDP_VERSION: {{ salt['environ.get']('HDP_VERSION', False) }}
HDP_BASEURL: {{ salt['environ.get']('HDP_BASEURL', False) }}
HDP_REPOID: {{ salt['environ.get']('HDP_REPOID', False) }}
MPACK_URLS: {{ salt['environ.get']('MPACK_URLS') }}
REPOSITORY_VERSION: {{ salt['environ.get']('REPOSITORY_VERSION', False) }}
VDF: {{ salt['environ.get']('VDF', False) }}
AMBARI_VERSION: {{ salt['environ.get']('AMBARI_VERSION', False) }}
OS: {{ salt['environ.get']('OS', False) }}
LOCAL_URL_AMBARI: {{ salt['environ.get']('LOCAL_URL_AMBARI', False) }}
LOCAL_URL_HDP: {{ salt['environ.get']('LOCAL_URL_HDP', False) }}
LOCAL_URL_HDP_UTILS: {{ salt['environ.get']('LOCAL_URL_HDP_UTILS', False) }}
LOCAL_URL_VDF: {{ salt['environ.get']('LOCAL_URL_VDF', False) }}
REPOSITORY_TYPE : {{ salt['environ.get']('REPOSITORY_TYPE', "remote") }}

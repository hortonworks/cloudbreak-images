AMBARI_VERSION: {{ salt['environ.get']('AMBARI_VERSION', False) }}
AMBARI_BASEURL: {{ salt['environ.get']('AMBARI_BASEURL', False) }}
AMBARI_GPGKEY: {{ salt['environ.get']('AMBARI_GPGKEY', False) }}

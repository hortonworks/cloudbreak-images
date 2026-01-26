include:
  - {{ slspath }}.always-pass
  - {{ slspath }}.rpms
{% if pillar['CLUSTERMANAGER_VERSION'] and pillar['CLUSTERMANAGER_BASEURL'] and pillar['CLUSTERMANAGER_GPGKEY'] %}
  - {{ slspath }}.cm
    {% if pillar['STACK_VERSION'] and  pillar['STACK_BASEURL'] and  pillar['STACK_REPOID'] %}
  - {{ slspath }}.cdh
    {% endif %}
    {% if 'STREAMS_MESSAGING_MANAGER' in pillar['PRE_WARM_CSD'] %}
  - {{ slspath }}.node
    {% endif %}
  - {{ slspath }}.parcels
  - {{ slspath }}.torrent
{% endif %}
  
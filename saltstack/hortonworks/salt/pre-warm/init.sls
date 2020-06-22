include:
  - {{ slspath }}.always-pass
{% if pillar['STACK_TYPE'] == 'CDH' %}
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
{% elif pillar['STACK_TYPE'] == 'HDP' or  pillar['STACK_TYPE'] == 'HDF' %}
  {% if pillar['CLUSTERMANAGER_VERSION'] and pillar['CLUSTERMANAGER_BASEURL'] and pillar['CLUSTERMANAGER_GPGKEY'] %}
  - {{ slspath }}.ambari
  - {{ slspath }}.smartsense
    {% if pillar['STACK_VERSION'] and  pillar['STACK_BASEURL'] and  pillar['STACK_REPOID'] %}
  - {{ slspath }}.hdp
    {% endif %}
  {% endif %}
{% endif %}

include:
  - {{ slspath }}.always-pass
  - {{ slspath }}.cm
  - {{ slspath }}.cdh
    {% if 'STREAMS_MESSAGING_MANAGER' in pillar['PRE_WARM_CSD'] %}
  - {{ slspath }}.node
    {% endif %}
  - {{ slspath }}.parcels
  - {{ slspath }}.torrent

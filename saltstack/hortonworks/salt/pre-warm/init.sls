include:
  - {{ slspath }}.always-pass
{% if grains['os_family'] == 'RedHat' %}
  {% if pillar['AMBARI_VERSION'] and pillar['AMBARI_BASEURL'] and pillar['AMBARI_GPGKEY'] %}
  - {{ slspath }}.ambari
  - {{ slspath }}.smartsense
    {% if  pillar['HDP_STACK_VERSION'] and  pillar['HDP_VERSION'] and  pillar['HDP_BASEURL'] and  pillar['HDP_REPOID'] %}
  - {{ slspath }}.hdp
    {% endif %}
  {% endif %}
{% endif %}

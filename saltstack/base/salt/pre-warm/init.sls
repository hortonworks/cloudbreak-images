always-pass:
  test.succeed_without_changes

{% if grains['os_family'] == 'RedHat' %}
  {% if pillar['AMBARI_VERSION'] and pillar['AMBARI_BASEURL'] and pillar['AMBARI_GPGKEY'] %}
include:
  - {{ slspath }}.ambari
  - {{ slspath }}.smartsense
  {% endif %}
  {% if  pillar['HDP_STACK_VERSION'] and  pillar['HDP_VERSION'] and  pillar['HDP_BASEURL'] and  pillar['HDP_REPOID'] %}
  - {{ slspath }}.hdp
  {% endif %}
{% endif %}

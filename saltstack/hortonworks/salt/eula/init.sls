{% if pillar['HDP_VERSION'] %}
copy_eula:
  file.recurse:
    - name: /etc/hortonworks/
    - source: salt://{{ slspath }}/etc/hortonworks/
    - include_empty: True

{% if pillar['COPY_AWS_MARKETPLACE_EULA'] %}
remove_tp_eulas:
  cmd.run:
    - name: rm -f /etc/hortonworks/hdcloud*technical-preview*
{% else %}
remove_marketplace_eulas:
  cmd.run:
    - name: rm -f /etc/hortonworks/hdcloud*marketplace*
{% endif %}

{% if '2.5' in pillar['HDP_VERSION'] %}
remove_hdp26_eulas:
  cmd.run:
    - name: rm -f /etc/hortonworks/hdcloud*hdp26*
{% else %}
remove_hdp25_eulas:
  cmd.run:
    - name: rm -f /etc/hortonworks/hdcloud*hdp25*
{% endif %}

{% endif %}
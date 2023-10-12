final:
  '*':
{% if pillar['CUSTOM_IMAGE_TYPE'] == 'hortonworks' or pillar['OPTIONAL_STATES'] == 'oracle-java' %}
    - validate
{% endif %}
{% if salt['file.file_exists']('/etc/waagent.conf') %}
    - waagent
{% endif %}
    - krb5
    - metadata
{% if pillar['subtype'] != 'Docker' %}
    - cis-controls
{% endif %}
    - cleanup

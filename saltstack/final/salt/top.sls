final:
  '*':
{% if pillar['CUSTOM_IMAGE_TYPE'] == 'hortonworks' %}
    - validate
{% endif %}
{% if salt['file.file_exists']('/etc/waagent.conf') %}
    - waagent
{% endif %}
    - krb5
    - metadata
{% if pillar['subtype'] != 'Docker'  %}
    - cis-controls
{% if salt['environ.get']('OSCAP_SCAN_ENABLED') == 'true' %}
    - openscap
{% endif %}
{% endif %}
    - cleanup
    - hacks-and-tweaks

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
{% if pillar['subtype'] != 'Docker' and salt['environ.get']('OS') != 'redhat9' %}
    - cis-controls
{% if salt['environ.get']('STIG_ENABLED') == 'true' %}
    - openscap
{% endif %}
{% endif %}
    - cleanup
    - hacks-and-tweaks

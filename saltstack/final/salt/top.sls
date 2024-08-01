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
{% if pillar['subtype'] != 'Docker' %}
    - cis-controls
{% if salt['environ.get']('STIG_ENABLED') == 'true' %}
    - openscap
{% endif %}
{% endif %}
    - cleanup
# This could be removed (proably along with the whole Psycopg2 stuff!) once CDPD-71074 gets delivered to 7.2.18 and above
{% if salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' %}
    - hue-hack
{% endif %}

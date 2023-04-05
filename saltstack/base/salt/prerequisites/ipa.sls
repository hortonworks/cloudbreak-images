{% if grains['os_family'] == 'RedHat' and grains['osmajorrelease'] | int == 8 %}
patch_ipa_constants_hostname:
  file.patch:
    - name: /usr/lib/python3.6/site-packages/ipalib/constants.py
    - source: salt://{{ slspath }}/ipa-constants.patch
{% endif %}
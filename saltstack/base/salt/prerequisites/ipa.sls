{% if pillar['OS'] == 'redhat8' %}
patch_ipa_constants_hostname:
  file.patch:
    - name: /usr/lib/python3.6/site-packages/ipalib/constants.py
    - source: salt://{{ slspath }}/ipa-constants-py3.6.patch
{% elif pillar['OS'] == 'redhat9' %}
patch_ipa_constants_hostname:
  file.patch:
    - name: /usr/lib/python3.9/site-packages/ipalib/constants.py
    - source: salt://{{ slspath }}/ipa-constants-py3.9.patch
{% endif %}
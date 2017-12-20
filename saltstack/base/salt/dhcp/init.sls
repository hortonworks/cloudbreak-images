/etc/dhcp:
  file.recurse:
    - source: salt://{{ slspath }}/etc/dhcp/
    - include_empty: True
    - file_mode: 755

/etc/NetworkManager:
  file.recurse:
    - source: salt://{{ slspath }}/etc/NetworkManager/
    - file_mode: 755
    - include_empty: True

{% set subtype = grains['virtual_subtype'] |default('', true) %}
{% if subtype == 'Docker' %}
/etc/resolv.conf:
  file.managed:
    - name: /etc/resolv.conf.ycloud
    - source: salt://{{ slspath }}/etc/resolv.conf.ycloud
{% endif %}

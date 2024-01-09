/etc/dhcp:
  file.recurse:
    - source: salt://{{ slspath }}/etc/dhcp/
    - template: jinja
    - include_empty: True
    - file_mode: 755

/etc/NetworkManager:
  file.recurse:
    - source: salt://{{ slspath }}/etc/NetworkManager/
    - file_mode: 755
    - include_empty: True

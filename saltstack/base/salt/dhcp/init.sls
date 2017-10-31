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
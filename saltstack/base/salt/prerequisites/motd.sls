/etc/motd:
  file.managed:
    - source: salt://{{ slspath }}/etc/motd
    - mode: 644

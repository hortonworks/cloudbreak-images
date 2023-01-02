/etc/profile.d/timeout.sh:
  file.managed:
    - user: root
    - group: root
    - source:
      - salt://{{ slspath }}/etc/profile.d/timeout.sh
    - mode: 755

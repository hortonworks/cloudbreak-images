/etc/profile.d/umask.sh:
  file.managed:
    - user: root
    - group: root
    - source:
      - salt://{{ slspath }}/etc/profile.d/umask.sh
    - mode: 755

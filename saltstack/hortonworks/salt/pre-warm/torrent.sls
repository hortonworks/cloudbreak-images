create_torrent:
  cmd.script:
    - name: salt://pre-warm/tmp/create_torrent.sh
    - output_loglevel: DEBUG
    - timeout: 9000
    - unless: ls /tmp/create_torrent.status
    - failhard: True

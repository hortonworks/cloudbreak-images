install_autossh:
  cmd.script:
    - name: salt://autossh/install_autossh.sh
    - output_loglevel: DEBUG
    - timeout: 9000
    - failhard: True

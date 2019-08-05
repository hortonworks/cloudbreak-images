nodejs:
  pkg.installed

forever:
  cmd.run:
    - name: |
        npm install -g forever
        chmod -R o+rX /usr/lib/node_modules/forever
    - timeout: 9000
    - failhard: True
    - require:
      - pkg: nodejs
install_checkipaconsistency:
  pip.installed:
    - name: checkipaconsistency==2.7.10

check-parent-folder:
  cmd.run:
    - name: ls -la /usr/local/lib/python3.8/site-packages

/usr/local/lib/python3.8/site-packages/checkipaconsistency/main.py:
  file.managed:
    - name: /usr/local/lib/python3.8/site-packages/checkipaconsistency/main.py
    - source: salt://{{ slspath }}/scripts/main.py
    - mode: 644
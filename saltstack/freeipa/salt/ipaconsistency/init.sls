install_checkipaconsistency:
  pip.installed:
    - name: checkipaconsistency==2.7.10

/usr/local/lib/python3.6/site-packages/checkipaconsistency/main.py:
  file.managed:
    - name: /usr/local/lib/python3.6/site-packages/checkipaconsistency/main.py
    - source: salt://{{ slspath }}/scripts/main.py
    - mode: 644
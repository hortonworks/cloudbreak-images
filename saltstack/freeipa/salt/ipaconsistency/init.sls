/usr/local/lib/python3.8/site-packages/checkipaconsistency/main.py:
  file.managed:
    - name: /usr/local/lib/python3.8/site-packages/checkipaconsistency/main.py
    - source: salt://{{ slspath }}/scripts/main.py
    - mode: 644
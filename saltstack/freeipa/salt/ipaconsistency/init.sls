# CentOS 7 / RHEL 7 / RHEL 8 + Python 3.6
/usr/local/lib/python3.6/site-packages/checkipaconsistency/main.py:
  file.managed:
    - name: /usr/local/lib/python3.6/site-packages/checkipaconsistency/main.py
    - source: salt://{{ slspath }}/scripts/main.py
    - mode: 644
    - onlyif: ls -la /usr/local/lib/python3.6/site-packages/

# RHEL 8 + Python 3.8
/usr/local/lib/python3.8/site-packages/checkipaconsistency/main.py:
  file.managed:
    - name: /usr/local/lib/python3.8/site-packages/checkipaconsistency/main.py
    - source: salt://{{ slspath }}/scripts/main.py
    - mode: 644
    - onlyif: ls -la /usr/local/lib/python3.8/site-packages/

# CentOS 7 + Python 3.8
/opt/rh/rh-python38//usr/local/lib/python3.8/site-packages/checkipaconsistency/main.py:
  file.managed:
    - name: /opt/rh/rh-python38//usr/local/lib/python3.8/site-packages/checkipaconsistency/main.py
    - source: salt://{{ slspath }}/scripts/main.py
    - mode: 644
    - onlyif: ls -la /opt/rh/rh-python38//usr/local/lib/python3.8/site-packages/
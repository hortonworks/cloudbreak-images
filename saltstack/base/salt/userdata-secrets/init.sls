/usr/bin/cdp-retrieve-userdata-secrets.sh:
  file.managed:
    - name: /usr/bin/cdp-retrieve-userdata-secrets.sh
    - source: salt://{{ slspath }}/bin/cdp-retrieve-userdata-secrets.sh
    - user: root
    - group: root
    - mode: 700

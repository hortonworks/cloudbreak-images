/cdp/bin/reverse-tunnel.sh:
  file.managed:
    - name: /cdp/bin/reverse-tunnel.sh
    - source: salt://{{ slspath }}/cdp/bin/reverse-tunnel.sh

/cdp/bin/reverse-tunnel-values.sh:
  file.managed:
    - name: /cdp/bin/reverse-tunnel-values.sh
    - source: salt://{{ slspath }}/cdp/bin/reverse-tunnel-values.sh

/cdp/bin/update-reverse-tunnel-values.sh:
  file.managed:
    - name: /cdp/bin/update-reverse-tunnel-values.sh
    - source: salt://{{ slspath }}/cdp/bin/updatereverse-tunnel-values.sh

/systemd/tunnel@.service:
  file.managed:
    - name: /systemd/tunnel@.service
    - source: salt://{{ slspath }}/systemd/tunnel@.service

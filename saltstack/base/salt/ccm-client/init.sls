/cdp/bin/reverse-tunnel.sh:
  file.managed:
    - name: /cdp/bin/reverse-tunnel.sh
    - makedirs: True
    - source: salt://{{ slspath }}/cdp/bin/reverse-tunnel.sh

/cdp/bin/reverse-tunnel-values.sh:
  file.managed:
    - name: /cdp/bin/reverse-tunnel-values.sh
    - makedirs: True
    - source: salt://{{ slspath }}/cdp/bin/reverse-tunnel-values.sh

/cdp/bin/update-reverse-tunnel-values.sh:
  file.managed:
    - name: /cdp/bin/update-reverse-tunnel-values.sh
    - makedirs: True
    - source: salt://{{ slspath }}/cdp/bin/update-reverse-tunnel-values.sh

/systemd/tunnel@.service:
  file.managed:
    - name: /systemd/tunnel@.service
    - makedirs: True    
    - source: salt://{{ slspath }}/systemd/tunnel@.service

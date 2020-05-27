/cdp/bin/reverse-tunnel.sh:
  file.managed:
    - name: /cdp/bin/reverse-tunnel.sh
    - makedirs: True
    - source: salt://{{ slspath }}/cdp/bin/reverse-tunnel.sh
    - mode: 740

/cdp/bin/reverse-tunnel-values.sh:
  file.managed:
    - name: /cdp/bin/reverse-tunnel-values.sh
    - makedirs: True
    - source: salt://{{ slspath }}/cdp/bin/reverse-tunnel-values.sh
    - mode: 740

/cdp/bin/update-reverse-tunnel-values.sh:
  file.managed:
    - name: /cdp/bin/update-reverse-tunnel-values.sh
    - makedirs: True
    - source: salt://{{ slspath }}/cdp/bin/update-reverse-tunnel-values.sh
    - mode: 740

/etc/systemd/system/ccm-tunnel@.service:
  file.managed:
    - name: /etc/systemd/system/ccm-tunnel@.service
    - makedirs: True    
    - source: salt://{{ slspath }}/etc/systemd/system/ccm-tunnel@.service

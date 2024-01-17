stop_and_disable_dnsmasq:
  service.dead:
    - enable: False
    - name: dnsmasq

install_smartsense:
  pkg.installed:
    - name: smartsense-hst

disable_smartsense_hst:
  service.disabled:
    - name: hst
    - require:
      - pkg: install_smartsense

disable_smartsense_hst_gateway:
  service.disabled:
    - name: hst-gateway
    - require:
      - pkg: install_smartsense
add_cis_control_sh:
  file.managed:
    - name: /tmp/cis_control.sh
    - makedirs: True
    - mode: 755
    - source: salt://cis-controls/scripts/cis_control.sh

execute_cis_control_sh:
  cmd.run:
    - name: /tmp/cis_control.sh
    - env:
      - IMAGE_BASE_NAME: {{ salt['environ.get']('IMAGE_BASE_NAME') }}
      - CLOUD_PROVIDER: {{ salt['environ.get']('CLOUD_PROVIDER') }}

remove_cis_control_sh:
  file.absent:
    - name: /tmp/cis_control.sh

# Additional states to cover violations not fixed by AutomateCompliance

blacklist_cramfs:
  file.replace:
    - name: /etc/modprobe.d/salt_cis.conf
    - pattern: "^blacklist cramfs"
    - repl: "blacklist cramfs"
    - append_if_not_found: True

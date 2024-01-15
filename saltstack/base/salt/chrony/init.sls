{% if pillar['OS'] == 'redhat8' %}
chronyReinstall:
  cmd.run:
    - name: dnf reinstall chrony -y
{% endif %}

chronyRestart:
  file.line:
    - name: /usr/lib/systemd/system/chronyd.service
    - mode: ensure
    - content: "Restart=always"
    - after: \[Service\]
    - backup: False

chronyRestartSec:
  file.line:
    - name: /usr/lib/systemd/system/chronyd.service
    - mode: ensure
    - content: "RestartSec=5"
    - after: "Restart=always"
    - backup: False
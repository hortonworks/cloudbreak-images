10periodic:
  file.replace:
    - name: /etc/apt/apt.conf.d/10periodic
    - pattern: "^APT::Periodic::Update-Package-Lists \"1\";"
    - repl: "APT::Periodic::Update-Package-Lists \"0\";"
    - append_if_not_found: True

{% if grains['osfinger'] != 'Ubuntu-14.04' %}
20auto-upgrades-1:
  file.replace:
    - name: /etc/apt/apt.conf.d/20auto-upgrades
    - pattern: "^APT::Periodic::Update-Package-Lists \"1\";"
    - repl: "APT::Periodic::Update-Package-Lists \"0\";"
    - append_if_not_found: True

20auto-upgrades-2:
  file.replace:
    - name: /etc/apt/apt.conf.d/20auto-upgrades
    - pattern: "^APT::Periodic::Unattended-Upgrade \"1\";"
    - repl: "APT::Periodic::Unattended-Upgrade \"0\";"
    - append_if_not_found: True
{% endif %}

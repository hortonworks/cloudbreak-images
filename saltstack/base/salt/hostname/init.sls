{% if salt['environ.get']('CLOUD_PROVIDER') == 'GCP' %}
# GCP overrides the hostname each time the network goes up (e.g. startup) and this messes up our hostname confifuration so it should be removed
remove-gcp-NetworkManager-hostname-override:
  file.absent:
    - name: /etc/NetworkManager/dispatcher.d/google_hostname.sh

remove-gcp-dhcp-hostname-override:
  file.absent:
    - name: /etc/dhcp/dhclient.d/google_hostname.sh

create_google_guest_agent_override_dir:
  file.directory:
    - name: /etc/systemd/system/google-guest-agent.service.d
    - makedirs: True
    - mode: 0755

add_google_guest_agent_override:
  file.managed:
    - name: /etc/systemd/system/google-guest-agent.service.d/override.conf
    - source:
      - salt://{{ slspath }}/etc/systemd/system/google-guest-agent.service.d/override.conf
    - mode: 0644
    - require:
      - file: create_google_guest_agent_override_dir

add_cleanup_hosts_sh:
  file.managed:
    - name: /usr/local/bin/cleanup-hosts.sh
    - source:
      - salt://{{ slspath }}/usr/local/bin/cleanup-hosts.sh
    - mode: 0755
    - require:
      - file: create_google_guest_agent_override_dir

reload_systemd:
  cmd.run:
    - name: systemctl daemon-reload
    - require:
      - file: add_google_guest_agent_override
{% endif %}
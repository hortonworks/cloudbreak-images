install_salt_components:
  pkg.installed:
    - pkgs:
      - salt-master
      - salt-api

ensure_salt-master_is_dead:
  service.dead:
    - name: salt-master

ensure_salt-master_is_disabled:
  service.disabled:
    - name: salt-master

ensure_salt-minion_is_dead:
  service.dead:
    - name: salt-minion

ensure_salt-minion_is_disabled:
  service.disabled:
    - name: salt-minion

/etc/salt:
  file.recurse:
    - source: salt://{{ slspath }}/etc/salt
    - include_empty: True

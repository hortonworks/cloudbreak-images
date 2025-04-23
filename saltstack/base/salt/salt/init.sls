/etc/salt:
  file.recurse:
    - source: salt://{{ slspath }}/etc/salt
    - template: jinja
    - include_empty: True

create_saltmaster_service_file:
  file.managed:
    - user: root
    - group: root
    - template: jinja
    - name: /etc/systemd/system/salt-master.service
    - source: salt://{{ slspath }}/etc/systemd/system/salt-master.service

/opt/salt/scripts/salt-master-wrapper.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
    - template: jinja
    - name: /opt/salt/scripts/salt-master-wrapper.sh
    - source: salt://{{ slspath }}/opt/salt/scripts/salt-master-wrapper.sh

create_saltapi_service_file:
  file.managed:
    - user: root
    - group: root
    - template: jinja
    - name: /etc/systemd/system/salt-api.service
    - source: salt://{{ slspath }}/etc/systemd/system/salt-api.service

/opt/salt/scripts/salt-api-wrapper.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
    - template: jinja
    - name: /opt/salt/scripts/salt-api-wrapper.sh
    - source: salt://{{ slspath }}/opt/salt/scripts/salt-api-wrapper.sh

create_saltminion_service_file:
  file.managed:
    - user: root
    - group: root
    - template: jinja
    - name: /etc/systemd/system/salt-minion.service
    - source: salt://{{ slspath }}/etc/systemd/system/salt-minion.service

/opt/salt/scripts/salt-minion-wrapper.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
    - template: jinja
    - name: /opt/salt/scripts/salt-minion-wrapper.sh
    - source: salt://{{ slspath }}/opt/salt/scripts/salt-minion-wrapper.sh

create_bin_for_activate_virtualenv:
  file.managed:
  - user: root
  - group: root
  - template: jinja
  - mode: 755
  - name: /usr/bin/activate_salt_env
  - source:
      - salt://{{ slspath }}/bin/activate_salt_env
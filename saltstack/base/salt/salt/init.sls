{% if grains['os_family'] == 'Suse' %}
/etc:
  file.recurse:
    - source: salt://{{ slspath }}/etc
    - template: jinja
    - include_empty: True
    
{% else %}

/etc/salt:
  file.recurse:
    - source: salt://{{ slspath }}/etc/salt
    - template: jinja
    - include_empty: True

{% endif %}

create_saltmaster_service_file:
  file.managed:
    - user: root
    - group: root
    - template: jinja
{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
    - name: /etc/init.d/salt-master
    - source:
      - salt://{{ slspath }}/etc/init.d/salt-master
    - mode: 755
{% elif grains['init'] == 'systemd' %}
    - name: /etc/systemd/system/salt-master.service
    - source: salt://{{ slspath }}/etc/systemd/system/salt-master.service
{% endif %}

create_saltapi_service_file:
  file.managed:
    - user: root
    - group: root
    - template: jinja
{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
    - name: /etc/init.d/salt-api
    - source:
      - salt://{{ slspath }}/etc/init.d/salt-api
    - mode: 755
{% elif grains['init'] == 'systemd' %}
    - name: /etc/systemd/system/salt-api.service
    - source: salt://{{ slspath }}/etc/systemd/system/salt-api.service
{% endif %}

create_saltminion_service_file:
  file.managed:
    - user: root
    - group: root
    - template: jinja
{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
    - name: /etc/init.d/salt-minion
    - source:
      - salt://{{ slspath }}/etc/init.d/salt-minion
    - mode: 755
{% elif grains['init'] == 'systemd' %}
    - name: /etc/systemd/system/salt-minion.service
    - source: salt://{{ slspath }}/etc/systemd/system/salt-minion.service
{% endif %}

create_bin_for_activate_virtualenv:
  file.managed:
  - user: root
  - group: root
  - template: jinja
  - mode: 755
  - name: /usr/bin/activate_salt_env
  - source:
      - salt://{{ slspath }}/bin/activate_salt_env
{% if grains['os_family'] == 'RedHat' %}
{% if grains['osmajorrelease'] | int == 7 %}
set_faillock_args:
  file.replace:
    - name: /etc/sysconfig/authconfig
    - pattern: "^FAILLOCKARGS=.*"
    - repl: 'FAILLOCKARGS="audit deny=3 unlock_time=900"'
    - append_if_not_found: True

enable_faillock:
  file.replace:
    - name: /etc/sysconfig/authconfig
    - pattern: "^USEFAILLOCK=.*"
    - repl: 'USEFAILLOCK=yes'
    - append_if_not_found: True
{% endif %}
{% if grains['osmajorrelease'] | int == 8 %}
/etc/security/faillock.conf:
  file.managed:
    - user: root
    - group: root
    - source:
      - salt://{{ slspath }}/etc/security/faillock.conf
    - mode: 644

select-profile:
  cmd.run:
    - name: authselect select sssd --force

enable-faillock:
  cmd.run:
    - name: authselect enable-feature with-faillock
{% endif %}
{% endif %}
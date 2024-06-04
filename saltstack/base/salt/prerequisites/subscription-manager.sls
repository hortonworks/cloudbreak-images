{% if grains['os_family'] == 'RedHat' %}
disable_redhat_subscription-manager:
  file.replace:
    - name: /etc/dnf/plugins/subscription-manager.conf
    - pattern: '^enabled=[0,1]'
    - repl: 'enabled=0'
    - ignore_if_missing: True
{% endif %}

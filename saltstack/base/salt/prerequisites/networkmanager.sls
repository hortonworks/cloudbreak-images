network_manager_config:
{% if grains['builder_type'] == ['azure-arm'] %}
  file.managed:
    - name: /etc/NetworkManager/conf.d/nodnsupdate.conf
    - makedirs: True
    - source: salt://{{ slspath }}/etc/NetworkManager/conf.d/nodnsupdate.conf
    - mode: 740
    - unless: test -f /etc/NetworkManager/conf.d/nodnsupdate.conf
{% else %}
  test.succeed_without_changes
{% endif %}

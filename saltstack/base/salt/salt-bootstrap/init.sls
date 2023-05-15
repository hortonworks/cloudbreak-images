install_saltbootstrap:
  archive.extracted:
    - name: /usr/sbin/
#    - source: https://github.com/hortonworks/salt-bootstrap/releases/download/v0.13.6/salt-bootstrap_0.13.6_Linux_{{ grains['osarch'] }}.tgz
    - source: https://cb-group.s3.eu-central-1.amazonaws.com/dbajzath/sb.tgz?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEAIaDGV1LWNlbnRyYWwtMSJGMEQCIB4NxgTTNhIJr30l65jsztGKZXBMKvPHepMoVva9gSTLAiAB8hb%2FsFo4us7lLf2nQRXqe%2Ft49Wl%2Fm%2F686IDw%2BzQE9CqfAwgrEAMaDDE1MjgxMzcxNzcyOCIMYyZLKE0g8WVCBE2BKvwCwlbIF8r0kc%2FRiyuLrNZpiRwdkrGGlPBp7abvtniOGzR6zCeJdftWaB9LDpiTFgFnpZiuhz4MVms2O8r%2FOo4Jq9DrqTiMYrKItA78Ncn92MQBKKALfoWu%2Bf5nA3EA7GqKRa%2BNU6V898INNVgA0tsW2XRaOM8LEceHcRys2WznsEH9DvA%2BgoNzSrixrvDfTVOe1PWPjtdynsLinpuXpjgkgewI0pDayBbxJjZN0BcrkA8UwRs1YAMt%2FMm%2F9a9NEViFISdoBSp9AFe9eMzJGO4Po4CSHcV4AOP2f0XStjG%2FSUjCQ5QjgqOvqM6QILH6ayzhXwLTjmoI8sqdUfkd8eeeJ5NgAFZ%2F%2FlvwEo517mvcvHD0DzdH6oP0NhnwK37ugpA1BZsZH9JziryinmgkHaRekr6whxia4reoEY9wgJIqlxWMRUXxGyrOITmzbQhJ5AhgIHaYbUooHzEJzWVqsI3PVV5xGTCiilLS0oBf3%2BxBpKpEGfppmRQm%2F5KHHlowqKKNowY6hQIsKSBZr21F6ycCo6PC0LLElM4pTMDJpqHZBVkfpM11HmHctdyYwDS7jK6tKcN3U9VajUMkHxoiCseN9ZOiJqTJqEyqOkvOHtvJT5kqncOkW3eFWwnBJHN%2BNZwmaOZ0snbr%2BMCxlMEZ9P5PJpEhC7ZzRmZpaewdS6jR%2BQCW5QIVJs%2FFNQLB9LbFO3l2zI7DD798IHP8RMEoiy8ZGMoqYjjti22AivzXnLShjDYRs6zEqrvCnkzCPD6dx2288D6ekVm080%2BXsuTn2Gcu0emqvWYFCXlmoE9ugCfhIZVjloVthyUO%2B7AoB9EhxN2lEPQwKkJfpzElAu9k6FPM%2Bfr7sSeZ%2BR6uDtQ%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20230516T094824Z&X-Amz-SignedHeaders=host&X-Amz-Expires=43200&X-Amz-Credential=ASIASHFDIJDQMFIU3SVC%2F20230516%2Feu-central-1%2Fs3%2Faws4_request&X-Amz-Signature=043841425013d0bd19a63b12606d693283198854ae93202ff65260ebaf66cd89
    - source_hash: md5=f43507b5cc18da05245a52e8f92c8c9b
    - archive_format: tar
    - enforce_toplevel: false
    - user: root
    - group: root
    - skip_verify: True
    - if_missing: /usr/sbin/salt-bootstrap

create_saltbootstrap_service_files:
  file.managed:
    - user: root
    - group: root
{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
    - name: /etc/init.d/salt-bootstrap
    - source:
      - salt://{{ slspath }}/etc/init.d/salt-bootstrap.{{ grains['os_family'] | lower }}
      - salt://{{ slspath }}/etc/init.d/salt-bootstrap
    - mode: 755
{% elif grains['init'] == 'systemd' %}
    - name: /etc/systemd/system/salt-bootstrap.service
    - template: jinja
    - source: salt://{{ slspath }}/etc/systemd/system/salt-bootstrap.service
{% endif %}

salt-bootstrap:
  service.running:
    - enable: True
    - require:
      - install_saltbootstrap
      - create_saltbootstrap_service_files

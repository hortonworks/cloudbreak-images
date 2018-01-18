create_cloudbreak_user:
  user.present:
    - name: cloudbreak
    - fullname: Cloudbreak user
    - shell: /bin/bash
    - password: '!!'
    - groups:
{% if grains['os_family'] == 'Debian' %}
      - sudo
{% else %}
      - wheel
{% endif %}

add_cloudbreak_sudo_access:
  file.managed:
    - name: /etc/sudoers.d/cloudbreak
    - user: root
    - group: root
    - mode: 0440
    - contents:
      - "cloudbreak ALL=(ALL) NOPASSWD:ALL"


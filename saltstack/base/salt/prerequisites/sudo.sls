# No need to grant sudo to OS_USER on Amazon Linux
{% if grains['os_family'] != 'Amazon' %}
os_user_sudoers:
  file.managed:
    - name: "/etc/sudoers.d/{{ pillar['os_user'] }}"
    - mode: 440
    - contents: |
        {{ pillar['os_user'] }} ALL=(ALL) NOPASSWD: ALL
{% endif %}
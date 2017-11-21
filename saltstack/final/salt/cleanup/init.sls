include:
  - {{ slspath }}.authorized_keys
  - {{ slspath }}.fstab
  - {{ slspath }}.hostname
  - {{ slspath }}.package
  - {{ slspath }}.sync_fs
  {% if pillar['os_user'] != "vagrant" %}
  - {{ slspath }}.salt
  {% endif %}
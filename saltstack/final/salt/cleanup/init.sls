include:
  - {{ slspath }}.authorized_keys
  - {{ slspath }}.fstab
  - {{ slspath }}.hostname
  - {{ slspath }}.package
  - {{ slspath }}.sync_fs
  - {{ slspath }}.salt
{% if not salt['file.directory_exists']('/vagrant') %}
  - {{ slspath }}.cloud-init
{% endif %}
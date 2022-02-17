include:
  - {{ slspath }}.generate-package-versions
  - {{ slspath }}.set-skip-repo-if-unavailable
  - {{ slspath }}.authorized_keys
  - {{ slspath }}.fstab
{% if pillar['subtype'] != 'Docker' %}
  - {{ slspath }}.hostname
{% endif %}
  - {{ slspath }}.kernel
  - {{ slspath }}.package
  - {{ slspath }}.sync_fs
  - {{ slspath }}.salt
{% if not salt['file.directory_exists']('/vagrant') %}
  - {{ slspath }}.cloud-init
{% endif %}
  - {{ slspath }}.user

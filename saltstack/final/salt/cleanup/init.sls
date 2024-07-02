include:
  - {{ slspath }}.set-skip-repo-if-unavailable
  - {{ slspath }}.authorized_keys
  - {{ slspath }}.fstab
{% if pillar['subtype'] != 'Docker' %}
  - {{ slspath }}.hostname
  - {{ slspath }}.kernel
{% endif %}
  - {{ slspath }}.package
  - {{ slspath }}.sync_fs
  - {{ slspath }}.salt
{% if not salt['file.directory_exists']('/vagrant') %}
  - {{ slspath }}.cloud-init
{% endif %}
  - {{ slspath }}.mount

storage_usage:
  cmd.run:
    - name: lsblk; df -h

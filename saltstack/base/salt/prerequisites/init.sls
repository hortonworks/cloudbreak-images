include:
  - {{ slspath }}.repository
  - {{ slspath }}.packages
  - {{ slspath }}.sudo
{% if grains['virtual_subtype'] != 'Docker' %}
  - {{ slspath }}.sysctl
  - {{ slspath }}.disable_ipv6
  - {{ slspath }}.selinux
{% endif %}
  - {{ slspath }}.ssh
  - {{ slspath }}.pip
  - {{ slspath }}.cert-tool
  - {{ slspath }}.dnsmasq
  - {{ slspath }}.user

/usr/bin/:
  file.recurse:
    - source: salt://{{ slspath }}/usr/bin/
    - include_empty: True
    - file_mode: 755

/usr/lib/jvm:
  file.recurse:
    - source: salt://{{ slspath }}/usr/lib/jvm/
    - include_empty: True

{% if grains['virtual_subtype'] == 'Docker' %}
adjust_user_data_helper_to_docker:
  file.replace:
    - name: /usr/bin/user-data-helper.sh
    - pattern: '^\s*format_disks\s*$'
    - repl: "# format_disks  # Disabled for docker"
{% endif %}

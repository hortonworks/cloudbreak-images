{% if pillar['OS'] == 'redhat9' and salt['environ.get']('CLOUD_PROVIDER') == 'Azure' %}

install_azure_vm_utils:
  pkg.installed:
    - pkgs:
      - azure-vm-utils

{% endif %}

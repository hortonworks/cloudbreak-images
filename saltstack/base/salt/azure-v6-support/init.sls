{% if pillar['OS'] == 'redhat9' and salt['environ.get']('CLOUD_PROVIDER') == 'Azure' %}

# Note this is a hack, do not push this to production! Testing only.
install_azure_vm_utils:
  pkg.installed:
    - pkgs:
      - azure-vm-utils

{% endif %}

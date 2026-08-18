{% if pillar['OS'] == 'redhat9' and salt['environ.get']('CLOUD_PROVIDER') == 'Azure' %}

# Note this is a hack, do not push this to production! Testing only.
install_azure_vm_utils:
  pkg.installed:
    - sources:
      - azure-vm-utils: https://mirror.eng.cloudera.com/repos/rhel/server/9/9.7/x86_64/appstream/os/Packages/a/azure-vm-utils-0.5.2-1.el9.x86_64.rpm

{% endif %}
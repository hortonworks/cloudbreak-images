fstab_remove_xvdb:
  file.line:
    - name: /etc/fstab
    - mode: delete
    - content: "/dev/xvdb"
    - onlyif: ls /etc/fstab

fstab_remove_azure_resource:
  cmd.run:
    - name: sed -i '/azure_resource-part[0-9][0-9]*/d' /etc/fstab
    - onlyif: grep -qE 'azure_resource-part[0-9]+' /etc/fstab

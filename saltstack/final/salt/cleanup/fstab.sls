fstab_remove_xvdb:
  file.line:
    - name: /etc/fstab
    - mode: delete
    - content: "/dev/xvdb"
    - onlyif: ls /etc/fstab

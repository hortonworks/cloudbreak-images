umount-additional-disk:
  cmd.run:
    - name: umount /mnt/tmp/
    - onlyif: mountpoint /mnt/tmp/

/mnt/tmp:
  file.absent

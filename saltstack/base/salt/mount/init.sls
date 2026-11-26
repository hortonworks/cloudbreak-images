{% if salt['environ.get']('CLOUD_PROVIDER') == "AWS" %}
format-and-mount-additional-disk:
  cmd.run:
    - name: |
        set -euo pipefail
        # Pick the unpartitioned, unmounted whole disk (the extra EBS scratch volume).
        # NVMe device indices are NOT stable on Nitro instances, so never assume
        # /dev/nvme1n1 - the root volume can enumerate there instead (see CB-30406).
        disk=""
        for d in $(lsblk -dno NAME,TYPE | awk '$2=="disk"{print $1}'); do
          if [ -z "$(lsblk -no MOUNTPOINT "/dev/$d" | tr -d '[:space:]')" ] \
             && [ "$(lsblk -no NAME "/dev/$d" | grep -c .)" -eq 1 ]; then
            disk="/dev/$d"; break
          fi
        done
        if [ -z "$disk" ]; then
          echo "ERROR: no free (unpartitioned, unmounted) additional disk found" >&2
          lsblk >&2
          exit 1
        fi
        echo "Using additional disk: $disk"
        mkfs.xfs -f "$disk"
        mkdir -p /mnt/tmp
        mount "$disk" /mnt/tmp/
    - unless: mountpoint -q /mnt/tmp
{% elif salt['environ.get']('CLOUD_PROVIDER') == "GCP" and pillar['OS'] == 'redhat8' %}
format-additional-disk:
  cmd.run:
    - name: mkfs.xfs /dev/sdb

create-additional-disk-mount-point:
  file.directory:
    - name: /mnt/tmp/

mount-additional-disk:
  cmd.run:
    - name: mount /dev/sdb /mnt/tmp/
{% else %}
nop-for-mount-workaround:
  test.nop:
    - name: "NOP - Mount workaround not needed for {{ salt['environ.get']('CLOUD_PROVIDER') }} {{ pillar['OS'] }}"
{% endif %}

add_kernel_cleanup_script:
  file.managed:
    - name: /opt/packer/provision-scripts/kernel/kernel-cleanup.sh
    - mode: 755
    - makedirs: True
    - source: salt://{{ slspath }}/scripts/kernel-cleanup.sh

run_kernel_cleanup_script:
  cmd.run:
    - name: sh -x /opt/packer/provision-scripts/kernel/kernel-cleanup.sh
    - shell: /bin/bash
    - require:
      - file: add_kernel_cleanup_script

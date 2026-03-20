{% if pillar['OS'] == 'centos7' %}
current_kernel:
  cmd.run:
    - name: uname -r

list_installed_kernels_before_cleanup:
  cmd.run:
    - name: rpm -q kernel

package_cleanup_oldkernels:
  cmd.run:
    - name: package-cleanup --oldkernels --count=1 -y

list_installed_kernels_after_cleanup:
  cmd.run:
    - name: rpm -q kernel

{% else %}
add_kernel_cleanup_script:
  file.managed:
    - name: /opt/provision-scripts/kernel/kernel-cleanup.sh
    - mode: 755
    - makedirs: True
    - source: salt://{{ slspath }}/scripts/kernel-cleanup.sh

run_kernel_cleanup_script:
  cmd.run:
    - name: sh -x /opt/provision-scripts/kernel/kernel-cleanup.sh
    - shell: /bin/bash
    - require:
      - file: add_kernel_cleanup_script
{% endif %}

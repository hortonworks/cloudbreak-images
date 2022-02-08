{% if grains['os_family'] == 'RedHat' %}

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

{% endif %}

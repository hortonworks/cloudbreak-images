{% if grains['os_family'] == 'RedHat' %}

current_kernel:
  cmd.run:
    - name: uname -r

list_installed_kernels_before_cleanup:
  cmd.run:
    - name: rpm -q kernel

list_installed_kernels_after_cleanup:
  cmd.run:
    - name: rpm -q kernel

{% endif %}

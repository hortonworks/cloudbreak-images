{% if grains['os_family'] == 'RedHat' %}

current_kernel:
  cmd.run:
    - name: uname -r

list_installed_kernels_before_cleanup:
  cmd.run:
    - name: rpm -q kernel

package_cleanup_oldkernels:
  cmd.run:
{% if pillar['OS'] != 'redhat8' and pillar['OS'] != 'redhat9' %}
    - name: package-cleanup --oldkernels --count=1 -y
{% else %}
    - name: dnf -y remove --oldinstallonly --setopt installonly_limit=2 kernel
    - onlyif: test $(rpm -q kernel | wc -l) -gt 1
{% endif %}

list_installed_kernels_after_cleanup:
  cmd.run:
    - name: rpm -q kernel

{% endif %}

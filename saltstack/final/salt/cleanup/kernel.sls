{% if grains['os_family'] == 'RedHat' %}

current_kernel:
  cmd.run:
    - name: uname -r

list_installed_kernels_before_cleanup:
  cmd.run:
    - name: rpm -q kernel || true

{% if pillar['OS'] != 'redhat8' %}
package_cleanup_oldkernels:
  cmd.run:
    - name: package-cleanup --oldkernels --count=1 -y
{% elif pillar['subtype'] != 'Docker' %}
package_cleanup_oldkernels:
  cmd.run:
    - name: dnf -y remove --oldinstallonly --setopt installonly_limit=2 kernel || true
{% endif %}

list_installed_kernels_after_cleanup:
  cmd.run:
    - name: rpm -q kernel || true

{% endif %}

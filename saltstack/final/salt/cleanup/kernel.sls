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
# We need to exclude RHEL8 arm64 - see comments on CB-31306
{% elif pillar['OS'] != 'redhat8' or salt['environ.get']('ARCHITECTURE') != 'arm64' %}
    - name: dnf -y remove --oldinstallonly --setopt installonly_limit=2 kernel
    - onlyif: test $(rpm -q kernel | wc -l) -gt 1
{% else %}
    - name: echo "Skipping kernel package cleanup for RHEL 8 arm64 image"
{% endif %}

list_installed_kernels_after_cleanup:
  cmd.run:
    - name: rpm -q kernel
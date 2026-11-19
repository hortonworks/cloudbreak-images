final:
  '*':
{% if pillar['IMAGE_TYPE'] != 'freeipa' %}
    - validate
{% endif %}
    - krb5
    - metadata
{% if pillar['subtype'] != 'Docker'  %}
    - cis-controls
# Must run after the reboot provisioner (salt-final.sh) and before the CVE scans,
# so the non-running (old) kernels are gone and the scans report what ships in the image.
    - kernel-cleanup
{% if salt['environ.get']('OSCAP_SCAN_ENABLED') == 'true' %}
    - openscap
{% endif %}
{% if salt['environ.get']('TRIVY_SCAN_ENABLED') == 'true' %}
    - trivy
{% endif %}
{% endif %}
{% if salt['file.file_exists']('/etc/waagent.conf') %}
    - waagent
{% endif %}
    - cleanup
    - hacks-and-tweaks

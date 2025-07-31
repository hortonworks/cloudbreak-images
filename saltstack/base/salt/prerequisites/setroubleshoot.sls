# setroubleshoot breaks SCM group creation on Azure + it is unwanted for CIS compliance

{% if salt['environ.get']('OS') == 'redhat9' or (salt['environ.get']('OS') == 'redhat8' and salt['environ.get']('RHEL_VERSION') == '8.10') and salt['environ.get']('CLOUD_PROVIDER') == 'Azure' %}
remove_setroubleshoot_packages:
  pkg.removed:
    - pkgs:
      - setroubleshoot
      - setroubleshoot-server
      - setroubleshoot-plugins
remove_setroubleshoot_user:
  user.absent:
    - name: setroubleshoot
{% endif %}

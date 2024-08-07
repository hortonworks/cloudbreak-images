# setroubleshoot breaks SCM group creation on Azure + it is unwanted for CIS compliance

{% if salt['environ.get']('OS') == 'redhat8' and salt['environ.get']('RHEL_VERSION') == '8.10' %}
remove_setroubleshoot_packages:
  pkg.removed:
    - pkgs:
      - setroubleshoot
      - setroubleshoot-server
      - setroubleshoot-plugins
remove_setroubleshoot_user:
  cmd.run:
    - name: sudo userdel -f setroubleshoot
{% endif %}

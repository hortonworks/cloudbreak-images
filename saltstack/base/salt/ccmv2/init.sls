{% set jumpgate_agent_rpm_repo_url = salt['environ.get']('JUMPGATE_AGENT_RPM_URL') %}

/cdp/bin/ccmv2/generate-config.sh:
  file.managed:
    - name: /cdp/bin/ccmv2/generate-config.sh
    - makedirs: True
    - source: salt://{{ slspath }}/cdp/bin/ccmv2/generate-config.sh
    - mode: 740

/etc/logrotate.d/ccmv2:
  file.managed:
    - name: /etc/logrotate.d/ccmv2
    - source: salt://{{ slspath }}/etc/logrotate.d/ccmv2
    - user: root
    - group: root
    - mode: 644

<<<<<<< HEAD
{% if jumpgate_agent_rpm_repo_url %}
install_jumpgate_agent:
  pkg.installed:
    - sources:
      - jumpgate-agent: {{ jumpgate_agent_rpm_repo_url }}
{% endif %}
=======
{% set jumpgate_agent_rpm_url = salt['environ.get']('JUMPGATE_AGENT_RPM_URL') %}
{% if jumpgate_agent_rpm_url %}
install_jumpgate_agent:
  pkg.installed:
    - sources:
      - jumpgate-agent: {{ jumpgate_agent_rpm_url }}
    - skip_verify: True
{% endif %}>>>>>>> CDPR-16: Provide jumpgate agent rpm url as an input parameter (#608)

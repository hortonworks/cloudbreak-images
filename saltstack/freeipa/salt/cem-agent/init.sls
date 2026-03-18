{% set cem_agent_rpm_url = salt['environ.get']('CEM_AGENT_RPM_URL') %}

{% if cem_agent_rpm_url %}

install_cem_agent:
  pkg.installed:
    - sources:
      - nifi-minifi-cpp: {{ cem_agent_rpm_url }}

{% endif %}

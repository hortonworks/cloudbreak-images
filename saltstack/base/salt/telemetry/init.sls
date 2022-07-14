{%- set os = salt['environ.get']('OS') %}
include:
{%- if os.startswith("centos") or os.startswith("redhat") or os == "amazonlinux2" %}
  - {{ slspath }}.centos
{%- else %}
  - {{ slspath }}.debian
{%- endif %}
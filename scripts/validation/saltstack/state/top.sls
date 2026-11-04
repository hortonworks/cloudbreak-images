{% set is_freeipa = salt['environ.get']('IMAGE_TYPE') == 'freeipa' %}

validation:
  '*':
    - os
    - python
{% if not is_freeipa %}
    - jdk
{% endif %}

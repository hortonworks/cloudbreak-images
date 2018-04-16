{% if grains['os_family'] == 'Suse' %}
install_salt_components:
  pkg.installed:
    - fromrepo: saltstack-repo
    - pkgs:
      - salt
      - salt-master
      - salt-api

{% else %}

install_salt_components:
  pkg.installed:
    - pkgs:
      - salt-master
      - salt-api

{% endif %}

# TODO (leki75): Debian7 checks service status right after stopping it
# which failes as stopping the service requires some time. Salt from
# 2017.7 has init_delay parameter but Debian7 uses 2016.5 version. As
# the service is disabled it is not necessary to stop services as they
# will not start.

#ensure_salt-master_is_dead:
#  service.dead:
#    - name: salt-master

ensure_salt-master_is_disabled:
  service.disabled:
    - name: salt-master

ensure_salt-minion_is_dead:
  service.dead:
    - name: salt-minion

ensure_salt-minion_is_disabled:
  service.disabled:
    - name: salt-minion

{% if grains['os_family'] == 'Suse' %}

/etc:
  file.recurse:
    - source: salt://{{ slspath }}/etc
    - template: jinja
    - include_empty: True

salt_user_comment:
  file.comment:
    - name: /etc/salt/master
    - regex: ^user.*

salt_syndic_user_comment:
  file.comment:
    - name: /etc/salt/master
    - regex: ^syndic_user.*
    
{% else %}

/etc/salt:
  file.recurse:
    - source: salt://{{ slspath }}/etc/salt
    - template: jinja
    - include_empty: True

{% endif %}
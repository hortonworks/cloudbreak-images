{% if grains['os'] == 'Debian' and grains['osmajorrelease'] | int == 7 %}

install_wheezy_backports_repository:
  pkgrepo.managed:
    - humanname: Wheezy backports components repo
    - name: deb http://ftp.debian.org/debian wheezy-backports main contrib non-free
    - dist: wheezy-backports
    - file: /etc/apt/sources.list.d/wheezy_backports.list
    - gpgcheck: 1

apt_preference_wheezy_backports_repository:
  file.managed:
    - user: root
    - group: root
    - name: /etc/apt/preferences.d/wheezy-backports
    - source: salt://{{ slspath }}/etc/apt/preferences.d/wheezy-backports
    - mode: 644

{% elif grains['os_family'] == 'Suse' %}

register_system:
  cmd.run:
    - name: SUSEConnect -r $SLES_REGISTRATION_CODE
    - unless: '[[ "x${SLES_REGISTRATION_CODE}" != "x" ]] && SUSEConnect -s | grep -q \"Registered\"'

register_sle-sdk:
  cmd.run:
    - name: SUSEConnect -p sle-sdk/12.3/x86_64
    - unless: SUSEConnect -s | grep -q \"sle-sdk\"

{% endif %}

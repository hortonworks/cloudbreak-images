
{% if pillar['OS'] == 'amazonlinux2' or ( grains['os_family'] == 'RedHat' and grains['osmajorrelease'] | int == 7 ) %}
/etc/yum.repos.d/pgdg10.repo:
  file.managed:
    - source: salt://postgresql/yum/postgres10-el7.repo

/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-10:
  file.managed:
    - source: salt://postgresql/yum/pgdg10-gpg
{% endif %}

{% if pillar['OS'] == 'redhat8' %}
install-postgres:
  pkg.installed:
    - pkgs:
      - postgresql: 10*
      - postgresql-server: 10*
      - postgresql-contrib: 10*
      - postgresql-docs: 10*
      - postgresql-jdbc

{% elif grains['os_family'] == 'RedHat' and grains['osmajorrelease'] | int == 7  %}
install-postgres:
  pkg.installed:
    - pkgs:
      - postgresql10-server
      - postgresql-jdbc
      - postgresql10
      - postgresql10-contrib
      - postgresql10-docs
      - postgresql10-devel

{% elif grains['os_family'] == 'Debian' %}
install-postgres:
  pkg.installed:
    - pkgs:
      - postgresql
      - postgresql-client
      - libpostgresql-jdbc-java
{% elif grains['os_family'] == 'Suse' %}
install-postgres:
  pkg.installed:
    - pkgs:
      - postgresql10
      - postgresql-init
      - postgresql10-server
      - postgresql10-contrib
      - postgresql10-docs
      - postgresql10-devel
      - postgresql-jdbc
{% else %}
remove-old-postgres:
  pkg.removed:
    - pkgs:
      - postgresql92-server-compat
      - postgresql92-server
      - postgresql92
      - postgresql92-libs
      - postgresql-server
      - postgresql-libs
      - postgresql

ensure-postgres-home:
  user.present:
    - name: postgres
    - home: /var/lib/pgsql

remove-postgres-sysconfig:
  file.absent:
    - name: /etc/sysconfig/pgsql/postgresql

install-postgres:
  pkg.installed:
    - pkgs:
      - postgresql10-server
      - postgresql10-contrib
      - postgresql10-docs
      - postgresql10-devel
      - postgresql-jdbc
      - postgresql10

{% if  pillar['OS'] != 'amazonlinux2' %}
/etc/init.d/postgresql:
  file.symlink:
      - target: /etc/init.d/postgresql-10
      - force: True
{% endif %}
{% endif %}

{% if  pillar['OS'] != 'redhat8' %}
/usr/bin/initdb:
  file.symlink:
    - mode: 755
    - target: /usr/pgsql-10/bin/initdb
    - force: True
{% endif %}

{% if  pillar['OS'] == 'redhat8' %}

init-pg-database:
  cmd.run:
    - name: /usr/bin/postgresql-setup --initdb --unit postgresql

#/var/lib/pgsql/data:
#  file.symlink:
#      - target: /var/lib/pgsql/10/data
#      - force: True

reenable-postgres:
  cmd.run:
    - name: systemctl enable postgresql.service

{% elif  pillar['OS'] == 'amazonlinux2' or ( grains['os_family'] == 'RedHat' and grains['osmajorrelease'] | int == 7 ) %}
/var/lib/pgsql/data:
  file.symlink:
      - target: /var/lib/pgsql/10/data
      - force: True

init-pg-database:
  cmd.run:
    - name: find /var/lib/pgsql/ -name PG_VERSION | grep -q "data/PG_VERSION" || /usr/pgsql-10/bin/postgresql-10-setup initdb

systemd-link:
  file.replace:
    - name: /usr/lib/systemd/system/postgresql-10.service
    - pattern: "\\[Install\\]"
    - repl: "[Install]\nAlias=postgresql.service"
    - unless: cat /usr/lib/systemd/system/postgresql-10.service | grep postgresql.service


{% if salt['file.directory_exists']('/yarn-private') %}  # systemctl reenable does not work on ycloud so we create the symlink manually
create-postgres-service-link:
  cmd.run:
    - name: ln -sf /usr/lib/systemd/system/postgresql-10.service /usr/lib/systemd/system/postgresql.service && systemctl disable postgresql-10 && systemctl enable postgresql
{% else %}
reenable-postgres:
  cmd.run:
    - name: systemctl reenable postgresql-10.service
{% endif %}

{% elif pillar['OS'] == 'debian9' or ( grains['os_family'] == 'Debian' and grains['osmajorrelease'] | int in ( 8, 9, 16, 18 ) )  %}
  cmd.run:
    - name: echo 'Ubuntu/Debian, it is initialized automatically.'

{% elif pillar['OS'] == 'sles12sp3' or ( grains['os_family'] == 'Suse' and grains['osmajorrelease'] | int == 12 )  %}
  cmd.run:
    - runas: postgres
    - name: /usr/lib/postgresql10/bin/initdb /var/lib/pgsql/data/

{% else %}
init-pg-database:
  cmd.run:
    - name: find /var/lib/pgsql/ -name PG_VERSION | grep -q "data/PG_VERSION" || service postgresql initdb
{% endif %}

{% if pillar['subtype'] != 'Docker' %}
start-postgresql:
  service.running:
    - name: postgresql

log-postgres-service-status:
  cmd.run:
    - name: systemctl status postgresql.service
{% endif %}

/opt/salt/scripts/conf_pgsql_listen_address.sh:
  file.managed:
    - makedirs: True
    - mode: 755
    - source: salt://postgresql/scripts/conf_pgsql_listen_address.sh

configure-listen-address:
  cmd.run:
    - name: su postgres -c '/opt/salt/scripts/conf_pgsql_listen_address.sh' && echo $(date +%Y-%m-%d:%H:%M:%S) >> /var/log/pgsql_listen_address_configured
    - require:
      - file: /opt/salt/scripts/conf_pgsql_listen_address.sh

{% if pillar['subtype'] != 'Docker' %}
      - service: start-postgresql
{% endif %}

set-postgres-nologin-shell:
  user.present:
    - name: postgres
    - shell: /usr/sbin/nologin

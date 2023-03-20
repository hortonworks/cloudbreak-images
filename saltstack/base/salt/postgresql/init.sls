
{% if pillar['OS'] == 'amazonlinux2' or ( grains['os_family'] == 'RedHat' and grains['osmajorrelease'] | int == 7 ) %}
/etc/yum.repos.d/pgdg10.repo:
  file.managed:
    - source: salt://postgresql/yum/postgres10-el7.repo

/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-10:
  file.managed:
    - source: salt://postgresql/yum/pgdg10-gpg

/etc/yum.repos.d/pgdg11.repo:
  file.managed:
    - source: salt://postgresql/yum/postgres11-el7.repo

/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-11:
  file.managed:
    - source: salt://postgresql/yum/pgdg11-gpg
{% endif %}

{% if pillar['OS'] == 'redhat8' %}
install-postgres:
  cmd.run:
    - name: |
        dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
        dnf module -y disable postgresql
        dnf clean all
        dnf -y install postgresql11-server postgresql11 postgresql11-devel
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

install-postgres11:
  pkg.installed:
    - pkgs:
      - postgresql11-server
      - postgresql-jdbc
      - postgresql11
      - postgresql11-contrib
      - postgresql11-docs
      - postgresql11-devel

pgsql-ld-conf:
  alternatives.set:
    - path: /usr/pgsql-10/share/postgresql-10-libs.conf

pgsql-psql:
  alternatives.set:
    - path: /usr/pgsql-10/bin/psql

pgsql-clusterdb:
  alternatives.set:
    - path: /usr/pgsql-10/bin/clusterdb

pgsql-createdb:
  alternatives.set:
    - path: /usr/pgsql-10/bin/createdb

pgsql-createuser:
  alternatives.set:
    - path: /usr/pgsql-10/bin/createuser

pgsql-dropdb:
  alternatives.set:
    - path: /usr/pgsql-10/bin/dropdb

pgsql-dropuser:
  alternatives.set:
    - path: /usr/pgsql-10/bin/dropuser

pgsql-pg_basebackup:
  alternatives.set:
    - path: /usr/pgsql-10/bin/pg_basebackup

pgsql-pg_dump:
  alternatives.set:
    - path: /usr/pgsql-10/bin/pg_dump

pgsql-pg_dumpall:
  alternatives.set:
    - path: /usr/pgsql-10/bin/pg_dumpall

pgsql-pg_restore:
  alternatives.set:
    - path: /usr/pgsql-10/bin/pg_restore

pgsql-reindexdb:
  alternatives.set:
    - path: /usr/pgsql-10/bin/reindexdb

pgsql-vacuumdb:
  alternatives.set:
    - path: /usr/pgsql-10/bin/vacuumdb

pgsql-clusterdbman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/clusterdb.1

pgsql-createdbman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/createdb.1

pgsql-createuserman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/createuser.1

pgsql-dropdbman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/dropdb.1

pgsql-dropuserman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/dropuser.1

pgsql-pg_basebackupman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/pg_basebackup.1

pgsql-pg_dumpman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/pg_dump.1

pgsql-pg_dumpallman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/pg_dumpall.1

pgsql-pg_restoreman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/pg_restore.1

pgsql-psqlman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/psql.1

pgsql-reindexdbman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/reindexdb.1

pgsql-vacuumdbman:
  alternatives.set:
    - path: /usr/pgsql-10/share/man/man1/vacuumdb.1

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
    - name: /usr/pgsql-11/bin/postgresql-11-setup initdb

reenable-postgres:
  cmd.run:
    - name: systemctl enable --now postgresql-11

{% elif  grains['os_family'] == 'RedHat' and grains['osmajorrelease'] | int == 7 %}
/var/lib/pgsql/data:
  file.symlink:
      - target: /var/lib/pgsql/10/data
      - force: True

init-pg-database:
  cmd.run:
    - name: find /var/lib/pgsql/ -name PG_VERSION | grep -q "data/PG_VERSION" || /usr/pgsql-10/bin/postgresql-10-setup initdb

init-pg11-database:
  cmd.run:
    - name: /usr/pgsql-11/bin/postgresql-11-setup initdb

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
{% if  pillar['OS'] == 'redhat8' %}
    - name: postgresql-11
{% else %}
    - name: postgresql
{% endif %}
log-postgres-service-status:
  cmd.run:
{% if  pillar['OS'] == 'redhat8' %}
    - name: systemctl status postgresql-11.service
{% else %}
    - name: systemctl status postgresql.service
{% endif %}
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

# Needed for installing psycopg2 in saltstack/base/salt/postgresql/init.sls
{% if '/usr/pgsql-11/bin' not in salt['environ.get']('PATH') %}
/opt/salt/scripts/conf_pgconfig_path.sh:
  file.managed:
    - makedirs: True
    - mode: 755
    - source: salt://postgresql/scripts/conf_pgconfig_path.sh

add-pgconfig-to-path:
  cmd.run:
    - name: /opt/salt/scripts/conf_pgconfig_path.sh
    - require:
      - file: /opt/salt/scripts/conf_pgconfig_path.sh

set-path-pgsql11-bin:
  environ.setenv:
    - name: PATH
    - value: "{{ salt['environ.get']('PATH') }}:/usr/pgsql-11/bin"
    - update_minion: True
{% endif %}

# Install psycopg2 globally

# CentOS 7 / RHEL 7 / RHEL 8 + Python 3.6
psycopg2-centos7-py36:
  pip.installed:
    - name: psycopg2==2.9.3
    - bin_env: /usr/local/bin/pip3
    - onlyif: ls -la /usr/local/lib/python3.6/site-packages/

# RHEL 8 + Python 3.8
psycopg2-rhel8-py38:
  pip.installed:
    - name: psycopg2==2.9.3
    - bin_env: /usr/local/bin/pip3.8
    - onlyif: ls -la /usr/lib64/python3.8/site-packages

# CentOS 7 + Python 3.8
psycopg2-centos7-py38:
  pip.installed:
    - name: psycopg2==2.9.3
    - bin_env: /opt/rh/rh-python38/root/usr/bin/pip3
    - onlyif: ls -la /opt/rh/rh-python38/root/usr/lib/python3.8/site-packages/

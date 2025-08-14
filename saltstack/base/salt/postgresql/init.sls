{% if pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' %}

{% set postgres_install_flags = '' %}
{% if salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' or salt['environ.get']('ARCHITECTURE') == 'arm64' %}
  {% set postgres_install_flags = '--skip-broken --nobest' %}
{% endif %}

{% if pillar['OS'] == 'redhat8' %}
/etc/yum.repos.d/postgres11-el8.repo:
  file.managed:
    - source: salt://postgresql/yum/postgres11-el8.repo
    - template: jinja
{% endif %}

install-postgres-all-in-one-repo:
  pkg.installed:
    - sources:
{% if pillar['OS'] == 'redhat9' %}
      - pgdg-redhat-repo: https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-{{ grains['osarch'] }}/pgdg-redhat-repo-latest.noarch.rpm
{% else %}
      - pgdg-redhat-repo: https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-{{ grains['osarch'] }}/pgdg-redhat-repo-latest.noarch.rpm
{% endif %}

disable-pg13:
  pkgrepo.absent:
    - name: pgdg13

disable-pg15:
  pkgrepo.absent:
    - name: pgdg15

disable-pg16:
  pkgrepo.absent:
    - name: pgdg16

install-postgres:
  cmd.run:
    - name: |
        dnf module -y disable postgresql
        dnf clean all
{% if pillar['subtype'] != 'Docker' %}
        dnf -y install postgresql11-server postgresql11 postgresql11-devel {{ postgres_install_flags }}
{% else %}
        dnf -y remove postgresql11-server postgresql11 postgresql11-devel
{% endif %}
        dnf -y install postgresql14-server postgresql14 postgresql14-devel {{ postgres_install_flags }}
{% if (pillar['OS'] == 'redhat8' and salt['environ.get']('RHEL_VERSION') == '8.10') or pillar['OS'] == 'redhat9' %}
        dnf -y install postgresql17-server postgresql17 postgresql17-devel {{ postgres_install_flags }}
{% endif %}
    - failhard: True

{% if pillar['subtype'] == 'Docker' %}
timeoutstop-postgres-ycloud:
  cmd.run:
    - name: mkdir /etc/systemd/system/postgresql-14.service.d  && echo $'[Service]\nTimeoutStopSec=120s' > /etc/systemd/system/postgresql-14.service.d/timeout.conf && mkdir /etc/systemd/system/postgresql-17.service.d && echo $'[Service]\nTimeoutStopSec=120s' > /etc/systemd/system/postgresql-17.service.d/timeout.conf
{% endif %}

{% set pg_default_version = '14' %}

{% elif pillar['OS'] == 'centos7' %}

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

/etc/yum.repos.d/pgdg14.repo:
  file.managed:
    - source: salt://postgresql/yum/postgres14-el7.repo

/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-14:
  file.managed:
    - source: salt://postgresql/yum/pgdg14-gpg

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

install-postgres14:
  pkg.installed:
    - pkgs:
        - postgresql14-server
        - postgresql-jdbc
        - postgresql14
        - postgresql14-contrib
        - postgresql14-docs
        - postgresql14-devel

# the override to 11 for runtimes >= 7.2.7 is handled in CB
{% set pg_default_version = '10' %}

{% endif %}

pgsql-ld-conf:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/postgresql-{{ pg_default_version }}-libs.conf

pgsql-psql:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/psql

pgsql-clusterdb:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/clusterdb

pgsql-createdb:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/createdb

pgsql-createuser:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/createuser

pgsql-dropdb:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/dropdb

pgsql-dropuser:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/dropuser

pgsql-pg_basebackup:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/pg_basebackup

pgsql-pg_dump:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/pg_dump

pgsql-pg_dumpall:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/pg_dumpall

pgsql-pg_restore:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/pg_restore

pgsql-reindexdb:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/reindexdb

pgsql-vacuumdb:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/bin/vacuumdb

pgsql-clusterdbman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/clusterdb.1

pgsql-createdbman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/createdb.1

pgsql-createuserman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/createuser.1

pgsql-dropdbman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/dropdb.1

pgsql-dropuserman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/dropuser.1

pgsql-pg_basebackupman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/pg_basebackup.1

pgsql-pg_dumpman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/pg_dump.1

pgsql-pg_dumpallman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/pg_dumpall.1

pgsql-pg_restoreman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/pg_restore.1

pgsql-psqlman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/psql.1

pgsql-reindexdbman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/reindexdb.1

pgsql-vacuumdbman:
  alternatives.set:
    - path: /usr/pgsql-{{ pg_default_version }}/share/man/man1/vacuumdb.1

/usr/bin/initdb:
  file.symlink:
    - mode: 755
    - target: /usr/pgsql-{{ pg_default_version }}/bin/initdb
    - force: True

{% if pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' %}

init-pg-database:
  cmd.run:
    - name: /usr/pgsql-{{ pg_default_version }}/bin/postgresql-{{ pg_default_version }}-setup initdb

reenable-postgres:
  cmd.run:
    - name: systemctl enable --now postgresql-{{ pg_default_version }}

{% elif pillar['OS'] == 'centos7' %}
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
    - name: /usr/lib/systemd/system/postgresql-{{ pg_default_version }}.service
    - pattern: "\\[Install\\]"
    - repl: "[Install]\nAlias=postgresql.service"
    - unless: cat /usr/lib/systemd/system/postgresql-{{ pg_default_version }}.service | grep postgresql.service


{% if pillar['subtype'] == 'Docker' %}  # systemctl reenable does not work on ycloud so we create the symlink manually
create-postgres-service-link:
  cmd.run:
    - name: |
        ln -sf /usr/lib/systemd/system/postgresql-{{ pg_default_version }}.service /usr/lib/systemd/system/postgresql.service
        systemctl disable postgresql-{{ pg_default_version }}
        systemctl enable postgresql
{% else %}

reenable-postgres:
  cmd.run:
    - name: systemctl reenable postgresql-{{ pg_default_version }}.service
{% endif %}

{% endif %}

{% if pillar['subtype'] != 'Docker' %}
start-postgresql:
  service.running:
{% if pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' %}
    - name: postgresql-{{ pg_default_version }}
{% else %}
    - name: postgresql
{% endif %}
log-postgres-service-status:
  cmd.run:
{% if pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' %}
    - name: systemctl status postgresql-{{ pg_default_version }}.service
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
    - env:
      - SUBTYPE: {{ pillar['subtype'] }}
    - require:
      - file: /opt/salt/scripts/conf_pgsql_listen_address.sh
{% if pillar['subtype'] != 'Docker' %}
      - service: start-postgresql
{% endif %}

{% if pillar['subtype'] != 'Docker' %}
stop-postgresql:
  service.dead:
{% if pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' %}
    - name: postgresql-{{ pg_default_version }}
    - enable: False
{% else %}
    - name: postgresql
{% endif %}
{% endif %}

set-postgres-nologin-shell:
  user.present:
    - name: postgres
    - shell: {{ salt['cmd.run']('which nologin') }}

# Needed for installing psycopg2 in saltstack/base/salt/postgresql/init.sls
{% set pg_default_version_bin = '/usr/pgsql-' ~ pg_default_version ~ '/bin' %}
{% if pg_default_version_bin not in salt['environ.get']('PATH') %}
set-etc-environment-path-pgsql{{ pg_default_version }}-bin:
  file.replace:
    - name: /etc/environment
    - pattern: |
        ^PATH="(.*)"$
    - repl: |
        PATH="\1:{{ pg_default_version_bin }}"

set-path-pgsql{{ pg_default_version }}-bin:
  environ.setenv:
    - name: PATH
    - value: "{{ salt['environ.get']('PATH') }}:{{ pg_default_version_bin }}"
    - update_minion: True
{% endif %}

# Install psycopg2 globally

# CentOS 7 / RHEL 7 / RHEL 8 + Python 3.6
psycopg2-centos7-py36:
  pip.installed:
    - name: psycopg2==2.9.3
    - bin_env: /usr/local/bin/pip3
    - onlyif: ls -la /usr/local/lib/python3.6/site-packages/

psycopg2-centos7-py36-verify:
  cmd.run:
    - name: /usr/local/bin/pip3 show psycopg2
    - onlyif: ls -la /usr/local/lib/python3.6/site-packages/

psycopg2-centos7-py36-hue-link:
  cmd.run:
    - name: ln -s /usr/local/lib64/python3.6/site-packages/psycopg2 /usr/lib64/python3.6/site-packages/psycopg2
    - onlyif: ls -la /usr/local/lib64/python3.6/site-packages/psycopg2

psycopg2-centos7-py36-hue-link-2:
  cmd.run:
    - name: ln -s /usr/local/lib64/python3.6/site-packages/psycopg2-2.9.3-py3.6.egg-info /usr/lib64/python3.6/site-packages/psycopg2-2.9.3-py3.6.egg-info
    - onlyif: ls -la /usr/local/lib64/python3.6/site-packages/psycopg2-2.9.3-py3.6.egg-info

# RHEL 8 + Python 3.8
psycopg2-rhel8-py38:
  pip.installed:
    - name: psycopg2==2.9.3
    - bin_env: /usr/local/bin/pip3.8
    - onlyif: ls -la /usr/lib64/python3.8/site-packages

psycopg2-rhel8-py38-verify:
  cmd.run:
    - name: /usr/local/bin/pip3.8 show psycopg2
    - onlyif: ls -la /usr/lib64/python3.8/site-packages

psycopg2-rhel8-py38-hue-link:
  cmd.run:
    - name: ln -s /usr/local/lib64/python3.8/site-packages/psycopg2 /usr/lib64/python3.8/site-packages/psycopg2
    - onlyif: ls -la /usr/local/lib64/python3.8/site-packages/psycopg2

psycopg2-rhel8-py38-hue-link-2:
  cmd.run:
    - name: ln -s /usr/local/lib64/python3.8/site-packages/psycopg2-2.9.3-py3.8.egg-info /usr/lib64/python3.8/site-packages/psycopg2-2.9.3-py3.8.egg-info
    - onlyif: ls -la /usr/local/lib64/python3.8/site-packages/psycopg2-2.9.3-py3.8.egg-info

# RHEL 8 + Python 3.9
psycopg2-rhel8-py39:
  pip.installed:
    - name: psycopg2==2.9.3
    - bin_env: /usr/local/bin/pip3.9
    - onlyif: ls -la /usr/lib64/python3.9/site-packages

psycopg2-rhel8-py39-verify:
  cmd.run:
    - name: /usr/local/bin/pip3.9 show psycopg2
    - onlyif: ls -la /usr/lib64/python3.9/site-packages

psycopg2-rhel8-py39-hue-link:
  cmd.run:
    - name: ln -s /usr/local/lib64/python3.9/site-packages/psycopg2 /usr/lib64/python3.9/site-packages/psycopg2
    - onlyif: ls -la /usr/local/lib64/python3.9/site-packages/psycopg2

psycopg2-rhel8-py39-hue-link-2:
  cmd.run:
    - name: ln -s /usr/local/lib64/python3.9/site-packages/psycopg2-2.9.3-py3.9.egg-info /usr/lib64/python3.9/site-packages/psycopg2-2.9.3-py3.9.egg-info
    - onlyif: ls -la /usr/local/lib64/python3.9/site-packages/psycopg2-2.9.3-py3.9.egg-info

# RHEL 8 + Python 3.11
psycopg2-rhel8-py311:
  pip.installed:
    - name: psycopg2==2.9.3
    - bin_env: /usr/local/bin/pip3.11
    - onlyif: ls -la /usr/lib64/python3.11/site-packages

psycopg2-rhel8-py311-verify:
  cmd.run:
    - name: /usr/local/bin/pip3.11 show psycopg2
    - onlyif: ls -la /usr/lib64/python3.11/site-packages

psycopg2-rhel8-py311-hue-link:
  cmd.run:
    - name: ln -s /usr/local/lib64/python3.11/site-packages/psycopg2 /usr/lib64/python3.11/site-packages/psycopg2
    - onlyif: ls -la /usr/local/lib64/python3.11/site-packages/psycopg2

psycopg2-rhel8-py311-hue-link-2:
  cmd.run:
    - name: ln -s /usr/local/lib64/python3.11/site-packages/psycopg2-2.9.3-py3.11.egg-info /usr/lib64/python3.11/site-packages/psycopg2-2.9.3-py3.11.egg-info
    - onlyif: ls -la /usr/local/lib64/python3.11/site-packages/psycopg2-2.9.3-py3.11.egg-info

# CentOS 7 + Python 3.8
psycopg2-centos7-py38:
  pip.installed:
    - name: psycopg2==2.9.3
    - bin_env: /opt/rh/rh-python38/root/usr/bin/pip3
    - onlyif: ls -la /opt/rh/rh-python38/root/usr/lib/python3.8/site-packages/
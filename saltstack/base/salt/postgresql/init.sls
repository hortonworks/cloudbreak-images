{% if  pillar['OS'] == 'amazonlinux' or ( grains['os_family'] == 'RedHat' and grains['osmajorrelease'] | int == 6 )  %}
/etc/yum.repos.d/pgdg95.repo:
  file.managed:
    - source: salt://postgresql/yum/postgres95-el6.repo

/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-95:
  file.managed:
    - source: salt://postgresql/yum/pgdg95-gpg

{% elif  pillar['OS'] == 'amazonlinux2' %}
/etc/yum.repos.d/pgdg95.repo:
  file.managed:
    - source: salt://postgresql/yum/postgres95-el7.repo

/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-95:
  file.managed:
    - source: salt://postgresql/yum/pgdg95-gpg
{% endif %}

{% if grains['os_family'] == 'RedHat' and grains['osmajorrelease'] | int == 7  %}
install-postgres:
  pkg.installed:
    - pkgs:
      - postgresql-server
      - postgresql-jdbc
      - postgresql

init-pg-database:
  cmd.run:
    - name: find /var/lib/pgsql/ -name PG_VERSION | grep -q "data/PG_VERSION" || postgresql-setup initdb
    - runas: postgres
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
      - postgresql96
      - postgresql-init
      - postgresql96-server
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
      - postgresql95-server
      - postgresql-jdbc
      - postgresql95

/etc/init.d/postgresql:
  file.symlink:
      - target: /etc/init.d/postgresql-9.5
      - force: True

{% if  pillar['OS'] == 'amazonlinux2' %}
init-pg-database:
  cmd.run:
    - name: find /var/lib/pgsql/ -name PG_VERSION | grep -q "data/PG_VERSION" || /usr/pgsql-9.5/bin/postgresql95-setup initdb

systemd-link:
  file.replace:
    - name: /usr/lib/systemd/system/postgresql-9.5.service
    - pattern: "\\[Install\\]"
    - repl: "[Install]\nAlias=postgresql.service"
    - unless: cat /usr/lib/systemd/system/postgresql-9.5.service | grep postgresql.service

reenable-postgres:
  cmd.run:
    - name: systemctl reenable postgresql-9.5.service    

{% else %}
init-pg-database:
  cmd.run:
    - name: find /var/lib/pgsql/ -name PG_VERSION | grep -q "data/PG_VERSION" || service postgresql initdb
{% endif %}
{% endif %}

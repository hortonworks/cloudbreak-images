install_postgresql_jdbc_driver:
  file.managed:
    - name: /opt/jdbc-drivers/postgresql-9.4.1208.jre7.jar
    - source: https://jdbc.postgresql.org/download/postgresql-9.4.1208.jre7.jar
    - skip_verify: True
    - makedirs: True
    - if_missing: /opt/jdbc-drivers/postgresql-9.4.1208.jre7.jar
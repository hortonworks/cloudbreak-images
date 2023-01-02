download_mysql_jdbc_driver:
  archive.extracted:
    - name: /tmp/
    - source: https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.39.tar.gz
    - source_hash: sha256=fa1bdc9ee5323642c5a533fa73fbcf537b26a979e5981c486c24256c433c7718
    - skip_verify: True
    - archive_format: tar
    - enforce_toplevel: True
    - if_missing: /opt/jdbc-drivers/mysql-connector-java-5.1.39-bin.jar

move_mysql_jdbc_driver:
  file.managed:
    - name: /opt/jdbc-drivers/mysql-connector-java-5.1.39-bin.jar
    - source: /tmp/mysql-connector-java-5.1.39/mysql-connector-java-5.1.39-bin.jar
    - makedirs: True
    - replace: False
    - require:
      - archive: download_mysql_jdbc_driver

remove_temp_mysql_jdbc_driver_files:
  file.absent:
    - name: /tmp/mysql-connector-java-5.1.39
    - require:
      - file: move_mysql_jdbc_driver
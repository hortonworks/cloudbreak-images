read_java_home:
  file.exists:
    - name: /etc/profile.d/java.sh
    - failhard: True

check_java_javahome:
  cmd.run:
    - name: '. /etc/profile.d/java.sh && $JAVA_HOME/bin/java -version'
    - failhard: True

check_javac_javahome:
  cmd.run:
    - name: '. /etc/profile.d/java.sh && $JAVA_HOME/bin/javac -version'
    - failhard: True
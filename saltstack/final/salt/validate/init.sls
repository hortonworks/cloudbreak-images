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

check_default_java_major_version:
  cmd.run:
    - name: '$(if [[ $(java -version 2>&1 | grep -oP "version [^0-9]?(1\.)?\K\d+" || true) == $DEFAULT_JAVA_MAJOR_VERSION ]]; then exit 0; else exit 1; fi)'
    - failhard: True
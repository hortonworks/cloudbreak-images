{% if pillar['CUSTOM_IMAGE_TYPE'] == 'base' %}

{% set java_home = salt['environ.get']('JAVA_HOME') %}
{% if java_home %}

check_java_javahome:
  cmd.run:
    - name: {{ salt['environ.get']('JAVA_HOME') }}/bin/java
    - require:
      - file: {{ salt['environ.get']('JAVA_HOME') }}/bin/java
    - failhard: True

check_javac_javahome:
  cmd.run:
    - name: {{ salt['environ.get']('JAVA_HOME') }}/bin/javac
    - require:
      - file: {{ salt['environ.get']('JAVA_HOME') }}/bin/javac
    - failhard: True

{% elif salt['file.directory_exists']('/usr/lib/jvm/java') %}

check_java:
  cmd.run:
    - name: /usr/lib/jvm/java/bin/java
    - require:
      - file: /usr/lib/jvm/java/bin/java
    - failhard: True

check_javac:
  cmd.run:
    - name: /usr/lib/jvm/java/bin/javac
    - require:
      - file: /usr/lib/jvm/java/bin/javac
    - failhard: True

{% else %}

fail_no_java_home_set:
  test.fail_without_changes:
    - failhard: True

{% endif %}

{% endif %}

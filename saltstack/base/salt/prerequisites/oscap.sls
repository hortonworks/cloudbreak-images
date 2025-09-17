/tmp/oscap:
  file.directory:
    - name: /tmp/oscap
    - mode: 755

/tmp/oscap/oscap_dummy:
  file.managed:
    - contents: '' # Creates an empty file.
    - require:
      - file: /tmp/oscap # Ensures the directory is created before the file.

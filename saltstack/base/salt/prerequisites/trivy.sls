/tmp/trivy:
  file.directory:
    - name: /tmp/trivy
    - mode: 755

/tmp/trivy/trivy_dummy:
  file.managed:
    - contents: '' # Creates an empty file.
    - require:
      - file: /tmp/trivy # Ensures the directory is created before the file.

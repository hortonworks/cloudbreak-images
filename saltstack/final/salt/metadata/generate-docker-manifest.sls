add_generate_docker_manifest_script:
  file.managed:
    - name: /tmp/generate-docker-manifest.sh
    - source: salt://{{ slspath }}/tmp/generate-docker-manifest.sh
    - skip_verify: True
    - makedirs: True
    - mode: 755

run_generate_docker_manifest:
  cmd.run:
    - name: /tmp/generate-docker-manifest.sh 2>&1 >>/var/log/generate-docker-manifest.sh.log
    - unless: /var/log/generate-docker-manifest.sh.log
    - env:
      - DOCKER_REPOSITORY: {{ salt['environ.get']('DOCKER_REPOSITORY') }}
      - IMAGE_UUID: {{ salt['environ.get']('IMAGE_UUID') }}
      - DOCKER_IMAGE_NAME: {{ salt['environ.get']('DOCKER_IMAGE_NAME') }}
      - TAG: {{ salt['environ.get']('TAG') }}
      - IMAGE_NAME: {{ salt['environ.get']('IMAGE_NAME') }}
      - OS: {{ salt['environ.get']('OS') }}
      - OS_TYPE: {{ salt['environ.get']('OS_TYPE') }}
      - MANIFEST_FILE: {{ salt['environ.get']('MANIFEST_FILE') }}
    - require:
      - file: add_generate_docker_manifest_script

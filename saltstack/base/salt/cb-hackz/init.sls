fake_python2-psycopg2_rpm_step0:
  pkg.installed:
    - pkgs:
        - rpmdevtools
        - rpm-build
        - rpmlint

fake_python2-psycopg2_rpm_step1:
  file.recurse:
    - name: /tmp/fakerpm
    - source: salt://{{ slspath }}/fakerpm
    - dir_mode: 755

fake_python2-psycopg2_rpm_step2:
  cmd.run:
    - name: chmod +x create-fake-rpm
    - cwd: /tmp/fakerpm

fake_python2-psycopg2_rpm_step3:
  cmd.run:
    - name: ./create-fake-rpm --build python2-psycopg2 python2-psycopg2
    - cwd: /tmp/fakerpm

fake_python2-psycopg2_rpm_step4:
  cmd.run:
    - name: rpm -i /tmp/fakerpm/noarch/python2-psycopg2-0-0.noarch.rpm
    - cwd: /tmp/fakerpm

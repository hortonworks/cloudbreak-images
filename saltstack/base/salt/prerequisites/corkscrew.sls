{%if pillar['subtype'] != 'Docker' %}

{% if pillar['OS'] != 'centos7' %}
clone_corkscrew:
  git.latest:
    - name: https://github.com/bryanpkc/corkscrew.git
    - rev: v2.0
    - target: /tmp/corkscrew

install_corkscrew:
  cmd.run:
    - name: autoreconf --install && ./configure && make && make install
    - cwd: /tmp/corkscrew

cleanup_corkscrew:
  file.absent:
    - name: /tmp/corkscrew

create_corkscrew_softlink:
  cmd.run:
    - name: ln -s /usr/local/bin/corkscrew /usr/bin/corkscrew
{% endif %}

{% elif pillar['OS'] == 'redhat8' %}

download_corkscrew_from_s3:
  cmd.run:
  - name: |
      wget -c -q --no-cookies --no-check-certificate \
            https://corkscrew-internal.s3.amazonaws.com/corkscrew \
            -O /usr/local/bin/corkscrew

make_corkscrew_executable:
  cmd.run:
    - name: chmod +x /usr/local/bin/corkscrew

create_corkscrew_softlink:
  cmd.run:
    - name: ln -s /usr/local/bin/corkscrew /usr/bin/corkscrew

{% else %}

install_corkscrew:
  pkg.installed:
    - sources:
      - corkscrew: http://ftp.altlinux.org/pub/distributions/ALTLinux/Sisyphus/x86_64/RPMS.classic/corkscrew-2.0-alt1.qa1.x86_64.rpm

{% endif %}

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

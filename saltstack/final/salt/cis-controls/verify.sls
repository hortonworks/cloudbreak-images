gpgcheck_verify:
  cmd.run:
    - name: if [[ $(grep -H -P "^gpgcheck\h*=\h*[^1].*\h*$" /etc/yum.repos.d/*) ]]; then false; else true; fi;
    - failhard: True

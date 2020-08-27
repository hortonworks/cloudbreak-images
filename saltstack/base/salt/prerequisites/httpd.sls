{% if pillar['OS'] == 'centos7' %}

create_okay_repo:
  pkgrepo.managed:
    - name: okay
    - humanname: "Extra OKay Packages for Enterprise Linux - $basearch"
    - baseurl: "http://repo.okay.com.mx/centos/$releasever/$basearch/release"
    - gpgcheck: 0

install_httpd:
  pkg.latest:
    - name: httpd

{% endif %}
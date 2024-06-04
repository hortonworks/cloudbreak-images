include:
  - {{ slspath }}.path
  - {{ slspath }}.user_uid
  - {{ slspath }}.subscription-manager
  - {{ slspath }}.repository
  - {{ slspath }}.packages
  - {{ slspath }}.sudo
{% if pillar['subtype'] != 'Docker' %}
  - {{ slspath }}.sysctl
  - {{ slspath }}.disable_ipv6
  - {{ slspath }}.selinux
  - {{ slspath }}.dnsmasq
{% endif %}
  - {{ slspath }}.motd
  - {{ slspath }}.ssh
  - {{ slspath }}.pip
  - {{ slspath }}.cert-tool
  - {{ slspath }}.user
  - {{ slspath }}.firewall
  - {{ slspath }}.umask
  - {{ slspath }}.jinja
  - {{ slspath }}.corkscrew
  - {{ slspath }}.storage
  - {{ slspath }}.authconfig
  - {{ slspath }}.ipa

/usr/bin/:
  file.recurse:
    - source: salt://{{ slspath }}/usr/bin/
    - template: jinja
    - include_empty: True
    - file_mode: 755

install_cdp_jenkins_build_us_west1_gpg_key:
  cmd.run:
    - name: "cp /tmp/repos/gpg-key-jenkins-build-us-west1.pub /etc/pki/rpm-gpg/gpg-key-jenkins-build-us-west1.pub && rpm --import /etc/pki/rpm-gpg/gpg-key-jenkins-build-us-west1.pub"
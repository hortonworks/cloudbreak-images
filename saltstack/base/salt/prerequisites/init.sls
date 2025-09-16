include:
  - {{ slspath }}.path
  - {{ slspath }}.setroubleshoot
{% if pillar['OS'] == 'redhat9' %}
  - {{ slspath }}.geoclue
{% endif %}
  - {{ slspath }}.user_uid
  - {{ slspath }}.subscription-manager
  - {{ slspath }}.repository
  - {{ slspath }}.packages
  - {{ slspath }}.sudo
  - {{ slspath }}.disable_ipv6
{% if pillar['subtype'] != 'Docker' %}
  - {{ slspath }}.sysctl
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
  - {{ slspath }}.oscap

/usr/bin/:
  file.recurse:
    - source: salt://{{ slspath }}/usr/bin/
    - template: jinja
    - include_empty: True
    - file_mode: 755
    - defaults:
        stack_version: {{ salt['environ.get']('STACK_VERSION') }}

install_cdp_jenkins_build_us_west1_gpg_key:
  cmd.run:
    - name: "cp /tmp/repos/gpg-key-jenkins-build-us-west1.pub /etc/pki/rpm-gpg/gpg-key-jenkins-build-us-west1.pub && rpm --import /etc/pki/rpm-gpg/gpg-key-jenkins-build-us-west1.pub"
**Table of Contents**

- [Images content for Cloudbreak](#images-content-for-cloudbreak)
  - [Source of base images](#source-of-base-images)
  - [Salt requirements](#salt-requirements)
  - [Base packages](#base-packages)
  - [Pre-warmed packages](#pre-warmed-packages)
  - [Freeipa packages](#freeipa-packages)
  - [Optional packages](#optional-packages-not-installed)


# Images content for Cloudbreak

This section provides information about the packages of specified images to be installed.

## Source of base images

 Cloud Provider | OS | Source
 ---- | ---- | ----
 AWS | CentOS 7 | `ami-098f55b4287a885ba`
 Azure | CentOS 7 |  `OpenLogic - CentOS - 7.6`
 Gcp | CentOS 7 |  `centos-7-v20200811`

## Salt requirements
- requests
- virtualenvwrapper
- CherryPy
- pyzmq
- salt
- tornado
- msgpack-python
- PyOpenSSL

## Base packages
- cert-tool
- corkscrew
- jinja2
- wget
- tar
- unzip
- curl
- net-tools
- git-core (Suse)
- man (Suse)
- libxml2-tools (Suse)
- git
- tmux
- ntp
- bash-completion (Amazon)
- iptables
- mc
- ruby
- snappy (RedHat)
- cloud-utils-growpart (RedHat)
- snappy-devel (RedHat but not redhat7)
- bind-utils (RedHat major version 7)
- iptables-services
- iptables-persistent (Debian)
- dnsutils (Debian)
- deltarpm
- nvme-cli
- openssl
- vim-common (centos7, redhat7)
- vim
- autossh (not Suse)
- ipa-client
- openldap
- openldap-clients
- awscli
- azcopy
- openssl-devel (RedHat)
- python_pip2 (Suse, not Amazon)
- python_pip3 (Suse, not Amazon)
- pyyaml
- cm_client
- fluent_logger
- pid
- jq
- policycoreutils (RedHat)
- policycoreutils-python (RedHat)
- cloud-init
- fluentd
- consul-template
- consul
- node-exporter
- jmx-exporter
- prometheus
- nginx
- postgresql
- salt
- salt-bootstrap
- cdp-telemetry

## Pre-warmed packages
- CFM
- PROFILER
- SPARK3
- CSA
- autossh
- openjdk
- haveged
- krb5-server (RedHat, Suse)
- krb5-libs (RedHat)
- krb5-workstation (RedHat)
- krb5-admin-server (Debian)
- krb5-kdc (Debian)
- krb5 (Suse)
- krb5-client (Suse)
- metering-heartbeat-rpm (centos, redhat, amazonlinux2)
- mktorrent
- cdh
- cloudera-manager-daemons
- cloudera-manager-agent
- cloudera-manager-server
- cloudera-manager-server-db-2
- yum-utils
- createrepo
- httpd
- nodejs
- smartsense-hst
- resolvconf (Debian)
- ruby-ws

## Freeipa packages
- autossh
- openjdk
- krb5-server
- krb5-libs
- krb5-workstation
- yum-utils
- httpd
- ntp
- ipa-server
- ipa-server-dns
- cdp-hashed-pwd
- freeipa-health-agent

## Optional packages (not installed)
- mysql-jdbc-driver
- jdk1.8


{% set os = salt['environ.get']('OS') %}
{% set cloudera_public_gem_repo = 'https://repository.cloudera.com/cloudera/api/gems/cloudera-gems/' %}
{% set cloudera_azure_plugin_version = '1.0.1' %}
{% set cloudera_azure_gen2_plugin_version = '0.3.1' %}
{% set cloudera_databus_plugin_version = '1.0.5' %}
{% set redaction_plugin_version = '0.1.2' %}

{% if os.startswith("centos") or os.startswith("redhat") %}
install_fluentd_yum:
  cmd.run:
    - name: curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent3.sh | sh
{% elif os.startswith("ubuntu") %}
  {% if os == "ubuntu18" %}
install_fluentd_ubuntu18:
  cmd.run:
    - name: curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-bionic-td-agent3.sh | sh
  {% elif os == "ubuntu16" %}
install_fluentd_ubuntu16:
  cmd.run:
    - name: curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-xenial-td-agent3.sh | sh
  {% elif os == "ubuntu14" %}
install_fluentd_ubuntu14:
  cmd.run:
    - name: curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-trusty-td-agent3.sh | sh
  {% else %}
warning_fluentd_ubuntu:
  cmd.run:
    - name: echo "Warning - Fluentd install is not supported for this Ubuntu OS version ({{ os }})"
  {% endif %}
{% elif os.startswith("debian") %}
  {% if os == "debian9" %}
install_fluentd_debian9:
  cmd.run:
    - name: curl -L https://toolbelt.treasuredata.com/sh/install-debian-stretch-td-agent3.sh | sh
  {% elif os == "debian8" %}
install_fluentd_debian8:
  cmd.run:
    - name: curl -L https://toolbelt.treasuredata.com/sh/install-debian-jessie-td-agent3.sh | sh
  {% else %}
warning_fluentd_debian:
  cmd.run:
    - name: echo "Warning - Fluentd install is not supported for this Debian OS version ({{ os }})"
  {% endif %}
{% elif os.startswith("sles") %}
warning_fluentd_suse:
  cmd.run:
    - name: echo "Warning - Fluentd install is not supported yet for Suse ({{ os }})"
{% elif os == "amazonlinux2" %}
install_fluentd_amazon2:
  cmd.run:
    - name: curl -L https://toolbelt.treasuredata.com/sh/install-amazon2-td-agent3.sh | sh
{% elif os == "amazonlinux" %}
install_fluentd_amazon1:
  cmd.run:
    - name: curl -L https://toolbelt.treasuredata.com/sh/install-amazon1-td-agent3.sh | sh
{% else %}
warning_fluentd_os:
  cmd.run:
    - name: echo "Warning - Fluentd install is not supported for this OS type ({{ os }})"
{% endif %}

install_fluentd_plugins:
  cmd.run:
    - names:
      - /opt/td-agent/embedded/bin/fluent-gem source -a {{ cloudera_public_gem_repo }}
      - /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-cloudwatch-logs fluent-plugin-detect-exceptions 
      - /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-redaction -v {{ redaction_plugin_version }}
      - /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-databus -v {{ cloudera_databus_plugin_version }}
      - /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-azurestorage -v {{ cloudera_azure_plugin_version }} -s {{ cloudera_public_gem_repo }}
      - /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-azurestorage-gen2 -v {{ cloudera_azure_gen2_plugin_version }}
    - onlyif: test -d /opt/td-agent/embedded/bin/
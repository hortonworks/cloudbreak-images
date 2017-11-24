# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.

  config.vbguest.iso_path = File.expand_path("/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso", __FILE__)
  config.vbguest.no_remote = true

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.auto_detect = true

    #asnible get_url
    config.cache.enable :generic, {
      "get_url" => { cache_dir: "/var/cache/get_url" },
    }
  end

  servers=[
      {
        :hostname => "centos7-vagrant",
        :box => "centos/7",
        :ram => 1024,
        :cpu => 2,
        :salt_repo => "salt-repo-2017.7-1.el.repo",
        :optional_states => "oracle-java",
        :oracle_jdk8_url_rpm => "http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.rpm"
      },
      {
        :hostname => "centos6-vagrant",
        :box => "centos/6",
        :ram => 1536,
        :cpu => 2,
        :salt_repo => "salt-repo-2017.7-1.el.repo",
        :optional_states => "oracle-java",
        :oracle_jdk8_url_rpm => "http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.rpm"
=begin

      #   :ambari_baseurl => "http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/2.x/BUILDS/2.4.1.0-22/",
      #   :ambari_key => "http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins",
      #   :hdp_stack_version => "2.5",
      #   :hdp_version => "2.5.0.1-60",
      #   :hdp_baseurl => "http://s3.amazonaws.com/dev.hortonworks.com/HDP/centos6/2.x/BUILDS/2.5.0.1-60",
      #   :hdp_repoid => "HDP-2.5",
=end
      },
      # {
      #   :hostname => "wheezy-vagrant",
      #   :box => "debian/wheezy64",
      #   :ram => 1536,
      #   :cpu => 2,
      #   :ambari_baseurl => "http://s3.amazonaws.com/dev.hortonworks.com/ambari/debian7/2.x/BUILDS/2.4.1.0-22/",
      #   :ambari_key => "B9733A7A07513CAD",
      #   :salt_repo => "http://repo.saltstack.com/apt/debian/7/amd64/latest"
      # },
      # {
      #   :hostname => "xenial-vagrant",
      #   :box => "ubuntu/xenial64",
      #   :ram => 1536,
      #   :cpu => 2,
      #   :ambari_baseurl => "http://s3.amazonaws.com/dev.hortonworks.com/ambari/ubuntu12/2.x/BUILDS/2.4.1.0-22/",
      #   :ambari_key => "B9733A7A07513CAD",
      #   :salt_repo => "http://repo.saltstack.com/apt/ubuntu/12.04/amd64/latest"
      # },
      # {
      #   :hostname => "trusty-vagrant",
      #   :box => "ubuntu/trusty64",
      #   :ram => 1536,
      #   :cpu => 2,
      #   :ambari_baseurl => "http://s3.amazonaws.com/dev.hortonworks.com/ambari/ubuntu14/2.x/BUILDS/2.4.1.0-22/",
      #   :ambari_key => "B9733A7A07513CAD",
      #   :salt_repo => "http://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest"
      # },
  ].each do |machine|
    config.vm.define machine[:hostname] do |node|
        node.vm.box = machine[:box]
        node.vm.hostname = machine[:hostname]
        node.vm.network "private_network", type: "dhcp"
        node.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", machine[:ram]]
            vb.customize ["modifyvm", :id, "--cpus", machine[:cpu]]
            vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
            vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        end

        node.vm.synced_folder "saltstack/", "/tmp/saltstack/"
        node.vm.synced_folder "scripts/", "/tmp/scripts/"
        node.vm.synced_folder "repos/", "/tmp/repos/"

        node.vm.provision :shell do |shell|
          shell.path = "scripts/salt-install.sh"
          shell.args = machine[:box].split('/',-1)[0] + " " + machine[:salt_repo] + " " + machine[:box].split('/',-1)[1].gsub(/ *\d+$/, '')
          shell.keep_color = false
        end

        node.vm.provision :shell do |shell|
          #shell.inline = "salt-call --local state.highstate --file-root=/srv/salt --pillar-root=/srv/pillar --retcode-passthrough -l info --config-dir=/srv/config"
          shell.inline = "/tmp/scripts/salt-setup.sh"
          shell.keep_color = true
          shell.env = {
            "OPTIONAL_STATES" => "oracle-java",
            "ORACLE_JDK8_URL_RPM" => machine[:oracle_jdk8_url_rpm],
            "os_user" => "vagrant"
          }
        end

        # node.vm.provision :salt do |salt|
        #   salt.install_type = "stable"
        #   salt.pillar({
        #
        #     "AMBARI_VERSION" => "2.4",
        #     "AMBARI_BASEURL" => machine[:ambari_baseurl],
        #     "AMBARI_GPGKEY" => machine[:ambari_key],
        #     "HDP_STACK_VERSION" => machine[:hdp_stack_version],
        #     "HDP_VERSION" => machine[:hdp_version],
        #     "HDP_BASEURL" => machine[:hdp_baseurl],
        #     "HDP_REPOID" => machine[:hdp_repoid]
        #   })
        #   salt.install_master = false
        #   salt.no_minion = true
        #   salt.minion_config = "saltstack/config/minion.yml"
        #   salt.masterless = true
        #   salt.run_highstate = true
        #   salt.verbose = true
        #   salt.colorize = true
        #   salt.log_level = "info"
        # end
    end
  end


end

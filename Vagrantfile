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

  config.vbguest.iso_path = "/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso"
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
        :hostname => "centos7",
        :box => "centos/7",
        :ram => 1024,
        :cpu => 2,
        :salt_repo => "salt-repo-2017.7-1.el.repo",
        :optional_states => "oracle-java",
        :custom_image_type => "hortonworks",
        :oracle_jdk8_url_rpm => "http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.rpm"
      },
      {
        :hostname => "centos6",
        :box => "centos/6",
        :ram => 1536,
        :cpu => 2,
        :salt_repo => "salt-repo-2016.11-6.el.repo",
        :custom_image_type => "hortonworks",
      },
      {
        :hostname => "debian7",
        :box => "debian/wheezy64",
        :ram => 1536,
        :cpu => 2,
        :salt_repo => "salt-repo-2016.11-5.debian7.list",
        :custom_image_type => "hortonworks"
      },
      {
        :hostname => "ubuntu12",
        :box => "ubuntu/precise64",
        :ram => 1536,
        :cpu => 2,
        :salt_repo => "salt-repo-2016.11-3.ubuntu12.list",
        :custom_image_type => "hortonworks"
      },
      {
        :hostname => "ubuntu14",
        :box => "ubuntu/trusty64",
        :ram => 1536,
        :cpu => 2,
        :salt_repo => "salt-repo-2017.7-1.ubuntu14.list",
        :custom_image_type => "hortonworks"
      },
      {
        :hostname => "ubuntu16",
        :box => "ubuntu/xenial64",
        :ram => 1536,
        :cpu => 2,
        :salt_repo => "salt-repo-2017.7-1.ubuntu16.list",
        :custom_image_type => "hortonworks"
      }
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
          shell.path = "scripts/salt-setup.sh"
          shell.keep_color = true
          shell.env = {
            "OPTIONAL_STATES" => machine[:optional_states],
            "CUSTOM_IMAGE_TYPE" => machine[:custom_image_type],
            "ORACLE_JDK8_URL_RPM" => machine[:oracle_jdk8_url_rpm],
            "PREINSTALLED_JAVA_HOME" => "",
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

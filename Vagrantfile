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
  config.vbguest.auto_update = false
  #config.ssh.insert_key = false

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
        :optional_states => "oracle-java",
        :custom_image_type => "hortonworks",
        :oracle_jdk8_url_rpm => "http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.rpm",
        :salt_install_os => "centos"
      },
      {
        :hostname => "centos6",
        :box => "centos/6",
        :ram => 1536,
        :cpu => 2,
        :custom_image_type => "hortonworks",
        :salt_install_os => "centos"
      },
      {
        :hostname => "debian9",
        :box => "debian/stretch64",
        :ram => 1536,
        :cpu => 2,
        :custom_image_type => "hortonworks",
        :salt_install_os => "debian"
      },
      {
        :hostname => "ubuntu14",
        :box => "ubuntu/trusty64",
        :ram => 1536,
        :cpu => 2,
        :custom_image_type => "hortonworks",
        :salt_install_os => "ubuntu"
      },
      {
        :hostname => "ubuntu16",
        :box => "ubuntu/xenial64",
        :ram => 1536,
        :cpu => 2,
        :custom_image_type => "hortonworks",
        :salt_install_os => "ubuntu"
      },
      {
        :hostname => "sles12sp3",
        :box => "mmolnar/sles12sp3",
        :ram => 1536,
        :cpu => 4,
        :custom_image_type => "hortonworks",
        :salt_install_os => "suse"
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
          shell.args = machine[:salt_install_os] + " " + machine[:box].split('/',-1)[1].gsub(/ *\d+$/, '')
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
            "SLES_REGISTRATION_CODE" => ENV['SLES_REGISTRATION_CODE'],
            "os_user" => "vagrant"
          }
        end

        # node.vm.provision :salt do |salt|
        #   salt.install_type = "stable"
        #   salt.pillar({
        #
        #     "CLUSTERMANAGER_VERSION" => "2.4",
        #     "CLUSTERMANAGER_BASEURL" => machine[:clustermanager_baseurl],
        #     "CLUSTERMANAGER_GPGKEY" => machine[:clustermanager_key],
        #     
        #     "STACK_VERSION" => machine[:stack_version],
        #     "STACK_BASEURL" => machine[:stack_baseurl],
        #     "STACK_REPOID" => machine[:stack_repoid]
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

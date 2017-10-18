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
        :salt_repo_file => "salt-repo-2016.11-6.el7.repo"
      },
      {
        :hostname => "centos6-vagrant",
        :box => "centos/6",
        :ram => 1536,
        :cpu => 2,
        :ambari_baseurl => "http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/2.x/BUILDS/2.4.1.0-22/",
        :ambari_key => "http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins",
        :hdp_stack_version => "2.5",
        :hdp_version => "2.5.0.1-60",
        :hdp_baseurl => "http://s3.amazonaws.com/dev.hortonworks.com/HDP/centos6/2.x/BUILDS/2.5.0.1-60",
        :hdp_repoid => "HDP-2.5",
        :salt_repo_file => "salt-repo-2016.11-6.el6.repo"
      },
      {
        :hostname => "wheezy-vagrant",
        :box => "debian/wheezy64",
        :ram => 1536,
        :cpu => 2,
        :ambari_baseurl => "http://s3.amazonaws.com/dev.hortonworks.com/ambari/debian7/2.x/BUILDS/2.4.1.0-22/",
        :ambari_key => "B9733A7A07513CAD",
        :salt_repo_file => "salt-repo-2016.11-6.debian7.list"
      },
      {
        :hostname => "precise-vagrant",
        :box => "ubuntu/precise64",
        :ram => 1536,
        :cpu => 2,
        :ambari_baseurl => "http://s3.amazonaws.com/dev.hortonworks.com/ambari/ubuntu12/2.x/BUILDS/2.4.1.0-22/",
        :ambari_key => "B9733A7A07513CAD",
        :salt_repo_file => "salt-repo-2016.11-6.ubuntu12.list"
      },
      {
        :hostname => "trusty-vagrant",
        :box => "ubuntu/trusty64",
        :ram => 1536,
        :cpu => 2,
        :ambari_baseurl => "http://s3.amazonaws.com/dev.hortonworks.com/ambari/ubuntu14/2.x/BUILDS/2.4.1.0-22/",
        :ambari_key => "B9733A7A07513CAD",
        :salt_repo_file => "salt-repo-2016.11-6.ubuntu14.list"
      },
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

        node.vm.synced_folder "saltstack/salt", "/srv/salt"
        node.vm.synced_folder "saltstack/pillar", "/srv/pillar"
        node.vm.synced_folder "saltstack/config", "/srv/config"
        node.vm.synced_folder "saltstack/repo", "/srv/repo"

        node.vm.provision :shell do |shell|
          shell.path = "scripts/salt-install.sh"
          shell.args = machine[:box].split('/',-1)[0] + " " + machine[:salt_repo_file] + " " + machine[:box].split('/',-1)[1].gsub(/ *\d+$/, '')
          shell.keep_color = false
        end

        node.vm.provision :shell do |shell|
          shell.inline = "salt-call --local state.highstate --file-root=/srv/salt --pillar-root=/srv/pillar --retcode-passthrough -l debug --config-dir=/srv/config"
          shell.keep_color = true
        end

        # node.vm.provision :salt do |salt|
        #   salt.install_type = "stable"
        #   salt.pillar({
        #     "os_user" => "vagrant",
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

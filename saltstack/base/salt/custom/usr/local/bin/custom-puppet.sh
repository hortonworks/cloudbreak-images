#!/bin/bash

# Install Puppet Agent and execute Puppet modules on local machine running RHEL 7.x
# Note: Process runs as root user

# Install the Puppet 6.x Repository on RHEL
rpm -Uvh https://yum.puppet.com/puppet6/puppet6-release-el-7.noarch.rpm
# Install the Puppet 5.x Repository on RHEL
# rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm

# Install the Puppet Agent to allow access to "puppet apply" command 
yum install -y puppet-agent

# Pull Puppet modules from Git
# Note: It would be preferrable to use Puppetlabs r10k but baseline does not include required Ruby version
mkdir /tmp/puppet-examples
git clone https://github.com/gitowner/puppet-examples.git /tmp/puppet-examples

cd /tmp/puppet-examples/variables

# Execute the Puppet Module in the current directory (explicit path necessary)
/opt/puppetlabs/bin/puppet apply --modulepath=. -e "include modulename"

# Cleanup
rm -rf /tmp/puppet-examples

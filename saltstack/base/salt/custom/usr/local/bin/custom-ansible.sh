#!/bin/bash

# Install Ansible and execute Ansible Playbooks on local machine using RHEL 7.x
# Note: Process runs as root user

# Install Ansible to allow access to "ansible-playbook" command
yum -y install ansible

# Pull Ansible Playbooks from Git
mkdir /tmp/ansible-playbooks
git clone https://github.com/gitowner/ansible-playbooks.git /tmp/ansible-playbooks

# Create Ansible Inventory file that evaluates all in Playbook to localhost.
# Note: Any variables needed by script go on end of line.
cat <<EOF > /tmp/ansible-local-inventory
  localhost ansible_connection=local var1="Value1"
EOF

# Execute Ansible Playbook
ansible-playbook --inventory-file=/tmp/ansible-local-inventory /tmp/ansible-playbooks/whoami/site.yml

# Cleanup
rm -rf /tmp/ansible-playbooks
rm -rf /tmp/ansible-local-inventory


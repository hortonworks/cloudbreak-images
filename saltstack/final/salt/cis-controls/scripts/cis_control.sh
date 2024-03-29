#!/bin/bash
set -ex -o pipefail -o errexit

# Remediating the system to align with the CIS L1 baseline using an SSG Ansible playbook
# The ansible playbook is available at https://github.com/AutomateCompliance/AnsibleCompliancePlaybooks/blob/main/rhel8-playbook-cis_server_l1.yml

# The list of tags of ansible tasks from the above-mentioned playbook that would break functionality, so we are skipping temporarily
SKIP_TAGS="package_firewalld_installed,service_firewalld_enabled,package_openldap-clients_removed"
EXTRA_VARS="sshd_idle_timeout_value=180"

if [ "${IMAGE_BASE_NAME}" == "freeipa" ] ; then
    SKIP_TAGS+=",service_httpd_disabled"
fi
if [ "${CLOUD_PROVIDER}" == "Azure" ]; then
    # Azure needs UDF to execute custom data: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/using-cloud-init#cloud-init-vm-provisioning-without-a-udf-driver
    SKIP_TAGS+=",kernel_module_udf_disabled"
    # Temporarily disable tmp noexec as CM fails to start REGIONSERVER. Can be removed when CM side fix is done by OPSAPS-68448
    SKIP_TAGS+=",mount_option_tmp_noexec"
fi

#Install and download what we need for the hardening
python3 -m pip install --user ansible
yum install -y git
git clone https://github.com/AutomateCompliance/AnsibleCompliancePlaybooks.git /tmp/ansible-compliance-playbooks

#Generate missing host keys as they are needed by the playbook
ssh-keygen -A

#Apply the SSG Ansible playbook
~/.local/bin/ansible-playbook -i localhost, -c local /tmp/ansible-compliance-playbooks/rhel8-playbook-cis_server_l1.yml --skip-tags $SKIP_TAGS --extra-vars "$EXTRA_VARS" | tee /tmp/cis_log.txt
chmod 644 /tmp/cis_log.txt

#Cleanup
rm -rf /tmp/ansible-compliance-playbooks
python3 -m pip uninstall -y ansible

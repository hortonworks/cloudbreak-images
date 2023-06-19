#!/bin/bash
set -xe

if [[ "${OS}" == "redhat8" && "$CLOUD_PROVIDER" != "Azure"  && "$CLOUD_PROVIDER" != "AWS_GOV" ]] ; then
    # Remediating the system to align with the CIS L1 baseline using an SSG Ansible playbook
    # The ansible playbook is available at https://github.com/AutomateCompliance/AnsibleCompliancePlaybooks/blob/main/rhel8-playbook-cis_server_l1.yml

    # The list of tags of ansible tasks from the above-mentioned playbook that would break functionality, so we are skipping temporarily
    if [ "${IMAGE_BASE_NAME}" == "freeipa" ] ; then
        SKIP_TAGS=package_firewalld_installed,service_firewalld_enabled,service_httpd_disabled
    else
        SKIP_TAGS=package_firewalld_installed,service_firewalld_enabled
    fi

    #Install and download what we need for the hardening
    python3 -m pip install --user ansible
    yum install -y git
    git clone https://github.com/AutomateCompliance/AnsibleCompliancePlaybooks.git /tmp/ansible-compliance-playbooks

    #Generate missing host keys as they are needed by the playbook
    ssh-keygen -A

    #Apply the SSG Ansible playbook
    ~/.local/bin/ansible-playbook -i localhost, -c local /tmp/ansible-compliance-playbooks/rhel8-playbook-cis_server_l1.yml --skip-tags $SKIP_TAGS | tee /tmp/cis_log.txt
    chmod 644 /tmp/cis_log.txt

    #Cleanup
    rm -rf /tmp/ansible-compliance-playbooks
    yum remove -y git
    python3 -m pip uninstall -y ansible
fi
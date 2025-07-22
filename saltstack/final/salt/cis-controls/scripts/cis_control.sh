#!/bin/bash
set -ex -o pipefail -o errexit

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }
STACK_VERSION={{ pillar['STACK_VERSION'] }}

# Remediating the system to align with the CIS L1 baseline using an SSG Ansible playbook
# The ansible playbook is available at
# https://github.com/AutomateCompliance/AnsibleCompliancePlaybooks/blob/main/rhel8-playbook-cis_server_l1.yml
# https://github.com/AutomateCompliance/AnsibleCompliancePlaybooks/blob/main/rhel8-playbook-stig.yml

ANSIBLE_PATH=/mnt/tmp/ansible

if [ "${STIG_ENABLED}" == "True" ]; then
    # The list of tags of ansible tasks from the above-mentioned playbook that would break functionality, so we are skipping temporarily
    SKIP_TAGS="package_firewalld_installed,service_firewalld_enabled" # package_openldap-clients_removed
    # We set these to a stricter 600
    SKIP_TAGS+=",file_permissions_sshd_private_key,file_permissions_sshd_pub_key"
    # We start the image burning with applying updates - however in test runs psql failed to update
    #     aws-gov-redhat8:                   fatal: [localhost]: FAILED! => {"changed": false, "failures": [], "msg": "Depsolve Error occured: \n Problem 1: cannot install the best update candidate for package postgresql11-devel-11.18-1PGDG.rhel8.x86_64\n  - nothing provides perl(IPC::Run) needed by postgresql11-devel-11.21-1PGDG.rhel8.x86_64\n Problem 2: cannot install the best update candidate for package postgresql14-devel-14.7-1PGDG.rhel8.x86_64\n  - nothing provides perl(IPC::Run) needed by postgresql14-devel-14.9-2PGDG.rhel8.x86_64\n Problem 3: problem with installed package postgresql11-devel-11.18-1PGDG.rhel8.x86_64\n  - package postgresql11-devel-11.18-1PGDG.rhel8.x86_64 requires postgresql11(x86-64) = 11.18-1PGDG.rhel8, but none of the providers can be installed\n  - cannot install both postgresql11-11.21-1PGDG.rhel8.x86_64 and postgresql11-11.18-1PGDG.rhel8.x86_64\n  - cannot install the best update candidate for package postgresql11-11.18-1PGDG.rhel8.x86_64\n  - nothing provides perl(IPC::Run) needed by postgresql11-devel-11.19-1PGDG.rhel8.x86_64\n  - nothing provides perl(IPC::Run) needed by postgresql11-devel-11.20-2PGDG.rhel8.x86_64\n  - nothing provides perl(IPC::Run) needed by postgresql11-devel-11.21-1PGDG.rhel8.x86_64\n Problem 4: problem with installed package postgresql14-devel-14.7-1PGDG.rhel8.x86_64\n  - package postgresql14-devel-14.7-1PGDG.rhel8.x86_64 requires postgresql14(x86-64) = 14.7-1PGDG.rhel8, but none of the providers can be installed\n  - cannot install both postgresql14-14.9-2PGDG.rhel8.x86_64 and postgresql14-14.7-1PGDG.rhel8.x86_64\n  - cannot install the best update candidate for package postgresql14-14.7-1PGDG.rhel8.x86_64\n  - nothing provides perl(IPC::Run) needed by postgresql14-devel-14.8-1PGDG.rhel8.x86_64\n  - nothing provides perl(IPC::Run) needed by postgresql14-devel-14.8-2PGDG.rhel8.x86_64\n  - nothing provides perl(IPC::Run) needed by postgresql14-devel-14.9-2PGDG.rhel8.x86_64", "rc": 1, "results": []}
    SKIP_TAGS+=",security_patches_up_to_date"
    # Should be re-added
    SKIP_TAGS+=",sudo_remove_nopasswd"
    # nginx fails to bind to port when selinux is enforcing
    # nginx: [emerg] bind() to 0.0.0.0:1080 failed (13: Permission denied)
    SKIP_TAGS+=",selinux_state"
    #if [ "${IMAGE_BASE_NAME}" == "freeipa" ] ; then
    #    SKIP_TAGS+=",service_httpd_disabled"
    #fi
else
    SKIP_TAGS="package_firewalld_installed,service_firewalld_enabled,package_openldap-clients_removed,configure_crypto_policy,configure_ssh_crypto_policy"
    EXTRA_VARS="sshd_idle_timeout_value=180"

    if [ "${IMAGE_BASE_NAME}" == "freeipa" ] ; then
        SKIP_TAGS+=",service_httpd_disabled"
    fi
fi

if [ "${CLOUD_PROVIDER}" == "Azure" ]; then
    # Azure needs UDF to execute custom data: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/using-cloud-init#cloud-init-vm-provisioning-without-a-udf-driver
    if [ "${STIG_ENABLED}" != "True" ]; then
        SKIP_TAGS+=",kernel_module_udf_disabled"
    fi
    if [ -n "$STACK_VERSION" ] && [ $(version $STACK_VERSION) -lt $(version "7.3.2") ]; then
    # disable tmp noexec as CM fails to start REGIONSERVER. Can be removed when CM side fix is done by OPSAPS-68448
    SKIP_TAGS+=",mount_option_tmp_noexec"
fi

#Install and download what we need for the hardening
python3 -m virtualenv --python="/usr/bin/python3.8" $ANSIBLE_PATH
source $ANSIBLE_PATH/bin/activate
python3 -m pip install ansible
yum install -y git
git clone https://github.com/AutomateCompliance/AnsibleCompliancePlaybooks.git $ANSIBLE_PATH/ansible-compliance-playbooks

#Generate missing host keys as they are needed by the playbook
ssh-keygen -A

#Apply the SSG Ansible playbook
mkdir -p /tmp/cis
chmod 777 /tmp/cis
if [ "${STIG_ENABLED}" == "True" ]; then
    ansible-playbook -i localhost, -c local $ANSIBLE_PATH/ansible-compliance-playbooks/rhel8-playbook-stig.yml --skip-tags $SKIP_TAGS | tee /tmp/cis/stig_log.txt
    chmod 777 /tmp/cis/stig_log.txt
else
    ansible-playbook -i localhost, -c local $ANSIBLE_PATH/ansible-compliance-playbooks/rhel8-playbook-cis_server_l1.yml --skip-tags $SKIP_TAGS --extra-vars "$EXTRA_VARS" | tee /tmp/cis/cis_log.txt
    chmod 777 /tmp/cis/cis_log.txt
   if [ "${RHEL_VERSION}" == "8.10" ]; then
       #Apply selinux related configuration
       ansible-playbook -i localhost, -c local $ANSIBLE_PATH/selinux.yml | tee /tmp/cis/selinux_log.txt
       chmod 777 /tmp/cis/selinux_log.txt
   fi
fi

#Clean up python stuff
deactivate
rm -rf $ANSIBLE_PATH

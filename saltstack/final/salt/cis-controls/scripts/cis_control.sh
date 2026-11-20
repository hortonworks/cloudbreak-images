#!/bin/bash
set -ex -o pipefail -o errexit

# Remediating the system to align with the CIS L1 baseline using an SSG Ansible playbook.
# CIS L1: the playbook shipped in the scap-security-guide RPM of the running OS minor version. This is the same
#   content the OpenSCAP CIS L1 scan uses (saltstack/final/salt/openscap), so the hardening and the scan match.
# STIG: https://github.com/AutomateCompliance/AnsibleCompliancePlaybooks/blob/main/rhel8-playbook-stig.yml

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
    # Network filtering is done by the cloud provider security groups / NSGs / firewall rules, not by a host firewall
    SKIP_TAGS+=",firewalld_loopback_traffic_restricted,firewalld_loopback_traffic_trusted"
    # Packages required by CDP: nginx (gateway / salt-api proxy), httpd and bind (FreeIPA), rsync, dnsmasq,
    # setroubleshoot (SELinux troubleshooting). Removing them with dnf would also remove their dependants.
    SKIP_TAGS+=",package_nginx_removed,package_httpd_removed,package_bind_removed,package_rsync_removed,package_dnsmasq_removed,package_setroubleshoot_removed"
    # Changing the shell of system accounts (uid < 1000, e.g. postgres) to nologin breaks 'su <user> -c' style calls in Salt and CDP scripts
    SKIP_TAGS+=",no_shelllogin_for_systemaccounts"
    # Images with a separate /var partition (e.g. the Azure RHEL LVM layout): nosuid on /var disables the setuid-root
    # YARN container-executor that Cloudera Manager installs under /var/lib/yarn-ce, so the NodeManager cannot start
    SKIP_TAGS+=",mount_option_var_nosuid"
    # The automation users (cloudbreak, saltuser) need passwordless sudo
    SKIP_TAGS+=",sudo_require_authentication"
    # The CIS custom crypto policy switches the system policy to DEFAULT:..., which would turn off the FIPS policy.
    # Detect FIPS from the system itself; the FIPS_MODE env var reaching this script is not reliable (Salt renders it as a
    # YAML boolean, or it can be missing).
    CURRENT_CRYPTO_POLICY=$(update-crypto-policies --show 2>/dev/null || true)
    if [ "$(cat /proc/sys/crypto/fips_enabled 2>/dev/null)" == "1" ] || [[ "${CURRENT_CRYPTO_POLICY}" == FIPS* ]] \
        || [ "$(echo "${FIPS_MODE}" | tr "[:upper:]" "[:lower:]")" == "true" ]; then
        echo "FIPS detected (FIPS_MODE='${FIPS_MODE}', crypto policy '${CURRENT_CRYPTO_POLICY}'), skipping the CIS custom crypto policy"
        SKIP_TAGS+=",configure_custom_crypto_policy_cis"
    else
        echo "No FIPS (FIPS_MODE='${FIPS_MODE}', crypto policy '${CURRENT_CRYPTO_POLICY}'), applying the CIS custom crypto policy"
    fi
    # AIDE is turned off: a database built at image burn time is not a meaningful baseline for the provisioned node,
    # building it over the pre-warmed parcels slows the burn down a lot, and the daily 'aide --check' adds I/O load on every node
    SKIP_TAGS+=",aide,package_aide_installed,aide_build_database,aide_check_audit_tools,aide_periodic_cron_checking"
    # 235 is the max value for ClientAliveInterval allowed by Azure Marketplace
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
fi

# The draft RHEL 9 playbook broke /etc/bashrc with an unanchored 'umask.*' regex (CB-31377). The SSG RPM playbook only
# replaces whole 'umask NNN' statements, so the rule is applied again for CIS L1; STIG still uses the old playbook.
if [ "${OS}" == "redhat9" ] && [ "${STIG_ENABLED}" == "True" ]; then
    SKIP_TAGS+=",accounts_umask_etc_bashrc"
fi

SKIP_TAGS+="{{ additional_tags }}"

#Install and download what we need for the hardening
python3 -m virtualenv $ANSIBLE_PATH
source $ANSIBLE_PATH/bin/activate
case ${OS} in
  "redhat8")
    PLAYBOOK="rhel8-playbook"
    python3 -m pip install ansible
    ;;

  "redhat9")
    PLAYBOOK="rhel9-playbook"
    python3 -m pip install ansible "ansible-core==2.13"
    ;;
esac

if [ "${STIG_ENABLED}" == "True" ]; then
    yum install -y git
    git clone https://github.com/AutomateCompliance/AnsibleCompliancePlaybooks.git $ANSIBLE_PATH/ansible-compliance-playbooks
else
    SSG_PRE_INSTALLED=$(rpm -q scap-security-guide >/dev/null 2>&1 && echo true || echo false)
    yum install -y scap-security-guide
    CIS_PLAYBOOK=/usr/share/scap-security-guide/ansible/$PLAYBOOK-cis_server_l1.yml
    head -n 20 $CIS_PLAYBOOK | grep -E "Benchmark|Version" || true
fi

#Generate missing host keys as they are needed by the playbook
ssh-keygen -A

#Apply the SSG Ansible playbook
mkdir -p /tmp/cis
chmod 700 /tmp/cis

if [ "${STIG_ENABLED}" == "True" ]; then
    ansible-playbook -i localhost, -c local $ANSIBLE_PATH/ansible-compliance-playbooks/$PLAYBOOK-stig.yml --skip-tags $SKIP_TAGS | tee /tmp/cis/stig_log.txt
    chmod 600 /tmp/cis/stig_log.txt
else
    ansible-playbook -i localhost, -c local $CIS_PLAYBOOK --skip-tags $SKIP_TAGS --extra-vars "$EXTRA_VARS" | tee /tmp/cis/cis_log.txt
    chmod 600 /tmp/cis/cis_log.txt
    # CIS 5.4.2.4: root has no password (SSH key + sudo access only), make sure the account is explicitly locked
    usermod -L root
    # Make sure AIDE is not left on the image (e.g. pulled in by the base image)
    if rpm -q aide >/dev/null 2>&1; then
        yum remove -y aide
        rm -rf /var/lib/aide
    fi
    if [ "${SSG_PRE_INSTALLED}" == "false" ]; then
        yum remove -y scap-security-guide
    fi
fi

#Clean up python stuff
deactivate
rm -rf $ANSIBLE_PATH

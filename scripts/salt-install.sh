#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}

set -ex -o pipefail -o errexit

function install_salt_with_pip3() {

  echo "Installing salt with version: $SALT_VERSION"
  python3 -m pip install --upgrade pip
  python3 -m pip install virtualenv
  python3 -m pip install checkipaconsistency==2.7.10
  python3 -m pip install 'PyYAML>=5.1' --ignore-installed

  # OS specific packages required for Salt go here
  if [ "${OS}" == "redhat8" ] ; then
    python3 -m pip install distro
  elif [ "${OS}" == "redhat7" ] ; then
    echo "No OS specific packages required for RedHat 7"
  elif [ "${OS}" == "centos7" ] ; then
    echo "No OS specific packages required for CentOS 7"
  fi

  # Anything installed after this point will end up Salt's venv
  mkdir ${SALT_PATH}
  python3 -m virtualenv ${SALT_PATH}
  source ${SALT_PATH}/bin/activate
  python3 -m pip install --upgrade pip

  # Some packages can't be installed via salt_requirements.txt (don't ask why)
  python3 -m pip install pbr
  python3 -m pip install -r /tmp/salt_requirements.txt
}

function install_with_yum() {
  update_yum_repos

  if [ "${OS_TYPE}" == "redhat8" ] ; then
    yum install -y redhat-lsb-core
    yum update -y python3
  else
    yum update -y python
  fi

  yum install -y yum-utils yum-plugin-versionlock
  yum clean metadata
  enable_epel_repository
  yum groupinstall -y 'Development Tools'
  
  install_python_pip
  
  ### Do we need this section at all? Probably not...
  if [ ! -z $(grep "^exclude=" /etc/yum.conf) ]; then
    sed -i 's/^exclude=.*$/& salt/g' /etc/yum.conf
  else
    echo "exclude=salt" >> /etc/yum.conf
  fi
  ###

  install_salt_with_pip3
  
  create_temp_minion_config
}

function update_yum_repos() {
  if [[ "${OS}" == "redhat8" ]]; then
    # Remove RHEL official repos and use the internal mirror in case of RHEL8
    if [[ "${CLOUD_PROVIDER}" != "AWS_GOV" ]]; then
      if [[ "${ARCHITECTURE}" != "arm64" ]]; then
        # Internal repo is not yet available for AWS_GOV and arm64 images
        RHEL_VERSION=$(cat /etc/redhat-release | grep -oP "[0-9\.]*")
        RHEL_VERSION=${RHEL_VERSION/.0/}
        REPO_FILE=rhel${RHEL_VERSION}_cldr_mirrors.repo
        rm /etc/yum.repos.d/*.repo -f
        curl https://mirror.infra.cloudera.com/repos/rhel/server/8/${RHEL_VERSION}/${REPO_FILE} --fail > /etc/yum.repos.d/${REPO_FILE}
      fi

      # Workaround on resolving the hostname as for some reason the DNS can't resolve it at provision time
      if [ "${IMAGE_BURNING_TYPE}" == "base" ] ; then
        if [[ "${CLOUD_PROVIDER}" != "Azure" ]] ; then
          yum install -y dnsutils
        fi
        echo "$(dig +short mirror.infra.cloudera.com A | tail -1) mirror.infra.cloudera.com" >> /etc/hosts
      fi
    fi
  else
    # Workaround based on the official documentation: https://cloud.google.com/compute/docs/troubleshooting/known-issues#known_issues_for_linux_vm_instances
    if [ "${CLOUD_PROVIDER}" == "GCP" ]; then
      sudo sed -i 's/repo_gpgcheck=1/repo_gpgcheck=0/g' /etc/yum.repos.d/google-cloud.repo
    fi

    sudo rm -rf /etc/yum.repos.d/CentOS*.repo

    sudo cat <<EOF >/etc/yum.repos.d/centos7-vault.repo
[base]
name=CentOS-7 - Base
baseurl=https://vault.centos.org/7.9.2009/os/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-7 - Updates
baseurl=https://vault.centos.org/7.9.2009/updates/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-7 - Extras
baseurl=https://vault.centos.org/7.9.2009/extras/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[sclo]
name=CentOS-7 - SCLO
baseurl=https://vault.centos.org/7.9.2009/sclo/x86_64/sclo/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[sclo-rh]
name=CentOS-7 - SCLO RH
baseurl=https://vault.centos.org/7.9.2009/sclo/x86_64/rh/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
EOF

    sudo cat <<EOF >/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2.0.22 (GNU/Linux)

mQENBFYM/AoBCADR9Q5cb+H5ndx+QkzNBQ88wcD+g112yvnHNlSiBMOnNEGHuKPJ
tujZ+eWXP3K6ucJckT91WxfQ2fxPr9jQ0xpZytcHcZdTfn3vKL9+OwR0npp+qmcz
rK8/EzVz/SWSgBQ5xT/HUvaeoVAbzBHSng0r2njnBAqABKAoTxgyRGKSCWduKD32
7PF2ZpqeDFFhd99Ykt6ar8SlV8ToqH6F7An0ILeejINVbHUxd6+wsbpcOwQ4mGAa
/CPXeqqLGj62ASBv36xQr34hlN/9zQMViaKkacl8zkuvwhuHf4b4VlGVCe6VILpQ
8ytKMV/lcg7YpMfRq4KVWBjCwkvk6zg6KxaHABEBAAG0aENlbnRPUyBTb2Z0d2Fy
ZUNvbGxlY3Rpb25zIFNJRyAoaHR0cHM6Ly93aWtpLmNlbnRvcy5vcmcvU3BlY2lh
bEludGVyZXN0R3JvdXAvU0NMbykgPHNlY3VyaXR5QGNlbnRvcy5vcmc+iQE5BBMB
AgAjBQJWDPwKAhsDBwsJCAcDAgEGFQgCCQoLBBYCAwECHgECF4AACgkQTrhOcfLu
nVXNewgAg7RVclomjTY4w80XiztUuUaFlCHyR76KazdaGfx/8XckWH2GdQtwii+3
Tg7+PT2H0Xyuj1aod+jVTPXTPVUr+rEHAjuNDY+xyAJrNljoOHiz111zs9pk7PLX
CPwKWQLnmrcKIi8v/51L79FFsUMvhClTBdLUQ51lkCwbcXQi+bOhPvZTVbRhjoB/
a9z0d8t65X16zEzE7fBhnVoj4xye/MPMbTH41Mv+FWVciBTuAepOLmgJ9oxODliv
rgZa28IEWkvHQ8m9GLJ0y9mI6olh0cGFybnd5y4Ss1cMttlRGR4qthLhN2gHZpO9
2y4WgkeVXCj1BK1fzVrDMLPbuNNCZQ==
=UtPD
-----END PGP PUBLIC KEY BLOCK-----    
EOF

    sudo ls /etc/yum.repos.d/*.repo
  fi
}

function enable_epel_repository() {
  if [ "${OS}" == "redhat8" ] ; then
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  elif [ "${OS}" == "centos7" ] ; then
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  fi
}

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function centos7_update_python27() {
  echo "Updating Python 2.7..."
  yum update -y python

  echo PYTHON27=$(yum list installed | grep ^python\\.x86_64 | grep -oi " [^\s]* " | xargs) >> /tmp/python_install.properties
}

function centos7_install_python36() {
  echo "Installing Python 3.6 with dependencies..."
  # yum -y install centos-release-scl
  yum install -y python36 python36-pip python36-devel python36-setuptools

  echo PYTHON36=$(yum list installed | grep ^python3\\.x86_64 | grep -oi " [^\s]* " | xargs) >> /tmp/python_install.properties
}

function centos7_install_python38() {
  echo "Installing Python 3.8 with dependencies..."
  # yum -y install centos-release-scl
  yum -y install openssl-devel libffi-devel bzip2-devel rh-python38-python-pip rh-python38-python-libs rh-python38-python-devel rh-python38-python-cffi rh-python38-python-lxml rh-python38-python-psycopg2

  echo PYTHON38=$(yum list installed | grep ^rh-python38-python\\.x86_64 | grep -oi " [^\s]* " | xargs) >> /tmp/python_install.properties
}

function redhat8_update_python36() {
  echo "Installing python3-devel (the rest should be already installed in case of RHEL8)..."
  yum update -y python3 || yum update -y python36
  yum install -y python3-devel
  
  echo PYTHON36=$(yum list installed | grep ^python36\\. | grep -oi " [^\s]* " | xargs) >> /tmp/python_install.properties
  
  echo "RedHat8 update python36. OS: $OS CLOUD_PROVIDER: $CLOUD_PROVIDER"
  if [ "${OS}" == "redhat8" ] &&  [ "${CLOUD_PROVIDER}" == "YARN" ]; then
    update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
    update-alternatives --install /usr/bin/python python /usr/bin/python3.6 2
    alternatives --set python /usr/bin/python3.6
    python -m pip install --upgrade pip
  else
    # CM agent needs this to work
    alternatives --set python /usr/bin/python3
  fi

  # Required dependency for IdM
  pip3 install pyasn1-modules
}

function redhat8_install_python38() {
  echo "Installing Python 3.8 with dependencies..."
  yum install -y python38
  yum install -y python38-devel python38-libs python38-cffi python38-lxml

  echo PYTHON38=$(yum list installed | grep ^python38\\. | grep -oi " [^\s]* " | xargs) >> /tmp/python_install.properties

  # We need to create this "hack", because Saltstack's pip.installed only accepts a pip/pip3
  # wrapper, but apparently can't call "python3 -m pip", so without this, we can't install
  # packages to the non-default python3 installation.
  cat <<EOF >/usr/local/bin/pip3.8
#!/bin/bash
/usr/bin/python3.8 -m pip "\$@"
EOF
  chmod +x /usr/local/bin/pip3.8
}

function redhat8_install_python39() {
  echo "Installing Python 3.9 with dependencies..."
  yum install -y python39
  yum install -y python39-devel python39-libs python39-cffi python39-lxml

  echo PYTHON39=$(yum list installed | grep ^python39\\. | grep -oi " [^\s]* " | xargs) >> /tmp/python_install.properties

  # We need to create this "hack", because Saltstack's pip.installed only accepts a pip/pip3
  # wrapper, but apparently can't call "python3 -m pip", so without this, we can't install
  # packages to the non-default python3 installation.
  cat <<EOF >/usr/local/bin/pip3.9
#!/bin/bash
/usr/bin/python3.9 -m pip "\$@"
EOF
  chmod +x /usr/local/bin/pip3.9
}

function redhat8_install_python311() {
  echo "Installing Python 3.11 with dependencies..."
  yum install -y python3.11 python3.11-pip python3.11-devel python3.11-libs python3.11-cffi python3.11-lxml

  echo PYTHON311=$(yum list installed | grep ^python3\\.11\\. | grep -oi " [^\s]* " | xargs) >> /tmp/python_install.properties

  # We need to create this "hack", because Saltstack's pip.installed only accepts a pip/pip3
  # wrapper, but apparently can't call "python3 -m pip", so without this, we can't install
  # packages to the non-default python3 installation.
  cat <<EOF >/usr/local/bin/pip3.11
#!/bin/bash
/usr/bin/python3.11 -m pip "\$@"
EOF
  chmod +x /usr/local/bin/pip3.11
}


function install_python_pip() {
  
  yum install -y openldap-devel
  
  if [ "${OS}" == "redhat8" ] ; then
    redhat8_update_python36
    redhat8_install_python38
    redhat8_install_python39
    redhat8_install_python311
  elif [ "${OS}" == "centos7" ] ; then
    centos7_update_python27
    centos7_install_python36
    centos7_install_python38
  fi
}

function create_temp_minion_config() {
  echo "requests_lib: True" > /tmp/minion
  echo "backend_requests: True" >> /tmp/minion
}

: ${SALT_INSTALL_OS:=$1}

echo "Installing Salt on ${SALT_INSTALL_OS}"
echo "Network interfaces: $(ifconfig)"
echo "Public address: $(curl -s https://checkip.amazonaws.com)"

case ${SALT_INSTALL_OS} in
  centos|redhat)
    echo "Install with yum"
    install_with_yum
    ;;
  *)
  echo "Unsupported platform:" $1
  exit 1
  ;;
esac

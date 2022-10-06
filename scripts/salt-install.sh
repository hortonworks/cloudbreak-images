#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}

set -ex -o pipefail -o errexit

function install_salt_for_centos7_with_pip3() {

  echo "Installing salt with version: $SALT_VERSION for CentOS 7"
  python3 -m pip install --upgrade pip
  python3 -m pip install virtualenv

  # fix pip3 not installing virtualenv for root
  # ln -s /usr/local/bin/virtualenv /usr/bin/virtualenv

  mkdir ${SALT_PATH}
  python3 -m virtualenv ${SALT_PATH}
  source ${SALT_PATH}/bin/activate

  # can't install these via salt_requirements.txt and I dunno why...
  python3 -m pip install distro

  python3 -m pip install -r /tmp/salt_requirements.txt
}


function install_salt_with_pip() {
  echo "Installing salt with version: $SALT_VERSION for RHEL 7 / RHEL 8"
  pip install --upgrade pip
  pip install virtualenv

  # fix pip3 not installing virtualenv for root
  if [ "${OS}" != "redhat7" ] ; then
    ln -s /usr/local/bin/virtualenv /usr/bin/virtualenv
  else
    echo "source scl_source enable rh-python38; python3.8 -m virtualenv \$@" > /usr/bin/virtualenv
    chmod +x /usr/bin/virtualenv
  fi
  mkdir ${SALT_PATH}
  virtualenv ${SALT_PATH}
  source ${SALT_PATH}/bin/activate
  # can't install these via salt_requirements.txt and I dunno why...
  if [ "${OS}" == "redhat7" ] ; then
    pip install pbr
  fi
  pip install --upgrade pip
  pip install -r /tmp/salt_requirements.txt
}

function install_with_yum() {
  # Workaround based on the official documentation: https://cloud.google.com/compute/docs/troubleshooting/known-issues#known_issues_for_linux_vm_instances
  if [ "${CLOUD_PROVIDER}" == "GCP" ]; then
    sudo sed -i 's/repo_gpgcheck=1/repo_gpgcheck=0/g' /etc/yum.repos.d/google-cloud.repo
  fi

  # The host http://olcentgbl.trafficmanager.net keeps causing problems, so we re-enable the default mirrorlist instead.
  # Also, this is the recommended way for YUM updates to work anyway. https://wiki.centos.org/PackageManagement/Yum/FastestMirror
  if [ "${CLOUD_PROVIDER}" == "Azure" ]; then
    if [ "${OS}" == "centos7" ] ; then
      sudo sed -i 's/\#mirrorlist/mirrorlist/g' /etc/yum.repos.d/CentOS-Base.repo
      sudo sed -i 's/baseurl/\#baseurl/g' /etc/yum.repos.d/CentOS-Base.repo
    fi
  fi
  
  yum update -y python
  yum install -y yum-utils yum-plugin-versionlock
  yum clean metadata
  enable_epel_repository
  yum groupinstall -y 'Development Tools'
  install_python_pip

  if [ ! -z $(grep "^exclude=" /etc/yum.conf) ]; then
    sed -i 's/^exclude=.*$/& salt/g' /etc/yum.conf
  else
    echo "exclude=salt" >> /etc/yum.conf
  fi

  if [ "${OS}" == "centos7" ] ; then
    install_salt_for_centos7_with_pip3
  elif [ "${OS}" == "redhat7" ] ; then
    install_salt_with_pip
  elif [ "${OS}" == "redhat8" ] ; then    
    install_salt_with_pip
  fi  
  create_temp_minion_config
}

function enable_epel_repository() {
    yum install -y epel-release
}

function install_python_pip() {

  echo "Installing python38 with deps"
  if [ "${OS}" == "redhat7" ] ; then
    yum-config-manager --enable rhscl
    yum -y install rh-python38
    # pip workaround
    echo "source scl_source enable rh-python38; python3.8 -m pip \$@" > /usr/bin/pip
    chmod +x /usr/bin/pip
  elif [ "${OS}" == "centos7" ] ; then
    yum -y install centos-release-scl
    yum -y install openssl-devel libffi-devel bzip2-devel rh-python38-python-pip rh-python38-python-libs rh-python38-python-devel rh-python38-python-cffi rh-python38-python-lxml

    #find / -name pip3

    # We need this because the rh-python38-* packages apparently use a non-standard location... duh!
    #ln -s /opt/rh/rh-python38/root/usr/bin/pip3 /bin/pip3
    #ln -s /opt/rh/rh-python38/root/usr/bin/pip3 /bin/pip
    ls -la /opt/rh/rh-python38/root/usr/bin/

    PATH=$PATH:/opt/rh/rh-python38/root/usr/local/bin:/opt/rh/rh-python38/root/usr/bin
    cat >> /etc/profile.d/rh-python3.sh <<EOF
      export PATH=$PATH:/opt/rh/rh-python38/root/usr/local/bin:/opt/rh/rh-python38/root/usr/bin
EOF

  else
    # I wonder what else we have that uses Python 2... probably nothing?
    yum install -y python-pip python-devel
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

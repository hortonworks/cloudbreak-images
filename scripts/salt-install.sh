#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}

set -ex -o pipefail -o errexit

function install_salt_for_rhel8_with_pip38() {
  echo "Installing salt with version: $SALT_VERSION for CentOS 7"
  python3.8 -m pip install --upgrade pip
  python3.8 -m pip install virtualenv

  # fix pip3 not installing virtualenv for root
  # ln -s /usr/local/bin/virtualenv /usr/bin/virtualenv

  mkdir ${SALT_PATH}
  python3.8 -m virtualenv ${SALT_PATH}
  source ${SALT_PATH}/bin/activate

  # can't install these via salt_requirements.txt and I dunno why...
  python3.8 -m pip install distro

  python3.8 -m pip install -r /tmp/salt_requirements.txt
}

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
  echo "Installing salt with version: $SALT_VERSION  for RHEL 7 / RHEL 8"
  pip install --upgrade pip
  pip install virtualenv

  # fix pip3 not installing virtualenv for root
  if [ "${OS}" != "redhat7" && "${OS}" != "redhat8" ] ; then
    ln -s /usr/local/bin/virtualenv /usr/bin/virtualenv
  else
    echo "source scl_source enable rh-python38; python3.8 -m virtualenv \$@" > /usr/bin/virtualenv
    chmod +x /usr/bin/virtualenv
  fi
  mkdir ${SALT_PATH}
  virtualenv ${SALT_PATH}
  source ${SALT_PATH}/bin/activate
  if [ "${OS}" == "redhat7" || "${OS}" == "redhat8" ] ; then
    # can't install this via salt_requirements.txt and I dunno why...
    pip install pbr
    python3.8 -m pip install distro
  fi
  pip install --upgrade pip
  pip install -r /tmp/salt_requirements.txt
}

function install_salt_with_pip3() {

  echo "Installing salt with version: $SALT_VERSION"
  python3.8 -m pip install --upgrade pip
  python3.8 -m pip install virtualenv

  mkdir ${SALT_PATH}
  python3.8 -m virtualenv ${SALT_PATH}
  source ${SALT_PATH}/bin/activate

  python3.8 -m pip install --upgrade pip
  python3.8 -m pip install checkipaconsistency==2.7.10
  python3.8 -m pip install pbr  
  python3.8 -m pip install -r /tmp/salt_requirements.txt
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

  if [ "${OS_TYPE}" == "redhat8" ] ; then  
    yum update -y python3.8
  else
    yum update -y python
  fi

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
    install_salt_for_rhel8_with_pip38
  fi  
  create_temp_minion_config
}

function enable_epel_repository() {
  if [ "${OS}" == "redhat8" ] ; then
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  elif [ "${OS}" == "amazonlinux2" ] || [ "${OS}" == "redhat7" ] ; then
    curl https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -o epel-release-latest-7.noarch.rpm && yum install --nogpgcheck -y ./epel-release-latest-7.noarch.rpm
  elif [ "${OS}" == "amazonlinux" ] ; then
    yum-config-manager --enable epel
  elif [ "${OS_TYPE}" == "redhat6" ] ; then
    curl https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm -o epel-release-latest-6.noarch.rpm && yum install -y ./epel-release-latest-6.noarch.rpm
  else
    yum install -y epel-release
  fi
}

function install_python_pip() {

  echo "Installing python38 with deps"
  if [ "${OS}" == "redhat8" ] ; then
    echo "Installing python3-devel (the rest should be already installed in case of RHEL8)"
    yum install -y python38-devel
    python3.8 -m pip install distro
  elif [ "${OS}" == "redhat7" ] ; then
    yum-config-manager --enable rhscl
    yum -y install rh-python38
    # pip workaround
    echo "source scl_source enable rh-python38; python3.8 -m pip \$@" > /usr/bin/pip
    chmod +x /usr/bin/pip
  elif [ "${OS}" == "centos7" ] ; then
    yum -y install centos-release-scl
    yum -y install openssl-devel libffi-devel bzip2-devel rh-python38-python-pip rh-python38-python-libs rh-python38-python-devel rh-python38-python-cffi rh-python38-python-lxml
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

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

  # OS specific required packages go here
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

function enable_epel_repository() {
  if [ "${OS}" == "redhat8" ] ; then
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  elif [ "${OS}" == "redhat7" ] ; then
    curl https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -o epel-release-latest-7.noarch.rpm && yum install --nogpgcheck -y ./epel-release-latest-7.noarch.rpm
  elif [ "${OS}" == "centos7" ] ; then
    yum install -y epel-release
  fi
}

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function install_python_pip() {
  
  yum install -y openldap-devel
  
  # For now, FreeIPA images have to be left with Python 3.6 and 2.7
  if [ "${IMAGE_BASE_NAME}" == "freeipa" ] ; then
    if [ "${OS}" == "redhat8" ] ; then
      echo "Installing python3-devel (the rest should be already installed in case of RHEL8)..."
      yum update -y python3
      yum install -y python3-devel

    elif [ "${OS}" == "redhat7" ] ; then
      echo "Updating Python 2.7..."
      yum update -y python
      echo "Installing Python 3.6 with dependencies..."
      yum-config-manager --enable rhscl
      yum -y install rh-python36
      # pip workaround
      echo "source scl_source enable rh-python36; python3.6 -m pip \$@" > /usr/bin/pip
      chmod +x /usr/bin/pip

    elif [ "${OS}" == "centos7" ] ; then
      yum -y install centos-release-scl
      echo "Updating Python 2.7..."
      yum update -y python
      echo "Installing Python 3.6 with dependencies..."
      yum install -y python36 python36-pip python36-devel python36-setuptools
    fi

  # For images with Runtime 7.2.15 and below we only support RHEL7 and CentOS7 with Python 2.7 and 3.6
  elif [ $(version $STACK_VERSION) -le $(version "7.2.16") ]; then
    if [ "${OS}" == "redhat7" ] ; then
      echo "Updating Python 2.7..."
      yum update -y python
      echo "Installing Python 3.6 with dependencies..."
      yum-config-manager --enable rhscl
      yum -y install rh-python36
      # pip workaround
      echo "source scl_source enable rh-python36; python3.6 -m pip \$@" > /usr/bin/pip
      chmod +x /usr/bin/pip

    elif [ "${OS}" == "centos7" ] ; then
      yum -y install centos-release-scl
      echo "Updating Python 2.7..."
      yum update -y python
      echo "Installing Python 3.6 with dependencies..."
      yum install -y python36 python36-pip python36-devel python36-setuptools
    fi

  # For images with Runtime 7.2.16 and above, we need Python 3.8, but sadly the package
  # names depend on the OS
  else
    if [ "${OS}" == "redhat8" ] ; then
      echo "Upgrading Python 3.6 to Python 3.8..."
      yum remove -y python3
      yum install -y python38
      yum install -y python38-devel python38-libs python38-cffi python38-lxml python38-psycopg2
      alternatives --set python /usr/bin/python3.8

    elif [ "${OS}" == "redhat7" ] ; then
      echo "Installing Python 3.8 with dependencies..."
      yum-config-manager --enable rhscl
      yum -y install rh-python38
      # pip workaround
      echo "source scl_source enable rh-python38; python3.8 -m pip \$@" > /usr/bin/pip
      chmod +x /usr/bin/pip

    elif [ "${OS}" == "centos7" ] ; then
      echo "Installing Python 3.8 with dependencies..."
      yum -y install centos-release-scl
      yum -y install openssl-devel libffi-devel bzip2-devel rh-python38-python-pip rh-python38-python-libs rh-python38-python-devel rh-python38-python-cffi rh-python38-python-lxml rh-python38-python-psycopg2

      # We need this because the rh-python38-* packages apparently use a non-standard location... duh!
      echo "Updating /etc/environment for Python 3.8..."
      PATH=$PATH:/opt/rh/rh-python38/root/usr/local/bin:/opt/rh/rh-python38/root/usr/bin
      echo "PATH=\"$PATH\"" >>/etc/environment
      cat /etc/environment
    fi
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

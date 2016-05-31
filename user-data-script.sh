#!/bin/bash

: ${HDP_VERSION:=}

set -eo pipefail
if [[ "$TRACE" ]]; then
    : ${START_TIME:=$(date +%s)}
    export START_TIME
    export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '
    set -x
fi

: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

update_centos() {
  # Use the same CentOS Base yum repo on CentOS images
  if grep "Amazon Linux AMI" /etc/issue &> /dev/null; then
    rm -fv /etc/yum.repos.d/CentOS-Base.repo
  fi
  
  if grep "Red Hat Enterprise Linux Server" /etc/redhat-release &> /dev/null; then
    rm -f /etc/yum.repos.d/CentOS-Base.repo
    # epel release not available on Redhat
    yum -y install wget
    wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/${EPEL}.noarch.rpm
    rpm -Uvh ${EPEL}.noarch.rpm
  fi
  yum clean all
  yum update -y
}

permissive_iptables() {
  # need to install iptables-services, othervise the 'iptables save' command will not be available
  yum -y install iptables-services net-tools

  iptables --flush INPUT
  iptables --flush FORWARD
  service iptables save
}

disable_selinux() {
  if [ $(getenforce) != "Disabled" ]; then
    setenforce 0;
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
  fi
}

enable_ipforward() {
  sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
}

install_utils() {
  if grep "Amazon Linux AMI" /etc/issue &> /dev/null; then
    yum-config-manager --enable epel
  else
   yum -y install epel-release
  fi
  
  yum -y install unzip curl wget git bind-utils ntp tmux bash-completion nginx haveged

  chkconfig haveged on

  # https://hortonworks.jira.com/browse/BUG-41308
  yum -y remove snappy
  yum -y install snappy-devel

  if ! [[ $PACKER_BUILDER_TYPE =~ azure ]]; then
    yum install -y cloud-init
  fi

  curl -Lo /sbin/cert-tool https://github.com/ehazlett/certm/releases/download/v0.0.1/cert-tool_linux_amd64 && chmod +x /sbin/cert-tool
  curl -o /usr/bin/jq http://stedolan.github.io/jq/download/linux64/jq && chmod +x /usr/bin/jq
}

install_kerberos() {
  yum -y install krb5-server krb5-libs krb5-workstation
}

reset_hostname() {
  echo "Avoid pre-assigned hostname"
  rm -vf /etc/hostname
}

grant-sudo-to-os-user() {
  if grep "Amazon Linux AMI" /etc/issue &> /dev/null; then
    echo "No need to grant sudo to OS_USER on Amazon Linux"
  else
    echo "$OS_USER ALL=NOPASSWD: ALL" > /etc/sudoers.d/$OS_USER
    chmod o-r /etc/sudoers.d/$OS_USER
  fi
}

install_salt() {
  # salt install for orchestrating the cluster
  yum -y install salt-master salt-api salt-minion && yum clean all
  adduser saltuser && usermod -G wheel saltuser && echo "saltuser:saltpass"| chpasswd
  if grep "Amazon Linux AMI" /etc/issue &> /dev/null; then
    chkconfig salt-master off
    chkconfig salt-minion off
    chkconfig salt-api off
  fi
}

install_consul() {
  # download consul from hashicorp
  curl -Lo /tmp/shared/consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
  cd /tmp/shared && unzip /tmp/shared/consul.zip && rm /tmp/shared/consul.zip
  mv /tmp/shared/consul /usr/sbin/consul
  chmod +x /usr/sbin/consul

  sed -i "/^hosts:/ s/ *files dns/ dns files/" /etc/nsswitch.conf
}

install_bootstrap() {
  # download salt-bootstrap from github
  curl -Lo /tmp/shared/salt-bootstrap_${CLOUDBREAK_BOOTSTRAP_VERSION}_Linux_x86_64.tgz https://github.com/sequenceiq/salt-bootstrap/releases/download/v${CLOUDBREAK_BOOTSTRAP_VERSION}/salt-bootstrap_${CLOUDBREAK_BOOTSTRAP_VERSION}_Linux_x86_64.tgz
  tar -zxf /tmp/shared/salt-bootstrap_${CLOUDBREAK_BOOTSTRAP_VERSION}_Linux_x86_64.tgz -C /usr/sbin/

  if grep "Amazon Linux AMI" /etc/issue &> /dev/null; then
    mv /etc/systemd/system/salt-bootstrap /etc/init.d/salt-bootstrap
    chmod +x /etc/init.d/salt-bootstrap
    chkconfig salt-bootstrap on
  else
    chmod +x /usr/sbin/salt-bootstrap
    systemctl enable salt-bootstrap
  fi
}

install_jdk() {
  export JDK_ARTIFACT=jdk-7u67-linux-x64.tar.gz
  mkdir -p /usr/jdk64 && cd /usr/jdk64 
  curl -LO http://public-repo-1.hortonworks.com/ARTIFACTS/$JDK_ARTIFACT 
  tar -xf $JDK_ARTIFACT
  rm -f $JDK_ARTIFACT

  curl -LO http://public-repo-1.hortonworks.com/ARTIFACTS/UnlimitedJCEPolicyJDK7.zip
  unzip UnlimitedJCEPolicyJDK7.zip
  mv -f UnlimitedJCEPolicy/*jar /usr/jdk64/jdk1.7.0_67/jre/lib/security/
  rm -f UnlimitedJCEPolicyJDK7.zip
}

install_ambari() {
  yum -y install ambari-server ambari-agent
  if grep "Amazon Linux AMI" /etc/issue &> /dev/null; then
    chkconfig ambari-server off
    chkconfig ambari-agent off
  else 
    rm -rf /etc/init.d/ambari-agent 
    find /etc/rc.d/rc* -name "*ambari*" | xargs rm -v
  fi
  
  IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
  echo "$IP $(hostname).mydomain $(hostname)" >> /etc/hosts
  ambari-server setup --silent --java-home /usr/jdk64/jdk1.7.0_67/
  ambari-server start
  echo Waiting for Ambari server to start
  while [[ ! "RUNNING" == "$(curl -s -u admin:admin -H "Accept: text/plain" localhost:8080/api/v1/check)" ]]; do 
    echo -n .
    sleep 1; 
  done
  ambari-server stop
  ambari-server reset --verbose --silent
  sed -i "s/$IP *.*//g" /etc/hosts
}

install_hdp() {
  if [[ -n "$HDP_VERSION" ]]; then
    cd /etc/yum.repos.d
    mv HDP-$HDP_VERSION.repo HDP.repo
    ls -1 | grep -v HDP-UTILS.repo | grep "HDP-" | xargs rm -vf || :
    yum -y install smartsense-hst
    yum -y install $(yum list available | awk '$3~/HDP-[1-9]/ && $1~/^(accumulo|atlas|datafu|falcon|flume|hadoop|hadooplzo|hbase|hive|kafka|knox|livy|mahout|oozie|phoenix|pig|ranger|slider|spark|sqoop|storm|tez|zeppelin|zookeeper)_[0-9]_[0-9]/ {print $1}')
  fi
}

configure_console() {
  export GRUB_CONFIG='/etc/default/grub'
  if [ -f "$GRUB_CONFIG" ] && grep "GRUB_CMDLINE_LINUX" "$GRUB_CONFIG" | grep -q "console=tty0"; then
    # we want ttyS0 as the default console output, the default RedHat AMI on AWS sets tty0 as well
    sed -i -e '/GRUB_CMDLINE_LINUX/ s/ console=tty0//g' "$GRUB_CONFIG"
    grub2-mkconfig -o /boot/grub2/grub.cfg
  fi
}

extend_rootfs() {
  if [[ $PACKER_BUILDER_TYPE == "googlecompute" ]]; then
      yum -y install cloud-utils-growpart

      root_fs_device=$(mount | grep ' / ' | cut -d' ' -f 1 | sed s/1//g)
      growpart $root_fs_device 1 || :
      xfs_growfs / || :
  fi
}

modify_waagent() {
  if [ -f /etc/waagent.conf ]; then
    cp /etc/waagent.conf /etc/waagent.conf.bak
    sed -i 's/Provisioning.SshHostKeyPairType.*/Provisioning.SshHostKeyPairType=ecdsa/' /etc/waagent.conf
    sed -i 's/Provisioning.DecodeCustomData.*/Provisioning.DecodeCustomData=y/' /etc/waagent.conf
    sed -i 's/Provisioning.ExecuteCustomData.*/Provisioning.ExecuteCustomData=y/' /etc/waagent.conf
    diff /etc/waagent.conf /etc/waagent.conf.bak || :
  fi
}

reset_fstab() {
  echo "Removing ephemeral /dev/xvdb from fstab"
  cat /etc/fstab
  sed -i "/dev\/xvdb/ d" /etc/fstab
}

cleanup() {
  reset_hostname
  reset_fstab
  yum clean all
}

disable_ipv6() {
  echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
  echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
  if grep "Amazon Linux AMI" /etc/issue &> /dev/null; then
    echo "IPv6 is disabled by default on Amazon Linux"
  else
    echo 'NETWORKING_IPV6=no' >> /etc/sysconfig/network
    echo 'IPV6INIT="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
    systemctl disable ip6tables.service
  fi
  sed -i 's/#AddressFamily any/AddressFamily inet/' /etc/ssh/sshd_config
}

disable_swap() {
  echo 'vm.swappiness = 0' >> /etc/sysctl.conf
}

set_dirty_ratio () {
  echo 'vm.dirty_background_ratio = 10' >> /etc/sysctl.conf
  echo 'vm.dirty_ratio = 20' >> /etc/sysctl.conf
}

reset_hostname() {
  echo "Avoid pre-assigned hostname"
  rm -vf /etc/hostname
  sed -i '/HOSTNAME=/d' /etc/sysconfig/network
}

reset_fstab() {
  echo "Removing ephemeral /dev/xvdb from fstab"
  cat /etc/fstab
  sed -i "/dev\/xvdb/ d" /etc/fstab
}

create_gc_image() {
    if [[ ${PACKER_BUILDER_TYPE:? required} == "googlecompute" ]]; then
        mkdir -p /tmp/imagebundle
        gcimagebundle -d /dev/sda -o /tmp/imagebundle --fssize=16106127360 --log_file=/tmp/imagebundle/create_imagebundle.log
        curl -O https://storage.googleapis.com/pub/gsutil.tar.gz
        tar xfz gsutil.tar.gz -C $HOME
        export PATH=${PATH}:$HOME/gsutil
        gsutil cp -a public-read /tmp/imagebundle/*.image.tar.gz gs://sequenceiqimage/"${PACKER_IMAGE_NAME:?required}".tar.gz
        rm -rf /tmp/imagebundle
    fi
}

check_params() {
    : ${PACKER_BUILDER_TYPE:? required amazon-ebs/googlecompute/openstack }
    : ${CONSUL_VERSION:=0.6.4}
    : ${CLOUDBREAK_BOOTSTRAP_VERSION:=0.1.1}
    : ${EPEL:=epel-release-7-6}
}

tune_vm() {
  if [[ -n "$(which tuned-adm &>/dev/null)" ]]; then
    tuned-adm profile custom
  fi
}

main() {
    check_params
    update_centos
    extend_rootfs
    modify_waagent
    disable_selinux
    permissive_iptables
    enable_ipforward
    install_utils
    install_kerberos
    #install_consul
    install_salt
    install_bootstrap
    install_jdk
    install_ambari
    install_hdp
    grant-sudo-to-os-user
    configure_console
    disable_ipv6
    tune_vm
    disable_swap
    set_dirty_ratio
    cleanup
    create_gc_image
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

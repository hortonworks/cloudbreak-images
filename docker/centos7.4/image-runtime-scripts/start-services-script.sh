#!/bin/bash

###
# CloudBreak uses unbound as a caching name server. Docker bind-mounts
# /etc/resolv.conf file that is why resolvconf package cannot be used
# as it tries to replace it with a symlink. A workaround is to tranform
# resolv.conf into unbound configuration and set unbound as a nameserver.
###
echo 'forward-zone:' >/etc/unbound/conf.d/99-default.conf
echo '  name: "."' >>/etc/unbound/conf.d/99-default.conf
for nameserver in $(awk '/^nameserver/{print $2}' /etc/resolv.conf); do
  echo "  forward-addr: ${nameserver}" >>/etc/unbound/conf.d/99-default.conf
done

echo 'forward-zone:' >>/etc/unbound/conf.d/99-default.conf
echo '  name: "in-addr.arpa."' >>/etc/unbound/conf.d/99-default.conf
for nameserver in $(awk '/^nameserver/{print $2}' /etc/resolv.conf); do
  echo "  forward-addr: ${nameserver}" >>/etc/unbound/conf.d/99-default.conf
done

echo "nameserver 127.0.0.1" >/etc/resolv.conf

## Cloudbreak related setup
if [[ -f "/etc/cloudbreak-config.props" ]]; then
    cp /etc/resolv.conf.ycloud /etc/resolv.conf

    source /etc/cloudbreak-config.props

    mkdir -p /home/${sshUser}/.ssh
    chmod 700 /home/${sshUser}/.ssh
    echo "${sshPubKey}" >> /home/${sshUser}/.ssh/authorized_keys
    chown -R ${sshUser}:${sshUser} /home/${sshUser}

    echo "${userData}" | base64 -d > /usr/bin/cb-init.sh
    chmod +x /usr/bin/cb-init.sh
    /usr/bin/cb-init.sh
fi

function setup_non_init_ssh_and_syslog() {

    echo "starting logging service.... "
    ## TODO: Nobody around to restart on failures
    /etc/init.d/syslog start
    echo "starting sshd service ... "

    ## TODO: Nobody around to restart on failures
    /etc/init.d/sshd start

    # Wait for 10 seconds for ssh to show up, otherwise die. Do this all the time.
    while : ; do
      found_pid=no;
      for ((i=0;i<10;i++));
      do
          PID=`pidof sshd`;
          if [ x"$PID"x != "xx" ];
          then
              found_pid=yes;
              break;
          else
              sleep 1;
          fi;
      done
      if [ "$found_pid" == "no" ] ; then
        echo "sshd is dead!" 1>&2
        exit 1
      fi
      sleep 1
    done
}

OS=`lsb_release -s -i`
OS_VERSION=`lsb_release -s -r`

if [[ ( x"$OS"x == x"Ubuntu"x && x"$OS_VERSION"x == x"16.04"x ) ]]; then
    ############################### Ubuntu16 #####################
    # Ubuntu16 has systemd
    exec -l /bin/systemd --system
    ############################### Ubuntu16 #####################
elif [[ ( x"$OS"x == x"Ubuntu"x && x"$OS_VERSION"x == x"14.04"x ) ]]; then
    ############################### Ubuntu14 #####################
    exec -l /sbin/init
    ############################### Ubuntu14 #####################
elif [[ ( x"$OS"x == x"Ubuntu"x && x"$OS_VERSION"x == x"12.04"x ) ]] ; then
    ############################### Ubuntu12 #####################
    exec -l /sbin/init
    ############################### Ubuntu12 #####################
elif [[ x"$OS"x == x"SUSE LINUX"x && x"$OS_VERSION"x == x"11"x ]]; then
    ############################### SLES #####################
    # Some bug causes this script to hang at 100% CPU
    # rm /etc/init.d/suse_studio_firstboot
    # exec -l /sbin/init

    setup_non_init_ssh_and_syslog
    ############################### SLES #####################
elif [[ x"$OS"x =~ "SUSE" && x"$OS_VERSION"x =~ "12" ]]; then
    ############################### SLES12 #####################
    # SLES12 has systemd
    exec -l /bin/systemd --system
    ############################### SLES12 #####################
elif [[ ( x"$OS"x == x"CentOS"x && x"$OS_VERSION"x == x"7.2.1511"x ) || ( x"$OS"x == x"CentOS"x && x"$OS_VERSION"x == x"7.3.1611"x ) || ( x"$OS"x == x"CentOS"x && x"$OS_VERSION"x == x"7.4.1708"x ) || ( x"$OS"x == x"CentOS"x && x"$OS_VERSION"x == x"7.5.1804"x ) ]] ; then
    ############################### Centos7 #####################
    # Centos7 has systemd
    systemctl enable sshd
    exec -l /usr/lib/systemd/systemd --system
    ############################### Centos7 #####################
fi

#!/bin/sh

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

###
# Set container limits for Ambari
###
if [ -f container_limits ]; then
    cpu=$(awk -F= '/vcores=/{print $2}' container_limits)
    memory=$(awk -F= '/memory=/{print $2*1024}' container_limits)
    mkdir -p /etc/resource_overrides
    cat >/etc/resource_overrides/ycloud.json <<EOF
{
    "processorcount": "$cpu",
    "physicalprocessorcount": "$cpu",
    "memorysize": "$memory",
    "memoryfree": "$memory",
    "memorytotal": "$memory"
}
EOF
fi

###
# CloudBreak provides a configuration file called cloudbreak-config.props
# when starting a deployment on Yarn. This is the method how it emulates
# user-data functionality of cloud-init.
###
if [ -f "/etc/cloudbreak-config.props" ]; then
    . /etc/cloudbreak-config.props

    cp /etc/cloudbreak-config.props /var/log/

    mkdir -p /home/${sshUser}/.ssh
    chmod 700 /home/${sshUser}/.ssh
    echo "${sshPubKey}" >>/home/${sshUser}/.ssh/authorized_keys
    chown -R ${sshUser}:${sshUser} /home/${sshUser}

    echo "${userData}" | base64 -d >/usr/bin/cb-init.sh
    chmod +x /usr/bin/cb-init.sh
    /usr/bin/cb-init.sh >/var/log/cb-init-sh.log 2>&1
fi

exec /bin/systemd --system

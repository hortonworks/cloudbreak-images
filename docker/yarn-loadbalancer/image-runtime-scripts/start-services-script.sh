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

#### Generate input for Ambari from container_limits generated dynamically by YARN
echo "using container_limits to create system resource overrides for ambari"
memoryMb=`cat container_limits | grep memory= | awk -F= '{print $2}'`
memoryKb=`expr $memoryMb \* 1024`
cpu=`cat container_limits | grep vcores= | awk -F= '{print $2}'`
mkdir -p /yarn-private/ambari/
cat <<EOF > /yarn-private/ambari/ycloud.json
{
    "processorcount": "$cpu",
    "physicalprocessorcount": "$cpu",
    "memorysize": "$memoryKb",
    "memoryfree": "$memoryKb",
    "memorytotal": "$memoryKb"
}
EOF

echo "Successfully ran start-services-script." >> /yarn-private/logs

# Run haproxy service.
echo "Attempting to start haproxy service." >> /yarn-private/logs

source /etc/cloudbreak-loadbalancer.props

# Edit configuration file.
SERVERS=(${servers})
tabs 4

i=0
for server in "${SERVERS[@]}"
do
    server=$(echo ${server} | sed 's#\\##g')
    printf "\tserver server%s %s check\n" "${i}" "${server}" >> /tmp/haproxy.cfg
    i=$((i+1))
done

echo "Finished setting up haproxy.cfg!" >> /yarn-private/logs

# Run haproxy.
haproxy -f /tmp/haproxy.cfg &
echo "Successfully started the haproxy service!" >> /yarn-private/logs

# Finish.
systemctl enable sshd
exec -l /usr/lib/systemd/systemd --system
#!/bin/bash
#
# register-ambari    Registers Ambari server with Consul
#
# chkconfig: 2345 99 01
# description: Registers Ambari server with Consul

### BEGIN INIT INFO
# Provides:          register-ambari
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO

docker_running() {
    if docker info &> /dev/null ; then
        echo UP;
    else
        echo DOWN;
    fi;
}
con() {
    declare path="$1"
    shift
    local consul_ip=127.0.0.1
    curl ${consul_ip}:8500/v1/${path} "$@"
}
 
register_ambari() {
    JSON=$(cat <<ENDOFJSON
{
    "ID":"$(hostname -i):ambari:8080",
    "Name":"ambari-8080",
    "Port":8080,
    "Check":null
}
ENDOFJSON
)
    triesRemaining=5
    while [ $triesRemaining -gt 0 ]; do
        con agent/service/register -X PUT -d @- <<<"$JSON"
        result=$?
        if [ $result -eq 0 ]; then
            triesRemaining=0
        else
            triesRemaining=$(( $triesRemaining - 1 ))
            sleep 5
        fi
    done
}
is_ambari_server() {
    if docker inspect ambari-server &> /dev/null ; then
        echo AMBARI_SERVER;
    else
        echo AMBARI_AGENT;
    fi;
}

start() {
    set -x
    exec 1>>/tmp/register1.log
    exec 2>>/tmp/register2.log
    DOCKER_MAX_RETRIES=60
    docker_retries=0
    while [[ "$(docker_running)" == "DOWN" ]] && [ $docker_retries -ne $DOCKER_MAX_RETRIES ];
    do
        sleep 8
        ((docker_retries++))
    done
    if [[ "$(is_ambari_server)" == "AMBARI_SERVER" ]] ; then
        register_ambari
    fi;
}

stop() {
    echo "finished"
}

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        echo "finished"
        ;;
  restart|reload|condrestart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart|reload|status}"
        exit 1
esac
exit 0

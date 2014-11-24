#!/bin/bash

[[ "$TRACE" ]] && set -x

: ${DOCKER_TAG:=consul}
: ${CONSUL_IMAGE:=sequenceiq/consul:v0.4.1.ptr}

get_meta() {
  curl -s 169.254.169.254/latest/meta-data/$1
}

fix_hostname_i() {
  if grep -q $(get_meta local-ipv4) /etc/hosts ;then
    echo OK
  else
    echo $(get_meta local-ipv4) $(cat /etc/hostname) >> /etc/hosts
  fi
}

get_region() {
  local zone=$(get_meta placement/availability-zone)
  echo ${zone:0:-1}
}

get_vpc() {
  local mac=$(get_meta network/interfaces/macs/)
  get_meta network/interfaces/macs/${mac}/vpc-id
}

get_cluster_name() {
  : ${AWS_DEFAULT_REGION:=$(get_region)}
  export AWS_DEFAULT_REGION

  aws ec2 describe-tags \
  --filters \
    Name=resource-id,Values=$(get_meta instance-id) \
    Name=key,Values=cluster \
      | jq .Tags[0].Value -r
}

get_vpc_peers() {
  local vpc=$(get_vpc)
  local cluster=$(get_cluster_name)

  : ${AWS_DEFAULT_REGION:=$(get_region)}
  export AWS_DEFAULT_REGION

  aws ec2 describe-instances \
    --filters \
      Name=instance-state-name,Values=running \
      Name=vpc-id,Values=$vpc \
      Name=tag:cluster,Values=$cluster \
    --query Reservations[].Instances[].PrivateIpAddress \
    --out text
}

meta_order() {
  get_vpc_peers | xargs -n 1 | sort | cat -n | sed 's/ *//;s/\t/ /'
}

my_order() {
  local myip=$(get_meta local-ipv4)
  meta_order | grep ${myip} | cut -d" " -f 1
}

consul_join_ip() {
  meta_order | head -1 | cut -d" " -f 2
}

start_consul() {

  CONSUL_OPTIONS="-advertise $(get_meta local-ipv4)"

  if [ $(my_order) -gt 1 ]; then
    CONSUL_OPTIONS="$CONSUL_OPTIONS -retry-join $(consul_join_ip)"
  fi

  if [ $(my_order) -le 3 ]; then
    CONSUL_OPTIONS="$CONSUL_OPTIONS -server -bootstrap-expect 3"
  fi

  docker rm -f consul &> /dev/null
  docker run -d \
    --name consul \
    --net=host \
    $CONSUL_IMAGE $CONSUL_OPTIONS
}

consul_leader() {
  local leader=$(curl -s 127.0.0.1:8500/v1/status/leader|jq . -r)
  while [ -z "$leader" ]; do
    sleep 1
    leader=$(curl -s 127.0.0.1:8500/v1/status/leader|jq . -r)
  done
  echo ${leader%:*}
}

con() {
  declare path="$1"
  shift
  local consul_ip=127.0.0.1
  #CONSUL_IP=$(get_meta local-ipv4)

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

  con agent/service/register -X PUT -d @- <<<"$JSON"
}

start_ambari_server() {
  docker rm -f ambari-server &>/dev/null
  if [[ "$(consul_leader)" ==  "$(get_meta local-ipv4)" ]]; then
    docker run -d \
     --name ambari-server \
     --net=host \
     sequenceiq/ambari:$DOCKER_TAG /start-server

    register_ambari
  fi
}

start_ambari_agent() {
  docker run -d \
    --name ambari-agent \
    --net=host \
    sequenceiq/ambari:$DOCKER_TAG /start-agent
}

amb_shell_docker() {
  declare script=$1
  shift
  declare docker_args="$@"

  docker run -t --rm \
    $docker_args \
    -e AMBARI_HOST=$(dig @172.17.42.1 ambari-8080.service.consul +short) \
    --entrypoint=sh \
    sequenceiq/ambari:$DOCKER_TAG -c $script
}

amb_shell() {
  amb_shell_docker /tmp/ambari-shell.sh -i
}

create_cluster() {
  amb_shell_docker /tmp/install-cluster.sh -e DEBUG=1 -e BLUEPRINT=multi-node-hdfs-yarn
}

main() {
  if [[ "$1" == "::" ]]; then
    shift
    eval "$@"
  else
    fix_hostname_i
    start_consul
    start_ambari_server
    start_ambari_agent
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

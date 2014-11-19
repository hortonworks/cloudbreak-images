#!/bin/bash

[[ "$TRACE" ]] && set -x

: ${DOCKER_TAG:=consul}
: ${IMAGES:=sequenceiq/ambari:consul progrium/consul }

install_utils() {
  apt-get update && apt-get install -y unzip curl git python-pip dnsutils nmap
  curl -o /usr/local/bin/jq http://stedolan.github.io/jq/download/linux64/jq && chmod +x /usr/local/bin/jq
  pip install awscli
}

install_docker() {
  curl -sSL https://get.docker.com/ | sh
  sudo usermod -aG docker ubuntu
}

install_consul() {
  curl -LO https://dl.bintray.com/mitchellh/consul/0.4.1_linux_amd64.zip \
    && unzip 0.4.1_linux_amd64.zip \
    && mv consul /usr/local/bin
}

get-meta() {
  curl -s 169.254.169.254/latest/meta-data/$1
}

fix-hostname-i() {
  if grep -q $(get-meta local-ipv4) /etc/hosts ;then
    echo OK
  else
    echo $(get-meta local-ipv4) $(cat /etc/hostname) >> /etc/hosts
  fi
}

get-region() {
  local zone=$(get-meta placement/availability-zone)
  echo ${zone:0:-1}
}

aws-cli-setup() {
  export AWS_DEFAULT_REGION=$(get-region)
  complete -C aws_completer aws

  grep aws_completer $HOME/.bashrc || cat >> $HOME/.bashrc<<EOF
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
complete -C aws_completer aws
EOF

  aws ec2 describe-regions
}

pull_images() {
  for i in ${IMAGES}; do
    docker pull ${i}
  done
}

build-ambari-image(){
  rm -rf /tmp/docker-ambari \
    && git clone https://github.com/sequenceiq/docker-ambari.git /tmp/docker-ambari \
    && cd /tmp/docker-ambari/ambari-server \
    && git checkout consul \
    && docker build -t sequenceiq/ambari:$DOCKER_TAG .
}

get-vpc() {
  local mac=$(get-meta network/interfaces/macs/)
  get-meta network/interfaces/macs/${mac}/vpc-id
}

get-vpc-peers() {
  local vpc=$(get-vpc)

  aws ec2 describe-instances \
    --filters \
      Name=instance-state-name,Values=running \
      Name=vpc-id,Values=$vpc \
    --query Reservations[].Instances[].PrivateIpAddress \
    --out text
}

meta-order() {
  if [ ! -f /tmp/meta-order ]; then
    get-vpc-peers | xargs -n 1 | sort | cat -n | sed 's/ *//;s/\t/ /' > /tmp/meta-order
  fi
  cat /tmp/meta-order
}

my-order() {
  local myip=$(get-meta local-ipv4)
  meta-order | grep ${myip} | cut -d" " -f 1
}

consul-join-ip() {
  meta-order | head -1 | cut -d" " -f 2
}

start-consul() {

  CONSUL_OPTIONS="-advertise $(get-meta local-ipv4)"

  if [ $(my-order) -gt 1 ]; then
    CONSUL_OPTIONS="$CONSUL_OPTIONS -retry-join $(consul-join-ip)"
  fi

  if [ $(my-order) -le 3 ]; then
    CONSUL_OPTIONS="$CONSUL_OPTIONS -server -bootstrap-expect 3"
  fi

  docker rm -f consul &> /dev/null
  docker run -d \
    --name consul \
    --net=host \
    progrium/consul:hack $CONSUL_OPTIONS
}

build-consul-hack-image() {
  cat >Dockerfile <<EOF
FROM progrium/consul
ADD https://github.com/sequenceiq/consul/releases/download/0.4.2.HACK/consul-0.4.2-linux /bin/consul
RUN chmod +x /bin/consul
EOF

  mkdir config
  docker build -t progrium/consul:hack .
}

consul-leader() {
  local leader=$(curl -s 127.0.0.1:8500/v1/status/leader|jq . -r)
  echo ${leader%:*}
}

con() {
  declare path="$1"
  shift
  local consul_ip=127.0.0.1
  #CONSUL_IP=$(get-meta local-ipv4)

  curl ${consul_ip}:8500/v1/${path} "$@"
}

register-ambari() {
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

mbari-server() {
  docker rm -f ambari-server &>/dev/null
  if [[ "$(consul-leader)" ==  "$(get-meta local-ipv4)" ]]; then
    docker run -d \
     --name ambari-server \
     --net=host \
     sequenceiq/ambari:$DOCKER_TAG /start-server

    register-ambari
  fi
}

start-ambari-agent() {
  docker run -d \
    --name ambari-agent \
    --net=host \
    sequenceiq/ambari:$DOCKER_TAG /start-agent
}

amb-shell-docker() {
  declare script=$1
  shift
  declare docker_args="$@"

  docker run -t --rm \
    $docker_args \
    -e AMBARI_HOST=$(dig @172.17.42.1 ambari-8080.service.consul +short) \
    --entrypoint=sh \
    sequenceiq/ambari:$DOCKER_TAG -c $script
}

amb-shell() {
  amb-shell-docker /tmp/ambari-shell.sh -i
}

create-cluster() {
  amb-shell-docker /tmp/install-cluster.sh -e DEBUG=1 -e BLUEPRINT=multi-node-hdfs-yarn
}

main() {
  if [[ "$1" == "::" ]]; then
    shift
    eval "$@"
  else
    echo SETUP ...
    #install_utils
    #aws-cli-setup
    #install_docker
    #pull_images

    #fix-hostname-i
    #install_consul
    # start-consul
    # build-ambari-image
    # sleep 10
    #
    # start-ambari-server
    # sleep 5
    #
    # start-ambari-agent
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

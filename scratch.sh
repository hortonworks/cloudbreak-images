#!/bin/bash

: ${DEBUG:=1}

VERSION=0.9.0

debug() {
  [[ "$DEBUG" ]] && echo "-----> $@" 1>&2
}

latest_ubuntu_trusty() {
  declare reg=$1
  [[ "$reg" ]] && region_options="--region=$reg"
  aws ec2 describe-images \
    $region_options \
    --filters \
      "Name=architecture,Values=x86_64" \
      "Name=virtualization-type,Values=hvm" \
      "Name=owner-id,Values=099720109477" \
    | jq ".Images[]|[.Name,.ImageId]" -c \
    | grep ubuntu/images/hvm/ubuntu-trusty-14.04 \
    | sort | tail -1 | jq .[1] -r
}

get_instance_ip() {
  declare reg=$1
  [[ "$reg" ]] && region_options="--region=$reg"

  aws ec2 describe-instances \
    $region_options \
    --filter Name=tag:Name,Values=cloudbreak-image-template \
    --query Reservations[0].Instances[0].PublicIpAddress \
    --out text
}

get_instance_state() {
  declare reg=$1
  [[ "$reg" ]] && region_options="--region=$reg"

  aws ec2 describe-instances \
    $region_options \
    --filter Name=tag:Name,Values=cloudbreak-image-template \
    --query Reservations[0].Instances[0].State.Name \
    --out text
}


create_instance() {
  declare reg=$1
  [[ "$reg" ]] && region_options="--region=$reg"

  INSTANCE_ID=$( aws ec2 run-instances \
	$region_options \
	--image-id $(latest_ubuntu_trusty) \
	--key-name sequence-eu \
	--user-data=file://./user-data-script.sh \
	--instance-type m3.medium \
	--query Instances[0].InstanceId \
	--out text
  )
  
  debug "[$reg] instance created: $INSTANCE_ID"

  aws ec2 create-tags \
	$region_options \
	--resources $INSTANCE_ID \
	--tags \
	  Key=Name,Value=cloudbreak-image-template \
	  Key=owner,Value=sequenceiq

}

create_image() {
  declare reg=$1
  [[ "$reg" ]] && region_options="--region=$reg"

  AMI=$( aws ec2 create-image \
    	$region_options \
	--instance-id $INSTANCE_ID \
	--name cloudbreak \
	--query ImageId \
	--out text
)

  debug "[$reg] ami created: $AMI"

  aws ec2 create-tags \
	$region_options \
	--resources $AMI \
	--tags \
	  Key=name,Value=cloudbreak \
	  Key=virtualization-type,Value=hvm \
	  Key=owner,Value=sequenceiq \
	  Key=versionmValue=$VERSION \
	  Key=consul,Value=v0.4.1.ptr

}

install_cluster() {
	declare ambariHost="$1"
	: ${ambariHost:? required}

	docker run -it --rm \
		--entrypoint=/tmp/install-cluster.sh \
		-e AMBARI_HOST=$ambariHost \
		-e BLUEPRINT=multi-node-hdfs-yarn \
		sequenceiq/ambari:1.6.0 
}

wait_for_running() {
  declare reg=$1
  [[ "$reg" ]] && region_options="--region=$reg"
  
  debug "[$reg] wait for instance reaching running state ..."
  while [[ $(get_instance_state) != running ]]; do
    echo -n .
    sleep 1
  done
}

wait_for_user_data_script() {
  declare reg=$1
  [[ "$reg" ]] && region_options="--region=$reg"

  local ip=$(get_instance_ip $reg)
  debug "[$reg] wait for $ip to finish user-data script ..."
  while ssh -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$ip test ! -f /tmp/ready; do 
    echo -n .
    sleep 1
  done
}

create_for_region() {
  create_instance "$@"
  wait_for_running "$@"
  wait_for_user_data_script "$@"
  create_image "$@"
}

main() {
  if [ $# -gt 0 ]; then
    create_for_region "$@"
  else
    aws ec2 describe-regions \
    --query Regions[].RegionName \
    --out=text \
    | xargs -t -n 1 -P 20 bash -c "$BASH_SOURCE \$@" --
  fi
}


[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
alias r=". $BASH_SOURCE"

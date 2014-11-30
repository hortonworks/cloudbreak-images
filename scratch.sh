#!/bin/bash

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
  
  echo instance created: $INSTANCE_ID

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

  echo ami created: $AMI

  aws ec2 create-tags \
	$region_options \
	--resources $AMI \
	--tags \
	  Key=name,Value=cloudbreak \
	  Key=virtualization-type,Value=hvm \
	  Key=owner,Value=sequenceiq \
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

main() {
  create_instance
  create_image
}

alias r=". $BASH_SOURCE"

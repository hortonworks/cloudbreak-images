#!/bin/bash

create_instance() {

  INSTANCE_ID=$( aws ec2 run-instances \
	--image-id ami-f4b11183 \
	--key-name sequence-eu \
	--user-data=file://./user-data-script.sh \
	--instance-type m3.medium \
	--query Instances[0].InstanceId \
	--out text
  )
  
  echo instance created: $INSTANCE_ID

  aws ec2 create-tags \
	--resources $INSTANCE_ID \
	--tags \
	  Key=Name,Value=cloudbreak-image-template \
	  Key=owner,Value=sequenceiq

}

create_image() {
  AMI=$( aws ec2 create-image \
	--instance-id $INSTANCE_ID \
	--name cloudbreak \
	--query ImageId \
	--out text
)

  echo ami created: $AMI

  aws ec2 create-tags \
	--resources $AMI \
	--tags \
	  Key=name,Value=cloudbreak \
	  Key=virtualization-type,Value=hvm \
	  Key=owner,Value=sequenceiq \
	  Key=consul,Value=v0.4.1.ptr

}

main() {
  create_instance
  create_image
}

alias r=". $BASH_SOURCE"

#!/bin/bash
#set -e
[[ "$TRACE" ]] && set -x

: ${CLUSTER:=consul}
: ${DEBUG:=1}
: ${USER_DATA_SCRIPT:=ec2-user-data.sh}
: ${AMI:=ami-a82d9bdf}

debug(){
  [[ "$DEBUG" ]] && echo "[DEBUG] $@" 1>&2
}

spot_req() {
  declare count=$1
  : ${count:? required InstanceCount}

  cat > /tmp/spot_req.json<<EOF
{
    "SpotPrice": "0.030000",
    "InstanceCount": $count,
    "Type": "one-time",
    "LaunchSpecification": {
        "ImageId": "$AMI",
        "KeyName": "sequence-eu",
        "InstanceType": "m3.medium",
        "UserData" : "$(cat $USER_DATA_SCRIPT |base64)",
        "BlockDeviceMappings": [
                    {
                        "DeviceName": "/dev/sda1",
                        "Ebs": {
                            "DeleteOnTermination": true,
                            "VolumeSize": 30,
                            "VolumeType": "standard"
                        }
                    }
         ],
        "Placement": {
            "AvailabilityZone": "eu-west-1c"
        },
        "SubnetId": "subnet-f0eb3587",
        "IamInstanceProfile": {
            "Arn": "arn:aws:iam::755047402263:instance-profile/readonly-role"
        }
    }
}
EOF
  RESP=$( aws ec2 request-spot-instances \
      --cli-input-json file:///tmp/spot_req.json \
      --query SpotInstanceRequests[].SpotInstanceRequestId
  )
  
  set -x
  debug resp="$RESP"
  echo $RESP | jq .[] -r
  set +x
}

tag_requests() {
  local spot_reqs
  if [ $# -gt 0 ]; then
    spot_reqs="$@"
  else
    spot_reqs=$(get_my_spot_reqs)
  fi
  aws ec2 create-tags \
    --resources $spot_reqs \
    --tags Key=Name,Value=${CLUSTER} \
           Key=owner,Value=$USER \
	   Key=cluster,Value=$CLUSTER
}

desc_spot_reqs() {
  declare jq_filter="$1"

# Name=tag:owner,Values="$USER" \
  aws ec2 describe-spot-instance-requests \
    --filters \
      Name=tag:Name,Values=${CLUSTER} \
      Name=status-code,Values=fulfilled,request-canceled-and-instance-running \
    | jq "$jq_filter" -r

}

get_my_spot_instances() {
  desc_spot_reqs .SpotInstanceRequests[].InstanceId
}

get_my_spot_reqs() {
  desc_spot_reqs .SpotInstanceRequests[].SpotInstanceRequestId
}

tag_instances() {
  count=1
  for i in $(get_my_spot_instances); do
    aws ec2 create-tags \
      --resources $i \
      --tags Key=Name,Value=${CLUSTER}-$count \
             Key=owner,Value=$USER \
	     Key=cluster,Value=$CLUSTER
    ((count++))
  done
}

cancel_spot_reqs() {
  aws ec2 cancel-spot-instance-requests \
    --spot-instance-request-ids $(get_my_spot_reqs)
}

terminate_instances() {
  aws ec2 terminate-instances \
    --instance-ids $(get_my_spot_instances)
}

clean() {
  cancel-spot_reqs
  terminate_instances
}

main() {
  spot_reqs=$(spot_req "$@")
  tag_requests $spot_reqs
  # tag_instances 
  echo request ID=$sir
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

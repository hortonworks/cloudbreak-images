#!/bin/bash

set -ex -o pipefail

AMI_ID=$IMAGE_NAME
IMAGE_NAME=$(aws ec2 describe-images --region $SOURCE_LOCATION --filters "Name=image-id,Values=$AMI_ID" --query 'Images[*].[Name]' --output "text")

if [ -z "$IMAGE_NAME" ]
then
  echo "Source image $AMI_ID in region $SOURCE_LOCATION not found, exiting"
  exit 1
fi

SRC_ACCOUNT=""
if [[ -z $SOURCE_ACCOUNT ]]; then
  SRC_ACCOUNT=self
else
  SRC_ACCOUNT=$SOURCE_ACCOUNT
  echo Source account is $SRC_ACCOUNT
fi


echo "Installing jq..."
yum install -q -y jq

echo "Copying image $IMAGE_NAME ($AMI_ID) from region $SOURCE_LOCATION to regions $AWS_AMI_REGIONS"
IMAGES=""

declare -a JOBS

function log() {
  echo "$(date --rfc-3339=seconds) $1"
}

function exec_background() {
  eval $1 & JOBS[$!]="$1"
}

function checking_jobs() {
  local cmd
  local status=0
  for pid in ${!JOBS[@]}; do
    cmd=${JOBS[${pid}]}
    wait ${pid} ; JOBS[${pid}]=$?
    if [[ ${JOBS[${pid}]} -ne 0 ]]; then
      status=${JOBS[${pid}]}
      log "[${pid}] Exited with status: ${status} | ${cmd}"
    fi
  done
  return ${status}
}

function wait_for_image_and_check() {
  REGION=$1
  AMI_IN_REGION=$2
  export AWS_RETRY_MODE=standard
  export AWS_MAX_ATTEMPTS=10000

  aws ec2 wait image-available --region $REGION --image-ids $AMI_IN_REGION

  if [ $? != 0 ]
  then
    log "First try of waiting in region $REGION for image $AMI_IN_REGION failed, retrying"
    aws ec2 wait image-available --region $REGION --image-ids $AMI_IN_REGION

    if [ $? != 0 ]
    then
      log "Second try of waiting in region $REGION for image $AMI_IN_REGION failed too, exiting"
      exit 1
    fi
  fi

  log "Querying snapshot in region $REGION for image $AMI_IN_REGION"
  SNAPSHOT_ID=$(aws ec2 describe-images --image-ids $AMI_IN_REGION --region $REGION --query "Images[0].BlockDeviceMappings[0].Ebs.SnapshotId" --output "text")

  if [ "$MAKE_PUBLIC_SNAPSHOTS" == "yes" ]; then
    log "Setting snapshot $SNAPSHOT_ID visibility to public in region $REGION for image $AMI_IN_REGION"
    aws ec2 modify-snapshot-attribute --snapshot-id $SNAPSHOT_ID --region $REGION --create-volume-permission "Add=[{Group=all}]"
  elif [ -n "$AWS_SNAPSHOT_USER" ]; then
    log "Setting snapshot $SNAPSHOT_ID visibility for user in region $REGION for image $AMI_IN_REGION"
    aws ec2 modify-snapshot-attribute --snapshot-id $SNAPSHOT_ID --region $REGION --create-volume-permission "Add=[{UserId=$AWS_SNAPSHOT_USER}]"
  fi

  if [ "$MAKE_PUBLIC_AMIS" == "yes" ]; then
    log "Setting launch permissions to public in region $REGION for image $AMI_IN_REGION"
    aws ec2 modify-image-attribute --image-id $AMI_IN_REGION --region $REGION --launch-permission "Add=[{Group=all}]"
  elif [ -n "$AWS_AMI_ORG_ARN" ]; then
    log "Setting launch permissions only for organization in region $REGION for image $AMI_IN_REGION"
    aws ec2 modify-image-attribute --image-id $AMI_IN_REGION --region $REGION --launch-permission "Add=[{OrganizationArn=$AWS_AMI_ORG_ARN}]"
  fi

  IMAGESTATUS=""
  SNAPSTATUS=""
  for ((i=0; i<5; i++))
  do
    IMAGE_DESC=$(aws ec2 describe-images --region $REGION --image-ids $AMI_IN_REGION --output json)
    IMAGE_AVAILABLE=$(echo $IMAGE_DESC | jq -r '.Images[0].State')

    if [ "${IMAGE_AVAILABLE}" == "available" ]; then
      log "The $AMI_IN_REGION in $REGION region is available, checking permissions..."
      IMAGE_PUBLIC=$(echo $IMAGE_DESC | jq -r '.Images[0].Public')
      if [ "$MAKE_PUBLIC_AMIS" == "yes" ]; then
        if [ "${IMAGE_PUBLIC}" == "true" ]; then
          log "The $AMI_IN_REGION in $REGION region is public"
          IMAGESTATUS="OK"
        fi
      elif [ -n "$AWS_AMI_ORG_ARN" ]; then
        IMAGE_PERMISSIONS=$(aws ec2 describe-image-attribute --region $REGION --image-id $AMI_IN_REGION --attribute launchPermission --output json)
        IMAGE_ORGANIZATION_ARN=$(echo $IMAGE_PERMISSIONS | jq -r '.LaunchPermissions[0].OrganizationArn')
        if [ "${IMAGE_PUBLIC}" == "false" ] && [ "${IMAGE_ORGANIZATION_ARN}" == "$AWS_AMI_ORG_ARN" ]; then
          log "The $AMI_IN_REGION in $REGION region is only shared with an organization"
          IMAGESTATUS="OK"
        fi
      else
        if [ "${IMAGE_PUBLIC}" == "false" ]; then
          log "The $AMI_IN_REGION in $REGION region is private"
          IMAGESTATUS="OK"
        fi
      fi
    fi

    SNAPSHOT_PERMISSIONS=$(aws ec2 describe-snapshot-attribute --region $REGION --snapshot-id $SNAPSHOT_ID --attribute createVolumePermission --output json)
    SNAPSHOT_PUBLIC=$(echo $SNAPSHOT_PERMISSIONS | jq -r '.CreateVolumePermissions | any(.Group == "all")')
    if [ "${MAKE_PUBLIC_SNAPSHOTS}" == "yes" ]; then
      if [ "${SNAPSHOT_PUBLIC}" == "true" ]; then
        SNAPSTATUS="OK"
      fi
    elif [ -n "${AWS_SNAPSHOT_USER}" ]; then
      SNAPSHOT_SHARED_WITH_USER=$(echo $SNAPSHOT_PERMISSIONS | jq -r --arg userId $AWS_SNAPSHOT_USER '.CreateVolumePermissions | any(.UserId == $userId)')
      if [ "${SNAPSHOT_PUBLIC}" == "false" ] && [ "${SNAPSHOT_SHARED_WITH_USER}" == "true" ]; then
        SNAPSTATUS="OK"
      fi
    else
      if [ "${SNAPSHOT_PUBLIC}" == "false" ]; then
        SNAPSTATUS="OK"
      fi
    fi

    if [ "${IMAGESTATUS}" == "OK" ] && [ "${SNAPSTATUS}" == "OK" ]; then
      break
    else
      sleep 60
    fi
  done

  if [ "${IMAGESTATUS}" = "OK" ]; then 
    log "The $AMI_IN_REGION in $REGION region is available and in correct state."
  else
    log "FAILURE | The $AMI_IN_REGION in $REGION region is not available or not in correct state."
    exit 1
  fi

  if [ "${SNAPSTATUS}" = "OK" ]; then
    log "The $SNAPSHOT_ID in $REGION region is available and in correct state."
  else
    log "FAILURE | The $SNAPSHOT_ID in $REGION region is not available or not in correct state."
    exit 1
  fi

  log "Copy operation in region $REGION for image $AMI_IN_REGION finished"
}

for REGION in $(echo $AWS_AMI_REGIONS | sed "s/,/ /g")
do
  log "Copying to region $REGION..."

  if [ "$REGION" == "$SOURCE_LOCATION" ]
  then
    log "Source and destination regions are the same, skipping copy to $REGION"
    continue
  fi

  AMI_IN_REGION=$(aws ec2 describe-images --owners $SRC_ACCOUNT --filters "Name=name,Values=$IMAGE_NAME" --region $REGION --query "Images[*].[ImageId]" --output "text")
  if [ -n "$AMI_IN_REGION" ]
  then
    log "Image is already copied to region $REGION as $AMI_IN_REGION"
  else
    AMI_IN_REGION=$(aws ec2 copy-image --source-image-id $AMI_ID --source-region $SOURCE_LOCATION --region $REGION --name $IMAGE_NAME --output "text")
    log "Image copy started to region $REGION as $AMI_IN_REGION, waiting for its completion"
  fi
  IMAGES+="${REGION}=${AMI_IN_REGION},"
  exec_background "wait_for_image_and_check $REGION $AMI_IN_REGION"
done

checking_jobs|| exit 1

IMAGES=${IMAGES%?} # remove trailing comma
log "Image copied to regions: $IMAGES"
echo "IMAGES_IN_REGIONS=$IMAGES" > images_in_regions

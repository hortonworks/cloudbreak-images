#!/bin/bash

AMI_ID=$IMAGE_NAME
IMAGE_NAME=$(aws ec2 describe-images --region $SOURCE_LOCATION --filters "Name=image-id,Values=$AMI_ID" --owners "self" --query 'Images[*].[Name]' --output "text")

if [ -z "$IMAGE_NAME" ]
then
  echo "Source image $AMI_ID in region $SOURCE_LOCATION not found, exiting"
  exit 1
fi

echo "Restoring image $IMAGE_NAME ($AMI_ID) from region $SOURCE_LOCATION to regions $AWS_AMI_REGIONS"
IMAGES=""

function log() {
  echo "$(date --rfc-3339=seconds) $1"
}

function wait_for_image() {
  REGION=$1
  AMI_IN_REGION=$2

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

  log "Querying snapshots in region $REGION for image $AMI_IN_REGION"
  SNAPSHOT_IDS=$(aws ec2 describe-images --image-ids $AMI_IN_REGION --region $REGION --query "Images[*].BlockDeviceMappings[*].Ebs.SnapshotId" --output "text")

  echo $SNAPSHOT_IDS | while read SNAPSHOT_ID
  do
    log "Setting snapshot $SNAPSHOT_ID visibility to public in region $REGION for image $AMI_IN_REGION"
    aws ec2 modify-snapshot-attribute --snapshot-id $SNAPSHOT_ID --region $REGION --create-volume-permission "Add=[{Group=all}]"
  done

  log "Setting launch permissions to public in region $REGION for image $AMI_IN_REGION"
  aws ec2 modify-image-attribute --image-id $AMI_IN_REGION --region $REGION --launch-permission "Add=[{Group=all}]"

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

  AMI_IN_REGION=$(aws ec2 describe-images --owners self --filters "Name=name,Values=$IMAGE_NAME" --region $REGION --query "Images[*].[ImageId]" --output "text")
  if [ -n "$AMI_IN_REGION" ]
  then
    log "Image is already copied to region $REGION as $AMI_IN_REGION"
    continue
  fi

  AMI_IN_REGION=$(aws ec2 copy-image --source-image-id $AMI_ID --source-region $SOURCE_LOCATION --region $REGION --name $IMAGE_NAME --output "text")
  log "Image copy started to region $REGION as $AMI_IN_REGION, waiting for its completion"

  IMAGES+="${REGION}=${AMI_IN_REGION},"
  wait_for_image $REGION $AMI_IN_REGION &
done

wait

IMAGES=${IMAGES%?} # remove trailing comma
log "Image copied to regions: $IMAGES"
echo "IMAGES_IN_REGIONS=$IMAGES" > images_in_regions

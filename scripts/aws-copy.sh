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

for REGION in $(echo $AWS_AMI_REGIONS | sed "s/,/ /g")
do
  echo "Copying to region $REGION..."

  if [ "$REGION" == "$SOURCE_LOCATION" ]
  then
    echo "Source and destination regions are the same, skipping"
    continue
  fi

  AMI_IN_REGION=$(aws ec2 copy-image --source-image-id $AMI_ID --source-region $SOURCE_LOCATION --region $REGION --name $IMAGE_NAME --output "text")
  echo "Image copy started to region $REGION as $AMI_IN_REGION"
  IMAGES+="${REGION}=${AMI_IN_REGION},"

  aws ec2 wait image-available --region $REGION --image-ids $AMI_IN_REGION & # wait for image availability in a new process
done

echo "Waiting for copy operations to finish..."
wait

IMAGES=${IMAGES%?} # remove trailing comma
echo "Image copied to regions: $IMAGES"
echo "IMAGES_IN_REGIONS=$IMAGES" > images_in_regions

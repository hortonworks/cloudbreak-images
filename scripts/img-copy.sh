#!/bin/bash

# This script is a helper meant for copying images to your own account.
# Currently it supports AWS only and requires the below parameters:
#
#  1 Source AWS account (from which the image is being copied)
#  2 AWS Credentials profile name
#  3 AMI ID
#  4 target regions, commma separated
#
# To have the proper AWS credentials, you'll need to use gimme-aws-creds along with
# Okta - this is the company standard, but technically nothing prevents you
# from setting up a custom ~/.aws/credentials file. Contents the credentials file
# will also provide you the necessary value for the AWS credentials profile name.
# Having Docker installed on your machine is also required to run this script.
#
# Example use:
# ./img-copy.sh 1234567890123 default ami-0073e5fb98e2faa3f eu-north-1,eu-west-3
#
# This will cause you to end up with a whole lot of log on the standard out, ending
# with something like this:
# + echo '2023-11-23 11:00:32+00:00 Image copied to regions: eu-north-1=ami-0b7149651a90989f3,eu-west-3=ami-0fb5aa19986c12ec8'
# Now you can copy those AMI references into a custom catalog.
#
# If you run into the below error message when the script finishes, it means that 
# your account can't have public AMIs:
#   "An error occurred (OperationNotPermitted) when calling the ModifyImageAttribute 
#    operation: You can’t publicly share this image because block public access for
#    AMIs is enabled for this account. To publicly share the image, you must call 
#    the DisableImageBlockPublicAccess API."
# Having public AMIs is a must though, as Cloudbreak needs to access them, so you'll 
# have to enable this in the account.
#
# Note: Regardless of the above error message, the AMI copy should be successful.

if [[ -z $1 ]]; then
  echo Source AWS account ID must be provided as the first parameter!
  exit 1
fi

if [[ -z $2 ]]; then
  echo AWS Credentials profile must be provided as the second parameter!
  exit 1
fi

if [[ -z $3 ]]; then
  echo Image name must be provided as the third parameter!
  exit 1
fi

if [[ -z $4 ]]; then
  echo Target regions must be provided as the fourth parameter!
  exit 1
fi

SCRIPTS_DIR=$(pwd)
echo Scripts Directory: $SCRIPTS_DIR

CREDS_DIR=$(cd ~/.aws;pwd)
echo Credentials Directory: $CREDS_DIR

docker run -i --rm \
 -v $CREDS_DIR:/root/.aws \
 -v $SCRIPTS_DIR:/scripts \
 -w /scripts \
 -e SOURCE_ACCOUNT=$1 \
 -e AWS_PROFILE=$2 \
 -e AWS_AMI_REGIONS=$4 \
 -e IMAGE_NAME=$3 \
 -e SOURCE_LOCATION=us-west-1 \
 -e MAKE_PUBLIC_AMIS=yes \
 -e MAKE_PUBLIC_SNAPSHOTS=yes \
 -e AWS_AMI_ORG_ARN= \
 -e AWS_SNAPSHOT_USER= \
 --entrypoint="/bin/bash" \
 amazon/aws-cli -c "./aws-copy.sh"

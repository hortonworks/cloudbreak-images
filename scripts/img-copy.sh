#!/bin/bash

# This script is a helper meant for copying images to your own account.
# Currently it supports AWS and Azure and requires the below parameters:
###################################################################################
#  AWS
###################################################################################
#   1 Cloud provider, "aws"
#   2 Source AWS account (from which the image is being copied)
#   3 AWS Credentials profile name
#   4 AMI ID
#   5 target regions, commma separated
#
# To have the proper AWS credentials, you'll need to use gimme-aws-creds along with
# Okta - this is the company standard, but technically nothing prevents you
# from setting up a custom ~/.aws/credentials file. Contents the credentials file
# will also provide you the necessary value for the AWS credentials profile name.
# Having Docker installed on your machine is also required to run this script.
#
# Example use:
# ./img-copy.sh aws 1234567890123 default ami-0073e5fb98e2faa3f eu-north-1,eu-west-3
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
#
#
###################################################################################
#  AZURE
###################################################################################
#   Prerequisites:: 
#      - Installed azure-cli tool (for azure login)
#      - Login into the azure via cli. The command: "az login", login window will pop via internet browser 
#
#   1 Cloud provider ("azure")
#   2 AZURE SUBSCRIPTION ID
#   2 AZURE SOURCE STORAGE ACCOUNT KEY
#   3 AZURE SOURCE BLOB ("SourceStorageAccountName/BlobStorageName/ImageName")
#   4 AZURE DESTINAION STORAGE ACCOUNT KEY
#   5 AZURE DESTINATION BLOB ("DestinationStorageAccountName/BlobStorageName/ImageName") 
#
#   Example use:
#   ./img-copy.sh azure subscription_id source_storage_account_key source_storage_account_name/storage_name/image_name storage_account_key destitantion_storage_account_name/blob_storage_name/image_name
#   ./img-copy.sh azure 3ddda1c7-????-????-ac81-0523f483b3b3 ?????Cgtt982SAqBHaVBlHJ1XYvthmSBLQ71KYHsIKCtH/?????PNBXgldT9+/?????fRvtI0n3S6tAbLknIAg== cbimgwu3ddda1c7d1f54e7ba/images/cb-cdh-7217-1704797135.vhd ?????3a7NxagSdWygXRejIUjL8oxcm+k96SM32dv46iarjeDGaadDFOa9Xkxbi1KtNw2+YrSet8y+AStNgby0A== teststorage/testblobcontainer/cb-cdh-7217-1704797135.vhd


if [[ $1 != "aws" && $1 != "azure" ]]; then
    echo Cloud provider \(\"aws\" or \"azure\"\) must be provided as the first parameter!
    exit 1
fi

if [[ $1 == aws ]]; then
    
    if [[ -z $2 ]]; then
      echo Source AWS account ID must be provided as the second parameter!
      exit 1
    fi

    if [[ -z $3 ]]; then
      echo AWS Credentials profile must be provided as the third parameter!
      exit 1
    fi

    if [[ -z $4 ]]; then
      echo Image name must be provided as the fourth parameter!
      exit 1
    fi

    if [[ -z $5 ]]; then
      echo Target regions must be provided as the fifth parameter!
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
    -e MAKE_PUBLIC_SNAPSHOTS=no \
    -e AWS_AMI_ORG_ARN= \
    -e AWS_SNAPSHOT_USER= \
    --entrypoint="/bin/bash" \
    amazon/aws-cli -c "./aws-copy.sh"

 elif [[ $1 == azure ]]; then
    
    if [[ -z $2 ]]; then
      echo AZURE SUBSCRIPTION ID must be provided as the second parameter!
      exit 1
    fi

    if [[ -z $3 ]]; then
      echo AZURE SOURCE STORAGE ACCOUNT KEY must be provided as the third parameter!
      exit 1
    fi

    if [[ -z $4 ]]; then
      echo AZURE SOURCE BLOB must be provided as the fourth parameter! The format: \"StorageAccountName/BlobStorageName/ImageName\"
      exit 1
    fi

    if [[ -z $5 ]]; then
      echo AZURE DESTINAION STORAGE ACCOUNT KEY must be provided as the fifth parameter!
      exit 1
    fi

    if [[ -z $6 ]]; then
      echo AZURE DESTINATION BLOB must be provided as the sixth parameter! The format: \"StorageAccountName/BlobStorageName/ImageName\"
      exit 1
    fi

    SCRIPTS_DIR=$(pwd)
    echo Scripts Directory: $SCRIPTS_DIR

    CREDS_DIR=$(cd ~/.azure;pwd)
    echo Credentials Directory: $CREDS_DIR

    docker run -i --rm \
    -v $SCRIPTS_DIR:/work \
    -v "$CREDS_DIR:/root/.azure" \
    -w /work \
    -e AZURE_SUBSCRIPTION_ID=$2 \
    -e AZURE_SOURCE_STORAGE_ACCOUNT_KEY=$3 \
    -e AZURE_SOURCE_BLOB=$4 \
    -e AZURE_DESTINATION_STORAGE_ACCOUNT_KEY=$5 \
    -e AZURE_DESTINATION_BLOB=$6 \
    --entrypoint "/bin/bash" \
    docker-sandbox.infra.cloudera.com/cloudbreak-tools/cloudbreak-azure-cli-tools:1.25.0 -c ./azure-copy-for-developers.sh

fi

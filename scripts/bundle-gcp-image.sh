#!/bin/bash

: ${GCP_STORAGE_BUNDLE?= required}
: ${GCP_STORAGE_BUNDLE_LOG?= required}
: ${GCP_ACCOUNT_FILE?= required}

if ! [[ -f $GCP_ACCOUNT_FILE ]]; then
	echo "Account file is missing: $GCP_ACCOUNT_FILE"
	exit 2
fi

set -eo pipefail
set -x

: ${START_TIME:=$(date +%s)}
export START_TIME
export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '

: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

export_image_to_bucket() {
	local zone attempt
	for zone in ${GCP_EXPORT_ZONE//,/ }; do
		for ((attempt=1; attempt<=GCP_EXPORT_ZONE_MAX_ATTEMPTS; attempt++)); do
			echo "Exporting ${IMAGE_NAME} in zone ${zone} (attempt ${attempt}/${GCP_EXPORT_ZONE_MAX_ATTEMPTS})..."
			docker rm -f gcloud-create-instance-$IMAGE_NAME || true
			if docker run --rm --name gcloud-create-instance-$IMAGE_NAME --volumes-from gcloud-config-$IMAGE_NAME google/cloud-sdk gcloud compute images export --quiet --destination-uri gs://${GCP_STORAGE_BUNDLE}/${IMAGE_PRE_NAME}${IMAGE_NAME}.tar.gz --image ${IMAGE_NAME} --project ${GCP_PROJECT} --zone ${zone}; then
				return 0
			fi
		done
	done
	return 1
}

main() {

	: ${GCP_PROJECT:=$(cat $GCP_ACCOUNT_FILE | jq .project_id -r)}
	: ${SERVICE_ACCOUNT_EMAIL:=$(cat $GCP_ACCOUNT_FILE | jq .client_email -r)}
	: ${IMAGE_PRE_NAME:=}
	: ${GCP_LABELS:=}
	: ${GCP_EXPORT_ZONE:="us-central1-f,us-central1-a,us-central1-b,us-central1-c"}
	: ${GCP_EXPORT_ZONE_MAX_ATTEMPTS:=2}

	docker rm -f gcloud-config-$IMAGE_NAME || true

    echo "Checking Google Cloud SDK version..."
    docker run google/cloud-sdk:latest gcloud version

    docker run --name gcloud-config-$IMAGE_NAME -v "${GCP_ACCOUNT_FILE}":/gcp.p12 google/cloud-sdk gcloud auth activate-service-account $SERVICE_ACCOUNT_EMAIL --key-file /gcp.p12 --project $GCP_PROJECT

    if docker run --rm --name gcloud-pre-check-$IMAGE_NAME --volumes-from gcloud-config-$IMAGE_NAME google/cloud-sdk gsutil ls gs://${GCP_STORAGE_BUNDLE}/${IMAGE_PRE_NAME}${IMAGE_NAME}.tar.gz 2>/dev/null; then
    	echo ${IMAGE_NAME}.tar.gz already exists, please delete it in order for this job to run
    	docker rm gcloud-config-$IMAGE_NAME
    	exit 1
    fi
	
	if ! export_image_to_bucket; then
		echo "Image export failed in all zones after ${GCP_EXPORT_ZONE_MAX_ATTEMPTS} attempts each: $GCP_EXPORT_ZONE" >&2
		exit 1
	fi
	docker run --rm --name gcloud-create-instance-public-$IMAGE_NAME --volumes-from gcloud-config-$IMAGE_NAME google/cloud-sdk gsutil -m acl ch -r -u AllUsers:R gs://${GCP_STORAGE_BUNDLE}/${IMAGE_PRE_NAME}${IMAGE_NAME}.tar.gz

	# Apply the labels (GCS Metadata)
    if [[ -n "$GCP_LABELS" ]]; then
        echo "Applying GCS metadata labels: $GCP_LABELS"
        # Convert comma-separated key:value pairs into the required -h header format with prefix 'x-goog-meta-'
        HEADER=$(echo "$GCP_LABELS" | sed 's/\([^,]\+\)/x-goog-meta-\1/g' | sed 's/,/ -h /g' | sed 's/^/-h /')
        docker run --rm --name gcloud-set-labels-$IMAGE_NAME --volumes-from gcloud-config-$IMAGE_NAME google/cloud-sdk gsutil setmeta ${HEADER} gs://${GCP_STORAGE_BUNDLE}/${IMAGE_PRE_NAME}${IMAGE_NAME}.tar.gz
    fi

    echo "Removing compute image"
    docker run --rm --name gcloud-remove-compute-image-$IMAGE_NAME --volumes-from gcloud-config-$IMAGE_NAME google/cloud-sdk gcloud compute images delete --quiet $IMAGE_NAME

	exit 0
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

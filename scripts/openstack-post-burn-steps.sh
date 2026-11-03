#!/usr/bin/env bash
#
# openstack-post-burn-steps.sh
#
# Post-burn step for the OpenStack packer build. For the
# freshly burnt image it:
#   1. locates it by name and prints its properties (openstack CLI),
#   2. resolves its ID from the name (openstack CLI),
#   3. sets its visibility to "community" (glance CLI),
#   4. removes the "signature_verified" property (glance CLI; ignored if absent).
#
# Expected environment (exported by the Makefile / build-openstack-redhat9):
#   IMAGE_NAME                   - name of the image just burnt (packer image_name)
#   OPENSTACK_AUTH_URL           - keystone v3 endpoint
#   OPENSTACK_USERNAME           - service account username
#   OPENSTACK_PASSWORD           - service account password
#   OPENSTACK_PROJECT_NAME       - tenant / project
#   OPENSTACK_PROJECT_DOMAIN_ID  - default: "default"
#   OPENSTACK_USER_DOMAIN_ID     - default: "default"
#   OPENSTACK_REGION_NAME
# Optional:
#   CB_OPENSTACK_CLI_TOOLS_VERSION           - image tag to run (default: "dev")
#   CB_OPENSTACK_CLI_TOOLS_IMAGE             - full override of the container image reference

set -euo pipefail

: "${IMAGE_NAME:?IMAGE_NAME is required (name of the image being burnt)}"
: "${OPENSTACK_AUTH_URL:?OPENSTACK_AUTH_URL is required}"
: "${OPENSTACK_USERNAME:?OPENSTACK_USERNAME is required}"
: "${OPENSTACK_PASSWORD:?OPENSTACK_PASSWORD is required}"
: "${OPENSTACK_PROJECT_NAME:?OPENSTACK_PROJECT_NAME is required}"

OPENSTACK_PROJECT_DOMAIN_ID="${OPENSTACK_PROJECT_DOMAIN_ID:-default}"
OPENSTACK_USER_DOMAIN_ID="${OPENSTACK_USER_DOMAIN_ID:-default}"
OPENSTACK_REGION_NAME="${OPENSTACK_REGION_NAME:-}"

# Published by tools/cloudbreak-openstack-cli-tools (see its Makefile: `make release`).
CB_OPENSTACK_CLI_TOOLS_REPO="docker-sandbox.infra.cloudera.com/cloudbreak-tools/cloudbreak-openstack-cli-tools"
CB_OPENSTACK_CLI_TOOLS_VERSION="${CB_OPENSTACK_CLI_TOOLS_VERSION:-dev}"
CB_OPENSTACK_CLI_TOOLS_IMAGE="${CB_OPENSTACK_CLI_TOOLS_IMAGE:-${CB_OPENSTACK_CLI_TOOLS_REPO}:${CB_OPENSTACK_CLI_TOOLS_VERSION}}"

os_env=(
    -e "OS_AUTH_URL=${OPENSTACK_AUTH_URL}"
    -e "OS_USERNAME=${OPENSTACK_USERNAME}"
    -e "OS_PASSWORD=${OPENSTACK_PASSWORD}"
    -e "OS_PROJECT_NAME=${OPENSTACK_PROJECT_NAME}"
    -e "OS_PROJECT_DOMAIN_ID=${OPENSTACK_PROJECT_DOMAIN_ID}"
    -e "OS_USER_DOMAIN_ID=${OPENSTACK_USER_DOMAIN_ID}"
    -e "OS_REGION_NAME=${OPENSTACK_REGION_NAME}"
    -e "OS_IDENTITY_API_VERSION=3"
    -e "OS_IMAGE_API_VERSION=2"
)

run_glance() {
    docker run --rm "${os_env[@]}" "${CB_OPENSTACK_CLI_TOOLS_IMAGE}" glance "$@"
}

run_openstack() {
    docker run --rm "${os_env[@]}" "${CB_OPENSTACK_CLI_TOOLS_IMAGE}" openstack "$@"
}

echo "Locating OpenStack image by name: ${IMAGE_NAME}"
mapfile -t image_ids < <(run_openstack image list --name "${IMAGE_NAME}" -f value -c ID | tr -d '\r')

if [[ "${#image_ids[@]}" -eq 0 || -z "${image_ids[0]}" ]]; then
    echo "ERROR: no OpenStack image found with name '${IMAGE_NAME}'" >&2
    exit 1
fi

if [[ "${#image_ids[@]}" -gt 1 ]]; then
    echo "ERROR: ${#image_ids[@]} images match name '${IMAGE_NAME}'; refusing to guess:" >&2
    printf '  %s\n' "${image_ids[@]}" >&2
    exit 1
fi

IMAGE_ID="${image_ids[0]}"
echo "Found image '${IMAGE_NAME}' -> ${IMAGE_ID}"

echo "Image properties (openstack image show):"
run_openstack image show "${IMAGE_ID}"

echo "Setting visibility to 'community'"
run_glance image-update --visibility community "${IMAGE_ID}"

echo "Removing 'signature_verified' property (ignored if absent)"
run_glance image-update --remove-property signature_verified "${IMAGE_ID}" \
    || echo "note: could not remove 'signature_verified' (likely not set); continuing"

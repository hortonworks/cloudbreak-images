#!/bin/bash

set -xe

if [ -f package-versions.json -a "$stack_version" != "" -a "$clustermanager_version" != "" ]; then
	apk update && apk add jq
	cat package-versions.json
	if [ "$stack_type" == "CDH" ]; then
		cat package-versions.json | jq --arg stack_version $stack_version --arg clustermanager_version $clustermanager_version '. += {"stack" : $stack_version,  "cm" : $clustermanager_version}' > package-versions-tmp.json && mv package-versions-tmp.json package-versions.json
	else
		cat package-versions.json | jq --arg stack_version $stack_version --arg clustermanager_version $clustermanager_version '. += {"stack" : $stack_version,  "ambari" : $clustermanager_version}' > package-versions-tmp.json && mv package-versions-tmp.json package-versions.json
	fi
	cat package-versions.json
fi

echo "pre_warm_parcels: ${pre_warm_parcels}"

pre_warm_parcels=${pre_warm_parcels:-[[\"\"]]}
pre_warm_csd=${pre_warm_csd:-\"\"}

cat  > ${image_name}.json <<EOF
{
"created_at": ${created_at},
"prometheus": ${prometheus},
"created": "${created}",
"git_rev": "${git_rev}",
"git_branch": "${git_branch}",
"git_tag": "${git_tag}",
"os": "${os}",
"os_user": "${os_user}",
"os_type": "${os_type}",
"orchestrator": "${orchestrator}",
"image_name": "${image_name}",
"description": "${description}",
"stack_type": "${stack_type}",
"ambari_version": "${clustermanager_version}",
"ambari_os_type": "${clustermanager_os_type}",
"ambari_baseurl": "$([ "$repository_type" == "local" ] && echo "${local_url_ambari}" || echo "${clustermanager_baseurl}")",
"cm_gpgkey": "${clustermanager_gpgkey}",
"cm_version": "${clustermanager_version}",
"cm_os_type": "${clustermanager_os_type}",
"cm_baseurl": "${clustermanager_baseurl}",
"cm_gpgkey": "${clustermanager_gpgkey}",
"hdp_version": "${stack_version}",
"hdp_os_type": "${stack_os_type}",
"hdp_baseurl": "$([ "$repository_type" == "local" ] && echo "${local_url_hdp}" || echo "${stack_baseurl}")",
"hdp_repoid": "${stack_repoid}",
"cdh_version": "${stack_version}",
"cdh_os_type": "${stack_os_type}",
"cdh_baseurl": "${stack_baseurl}",
"cdh_repoid": "${stack_repoid}",
"hdputil_version": "${hdputil_version}",
"hdputil_os_type": "${hdputil_os_type}",
"hdputil_baseurl": "$([ "$repository_type" == "local" ] && echo "${local_url_hdp_utils}" || echo "${hdputil_baseurl}")",
"hdputil_repoid": "${hdputil_repoid}",
"mpack_urls": $(if [[ -z "$mpack_urls" ]]; then echo []; else mpackjson=$(IFS=, read -ra mpacks <<< "$mpack_urls"; for mpack in "${mpacks[@]}"; do echo "\"${mpack}\","; done); echo "[${mpackjson:0:${#mpackjson}-1}]"; fi),
"aws_ami_regions": "${aws_ami_regions}",
"azure_storage_accounts": "${azure_storage_accounts}",
"gcp_storage_bundle": "${gcp_storage_bundle}",
"hdp_vdf": "$([ "$repository_type" == "local" ] && echo "${local_url_vdf}" || echo "${hdp_vdf}")",
"hdp_repository_version": "${stack_repository_version}",
"cdh_repository_version": "${stack_repository_version#*-}",
"manifest": $(if [ -f ${image_name}_manifest.json ]; then cat ${image_name}_manifest.json; else echo "{}"; fi),
"package_versions": $(if [ -f package-versions.json ]; then cat package-versions.json; else echo "{}"; fi),
"pre_warm_parcels": ${pre_warm_parcels},
"pre_warm_csd": ${pre_warm_csd}
}
EOF

cat ${image_name}.json

exit 0

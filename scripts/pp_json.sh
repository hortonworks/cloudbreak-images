#!/bin/bash

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
"ambari_version": "${ambari_version}",
"ambari_os_type": "${ambari_os_type}",
"ambari_baseurl": "$([ "$repository_type" == "local" ] && echo "${local_url_ambari}" || echo "${ambari_baseurl}")",
"ambari_gpgkey": "${ambari_gpgkey}",
"stack_type": "${stack_type}",
"hdp_version": "${hdp_version}",
"hdp_os_type": "${hdp_os_type}",
"hdp_baseurl": "$([ "$repository_type" == "local" ] && echo "${local_url_hdp}" || echo "${hdp_baseurl}")",
"hdp_repoid": "${hdp_repoid}",
"hdputil_version": "${hdputil_version}",
"hdputil_os_type": "${hdputil_os_type}",
"hdputil_baseurl": "$([ "$repository_type" == "local" ] && echo "${local_url_hdp_utils}" || echo "${hdputil_baseurl}")",
"hdputil_repoid": "${hdputil_repoid}",
"mpack_urls": $(if [[ -z "$mpack_urls" ]]; then echo []; else mpackjson=$(IFS=, read -ra mpacks <<< "$mpack_urls"; for mpack in "${mpacks[@]}"; do echo "\"${mpack}\","; done); echo "[${mpackjson:0:${#mpackjson}-1}]"; fi),
"aws_ami_regions": "${aws_ami_regions}",
"azure_storage_accounts": "${azure_storage_accounts}",
"gcp_storage_bundle": "${gcp_storage_bundle}",
"hdp_vdf": "$([ "$repository_type" == "local" ] && echo "${local_url_vdf}" || echo "${hdp_vdf}")",
"hdp_repository_version": "${hdp_repository_version}",
"manifest": $(if [ -f ${image_name}_manifest.json ]; then cat ${image_name}_manifest.json; else echo "{}"; fi)
}
EOF

exit 0

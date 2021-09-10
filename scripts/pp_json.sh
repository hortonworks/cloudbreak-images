#!/bin/bash

set -xe

if [ -f package-versions.json -a "$stack_version" != "" -a "$clustermanager_version" != "" ]; then
    wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    chmod +x jq-linux64
    mv jq-linux64 /bin/jq

    cat package-versions.json
    if [ "$stack_type" == "CDH" ]; then
        cat package-versions.json | jq --arg stack_version $stack_version --arg clustermanager_version $clustermanager_version --arg cm_build_number $cm_build_number --arg stack_build_number $stack_build_number --arg composite_gbn "$composite_gbn" '. += {"stack" : $stack_version,  "cm" : $clustermanager_version,  "cm-build-number" : $cm_build_number,  "cdh-build-number" : $stack_build_number, "composite_gbn": $composite_gbn}' > package-versions-tmp.json && mv package-versions-tmp.json package-versions.json

        for parcel in ${parcel_list_with_versions//,/ } ; do 
            parcel_versions=(`echo $parcel | tr ':' ' '`)
            cat package-versions.json | jq --arg parcel "${parcel_versions[0]}" --arg version "${parcel_versions[1]}" --arg parcel_gbn "${parcel_versions[0]}_gbn" --arg gbn "${parcel_versions[2]}" '. += {($parcel) : $version, ($parcel_gbn) : $gbn}' >> package-versions-tmp.json && mv package-versions-tmp.json package-versions.json
        done
    else
        cat package-versions.json | jq --arg stack_version $stack_version --arg clustermanager_version $clustermanager_version '. += {"stack" : $stack_version,  "ambari" : $clustermanager_version}' >> package-versions-tmp.json && mv package-versions-tmp.json package-versions.json
    fi
    cat package-versions.json
fi

echo "pre_warm_parcels: ${pre_warm_parcels}"

pre_warm_parcels=${pre_warm_parcels:-[ [ \"\" ] ]}
pre_warm_csd=${pre_warm_csd:-[ \"\" ]}

if [ -z "$image_uuid" ]; then
  image_uuid=$(cat /proc/sys/kernel/random/uuid)
fi


cat  > ${image_name}_$metadata_filename_postfix.json <<EOF
{
"uuid": "${image_uuid}",
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
"gcp_ami_regions": "${gcp_ami_regions}",
"hdp_repository_version": "${stack_repository_version}",
"cdh_repository_version": "${stack_repository_version#*-}",
"cm_build_number": "${cm_build_number}",
"stack_build_number": "${stack_build_number}",
"manifest": $(if [ -f ${image_name}_${metadata_filename_postfix}_manifest.json ]; then cat ${image_name}_${metadata_filename_postfix}_manifest.json; else echo "{}"; fi),
"package_versions": $(if [ -f package-versions.json ]; then cat package-versions.json; else echo "{}"; fi),
"pre_warm_parcels": $(if [[ -z "$pre_warm_parcels" ]]; then echo null; else echo $pre_warm_parcels; fi),
"pre_warm_csd": $(if [[ -z "$pre_warm_csd" ]]; then echo null; else echo $pre_warm_csd; fi)
}
EOF

cat ${image_name}_$metadata_filename_postfix.json

exit 0

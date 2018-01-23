echo $CBD_VERSION
cloudbreak_image="hortonworks/cloudbreak"
cloudbreak_web_image="hortonworks/cb-web"
cloudbreak_auth_image="hortonworks/cb-auth"
periscope_image="hortonworks/cloudbreak-autoscale"
cloudbreak_shell_image="hortonworks/cloudbreak-shell"

cloud_web_image="hortonworks/hdc-web"
cloud_auth_image="hortonworks/hdc-auth"

exist_tag() {
    local is_tag_exist=$(curl -Ls -H "Content-Type:application/json" https://registry.hub.docker.com/v2/repositories/$1/tags?page_size=100 | jq '.results[]| select (.name=="'${CBD_VERSION}'")| .name' -r)
    echo $is_tag_exist
}

build_in_progress() {
	local build_code=$(curl -Ls -H "Content-Type:application/json" https://registry.hub.docker.com/v2/repositories/$1/buildhistory | jq -r '. |[.results | sort_by(.id)  | .[]|select(.dockertag_name=="'${CBD_VERSION}'")]|sort_by(.id)|.[].status' |tail -1)
	echo $build_code
}

test_docker_build_finished() {
	local test_tag=$(exist_tag "$1")
	echo "Test $1 tag exist on docker hub ${test_tag}..."
	if ! [[ "$test_tag" ]]; then 
	    local count=0
	    local test_code=$(build_in_progress $1)
            echo "Test $1 build progress ${test_code}..."
	    while [[ $test_code -ne 10 ]] && [[ $test_code -ne -1 ]] && [ $((count++)) -lt 480 ] ; do
	        test_code=$(build_in_progress $1)
	        echo "Test $1 build progress ${test_code}..."
	        sleep 15;
	    done
	    if [[ $count -gt 480 ]]; then
	    	echo "Image tag $1 failed to create."
	    	exit -1
	    fi
	    if [[ $test_code -eq -1 ]]; then
	    	echo "Image tag $1 failed to create."
	    	exit -1
	    fi
	fi
}

docker_hub_check_start() {
	echo "Start polling cloudbreak image."
	test_docker_build_finished $cloudbreak_image

	if [[ $CBD_VERSION == 1* ]]; then 
		echo "Start polling cloudbreak web image."
		test_docker_build_finished $cloudbreak_web_image

		echo "Start polling cloudbreak auth image."
		test_docker_build_finished $cloudbreak_auth_image
	fi
	
	echo "Start polling cloudbreak periscope image."
	test_docker_build_finished $periscope_image

	echo "Start polling cloud web image."
	test_docker_build_finished $cloud_web_image

	echo "Start polling cloud auth image."
	test_docker_build_finished $cloud_auth_image
}

function main() {
    docker_hub_check_start
}

main && exit || exit

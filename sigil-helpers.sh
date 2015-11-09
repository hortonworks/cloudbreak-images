#!/bin/bash

generate_images_var() {
	sed -n 's/\(cb_[^:]*\):.*/{{ user `\1` }}/p' vars-docker-images.yml | xargs
}

helper_generate_atlas_metadata() {
	sigil -i '{{ range $v,$val := yaml "vars-versions.yml" }}"{{$v}}": "{{"{{"}} user `{{$v}}` {{"}}"}}",{{"\n"}}{{end}}'
}

helper_generate_all_images_json() {
	#sigil -i '"all_docker_images":"{{ range $v,$val := yaml "vars-docker-images.yml" }}{{"{{"}} user `{{$v}}` {{"}}"}},{{end}}"'
    sed -n 's/\(cb_docker[a-z_]*\).*/{{ user `\1` }}/p'  vars-docker-images.yml | sed -n 'H; $ {x;s/\n/,/gp;}'
}

helper_generate_all_images_yaml() {
    sigil -i 'all: "{{ range $v,$val := yaml "vars-docker-images.yml" }}{{"{{"}} .Config.PackerUserVars.{{$v}} {{"}}"}},{{end}}"'
}

main() {
    echo ===
    generate_images_var

    echo -e "\n==="
    helper_generate_atlas_metadata
    echo -e "\n==="
    helper_generate_all_images_json
    echo -e "\n==="
    helper_generate_all_images_yaml
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

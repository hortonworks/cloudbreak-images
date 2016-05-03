#!/bin/bash

helper_generate_atlas_metadata() {
	sigil -i '{{ range $v,$val := yaml "vars-versions.yml" }}"{{$v}}": "{{"{{"}} user `{{$v}}` {{"}}"}}",{{"\n"}}{{end}}'
}

main() {
    echo ===
    helper_generate_atlas_metadata
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"

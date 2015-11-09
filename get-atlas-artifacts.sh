
alias r=". $BASH_SOURCE"

slug() {
    [[ "$MOCK" ]] && echo mock || echo cloudbreak
}

get_last_type() {
    declare artifactType=${1:? artifact type required}

    curl -Ls https://atlas.hashicorp.com/api/v1/artifacts/sequenceiq/$(slug)/${artifactType}/search | jq .versions[0]
}

get_all() {
    for t in amazon googlecompute openstack; do
        echo "---> get latest artifact: $t"
        #get_last_type $t.image > $t.image.json
        #get_last_type $t.yml
        curl -L  https://atlas.hashicorp.com/api/v1/artifacts/sequenceiq/mock/$t.yml/1/file | tar -xzO | yaml2json | jq . 
    done

}

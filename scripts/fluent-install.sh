#!/bin/bash

function install_fluent_yum() {
    echo "Install fluentd for CentOS/Redhat"
    curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent3.sh | sh
}

function install_fluent_debian() {
    echo "Install fluentd for Debian"
    # TODO: if there is a newer debian, it will use a different script - so keep this switch / case statements
    case ${OS_TYPE} in
        debian9)
            curl -L https://toolbelt.treasuredata.com/sh/install-debian-stretch-td-agent3.sh | sh
            ;;
        *)
            echo "Unsupported os type: ${OS_TYPE} it is not a fatal error, but Fluent installation will be skipped."
            exit 0
            ;;
    esac
}

function install_fluent_ubuntu() {
    echo "Install fluentd for Ubuntu"
    case ${OS_TYPE} in
        ubuntu14)
            curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-trusty-td-agent3.sh | sh
            ;;
        ubuntu16)
            curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-xenial-td-agent3.sh | sh
            ;;
        ubuntu18)
            curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-bionic-td-agent3.sh | sh
            ;;
        *)
            echo "Unsupported os type: ${OS_TYPE} it is not a fatal error, but Fluent installation will be skipped."
            exit 0
            ;;
    esac
}

function install_extra_gems() {
    echo "Install required fluentd gems"
    /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-cloudwatch-logs
}

function main() {
    if [[ "${INCLUDE_FLUENT}" != "Yes" && "${INCLUDE_FLUENT}" != "true" ]]; then
        echo "INCLUDE_FLUENT environment variable is set to '${INCLUDE_FLUENT}', skipping Fluent installation."
        exit 0
    fi
    case ${OS} in
        centos*|redhat*)
            install_fluent_yum
            install_extra_gems
            ;;
        debian*)
            install_fluent_debian
            install_extra_gems
            ;;
        ubuntu*)
            install_fluent_ubuntu
            install_extra_gems
            ;;
        amazonlinux)
            echo "Install fluentd for Amazon linux 1"
            curl -L https://toolbelt.treasuredata.com/sh/install-amazon1-td-agent3.sh | sh
            install_extra_gems
            ;;
        amazonlinux2)
            echo "Install fluentd for Amazon linux 2"
            curl -L https://toolbelt.treasuredata.com/sh/install-amazon2-td-agent3.sh | sh
            install_extra_gems
            ;;
        *)
            echo "WARNING: Unsupported platform: ${OS}, it is not a fatal error, but Fluent installation will be skipped."
            exit 0
            ;;
    esac
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
os_user: {{ salt['environ.get']('OS_USER') }}
subtype: {% if salt['file.directory_exists']('/yarn-private') %}Docker{% else %}''{% endif %}

# https://tedops.github.io/how-to-find-default-active-ethernet-interface.html
network_interface: {{ salt['network.default_route']('inet')[0]['interface'] }}

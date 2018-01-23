os_user: {{ salt['environ.get']('OS_USER') }}
subtype: {{ salt['grains.get']('virtual_subtype') | default('', True) }}

# https://tedops.github.io/how-to-find-default-active-ethernet-interface.html
network_interface: {{ salt['network.default_route']('inet')[0]['interface'] }}
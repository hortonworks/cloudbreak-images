os_user: {{ salt['environ.get']('OS_USER') }}
subtype: {% if salt['grains.get']('virtual') == 'bhyve' or salt['grains.get']('virtual_subtype') == 'Docker' %}Docker{% else %}''{% endif %}

# https://tedops.github.io/how-to-find-default-active-ethernet-interface.html
network_interface: {{ salt['network.default_route']('inet')[0]['interface'] }}

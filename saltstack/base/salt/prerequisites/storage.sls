{% if pillar['OS'] == 'redhat7' %}

# extending space of /opt on redhat7 images to 25GB (currently it takes up ~19GB in centos7 images)

extend_opt_logical_volume:
  cmd.run:
    - name: lvextend -L25G -r /dev/mapper/rootvg-optlv

{% endif %}

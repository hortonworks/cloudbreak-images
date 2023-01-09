{% if pillar['OS'] == 'redhat7' %}

# extending space of /opt on redhat7 images to 25GB (currently it takes up ~19GB in centos7 images)

install_lvm2:
  pkg.installed:
    - name: lvm2

view_lvs:
  cmd.run:
    - name: pvs --segments -o+lv_name,seg_start_pe,segtype

#extend_opt_logical_volume:
#  cmd.run:
#    - name: lvextend -L25G -r /dev/mapper/rootvg-optlv

{% endif %}

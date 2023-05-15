install_saltbootstrap:
  archive.extracted:
    - name: /usr/sbin/
#    - source: https://github.com/hortonworks/salt-bootstrap/releases/download/v0.13.6/salt-bootstrap_0.13.6_Linux_{{ grains['osarch'] }}.tgz
    - source: https://cb-group.s3.eu-central-1.amazonaws.com/dbajzath/salt-bootstrap_0.13.6_Linux-arm_x86_64.tgz?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEIf%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDGV1LWNlbnRyYWwtMSJGMEQCIBIwMsWlZe3e71uXmKBHto6GWzDCn1PaSVHvS1A8fIlOAiBxfzKLIgikoEnw7vItwqT%2BpMI%2F5H5EbmM%2Fd9pKPy9gcyqfAwgwEAQaDDE1MjgxMzcxNzcyOCIMdOEf8AAFrkTfxW1mKvwCz8WEDzo66piNLG7%2FKDNuszZouJT2toElkgqtL0SjAPbSHsTnBXEf7mZyxdRVnqCA6ljZ4XQJdxXaJsbf2koZD7WgNc4kUYijMarkinZLX524kVnDg9Yv2TnEV1i%2Fl6BGxkMHl60hlUbF8h0NBq5knY9JbIaIHo2TrTZO5XrGWDs7iCN2IGP5LvAMFHbEZnAaCYK0u1J858aKIxniX%2F1vqzeeUiAFqHgbEvDInJ6FgE%2F0kwy5uvCVH1CMXOPUDp9wVC3FxOnqScwwbyxvRVd4t16YB56LBOjzPwIqucGt0M7ie7FsivBPDQHKkqo%2BWLH1QFql%2F%2BbPSaSgCyamcyQWAS6oYB%2Bcks0nly7ZKlA4BBe%2BwhcDU%2BA1%2FEdD1p%2BgCOCgYKbm8sYzi6Lu1bWSr3OmE6zsuTsMWAqzmhong2dpAyJuwJVEQVLtYL%2FzCOnFLA%2F5wtNDRMlC9FdfhRkTE3OA%2BKjgUJjsu1xHKiwxwPqTWizUv2jMg1RgWlkYku0wsd3LswY6hQJzGj0W9s9DpuQg9aY8nxBqah3S1Z2p2YIslHYgdjifQnro%2FvCbzcSyrizakm5iaWA5fgdzHPWMyxHF4C3snOU%2BxADk1DzDmqYd8F5tvnlPVvW3SS3ir%2BZv1wbSq%2Btp5jTwINIOegXW6AYBKUMH96%2BCbZz1yzfxL2SpXLVEn5tXzTDcbQpx46DEoBc54ZzqDGg9mzXMOBm9wBVTdbL0yHzpT5liiD16BUFLNIb0X7NfQuvGAPhTtMg9mH%2FSY7HbbEPpiOfJqxSCBbUP5sFCS753%2F0%2FzqGqj7N8z%2FifUrEEjikLflZb2hxteAU4mWBqlvHIE%2BNZ%2BkXGgOuKlH0QVhLnjaKfnQRc%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20240619T145115Z&X-Amz-SignedHeaders=host&X-Amz-Expires=43200&X-Amz-Credential=ASIASHFDIJDQIZ74UJOF%2F20240619%2Feu-central-1%2Fs3%2Faws4_request&X-Amz-Signature=5dd1e14ccd03ac7a6d862652d7d710b35f892dd7aba07acab7941c86f8f20a8c
    - source_hash: md5=f162b412cf01b22b25324c087b3d1787
    - archive_format: tar
    - enforce_toplevel: false
    - user: root
    - group: root
    - skip_verify: True
    - if_missing: /usr/sbin/salt-bootstrap

create_saltbootstrap_service_files:
  file.managed:
    - user: root
    - group: root
    - name: /etc/systemd/system/salt-bootstrap.service
    - template: jinja
    - source: salt://{{ slspath }}/etc/systemd/system/salt-bootstrap.service

salt-bootstrap:
{% if pillar['subtype'] != 'Docker' %}
  service.running:
    - enable: True
{% else %}
  cmd.run:
    - name: systemctl enable salt-bootstrap
{% endif %}
    - require:
      - install_saltbootstrap
      - create_saltbootstrap_service_files

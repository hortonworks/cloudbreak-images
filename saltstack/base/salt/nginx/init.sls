install_nginx:
  pkg.installed:
    - refresh: False
    - pkgs:
      - nginx

/etc/nginx:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://{{ slspath }}/etc/nginx/nginx.conf

enable_nginx:
  service.enabled:
    - name: nginx
    - require:
      - pkg: install_nginx
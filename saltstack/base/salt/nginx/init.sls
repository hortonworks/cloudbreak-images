install_nginx:
  pkg.installed:
    - refresh: False
    - pkgs:
      - nginx

/etc/nginx:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - template: jinja
    - source: salt://{{ slspath }}/etc/nginx/nginx.conf

/etc/nginx/sites-enabled/ssl-template:
  file.managed:
    - name: /etc/nginx/sites-enabled/ssl-template
    - makedirs: True
    - source: salt://{{ slspath }}/etc/nginx/ssl.conf

enable_nginx:
  service.enabled:
    - name: nginx
    - require:
      - pkg: install_nginx
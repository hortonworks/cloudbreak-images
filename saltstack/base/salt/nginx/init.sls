{% if pillar['OS'] == 'redhat8' %}
install_nginx_redhat8:
  cmd.run:
    - name: |
        sudo dnf module reset nginx -y
        sudo dnf module enable nginx:1.20 -y
        sudo dnf install nginx -y
{% else %}
install_nginx:
  pkg.installed:
    - refresh: False
    - pkgs:
      - nginx
{% endif %}

/etc/nginx:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - template: jinja
    - source: salt://{{ slspath }}/etc/nginx/nginx.conf

/etc/nginx/sites-enabled/ssl-template:
  file.managed:
    - name: /etc/nginx/sites-enabled/ssl-template
    - template: jinja
    - makedirs: True
    - source: salt://{{ slspath }}/etc/nginx/ssl.conf

enable_nginx:
  service.enabled:
    - name: nginx
{% if pillar['OS'] == 'centos7' %}
    - require:
      - pkg: install_nginx
{% endif %}

nginxRestart:
  file.line:
    - name: /usr/lib/systemd/system/nginx.service
    - mode: ensure
    - content: "Restart=always"
    - after: \[Service\]
    - backup: False

nginxRestartSec:
  file.line:
    - name: /usr/lib/systemd/system/nginx.service
    - mode: ensure
    - content: "RestartSec=3"
    - after: "Restart=always"
    - backup: False
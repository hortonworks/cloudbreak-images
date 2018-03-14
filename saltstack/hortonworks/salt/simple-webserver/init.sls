install_ruby_ws:
  file.managed:
    - name: /usr/local/bin/simplews.rb
    - source:
      - salt://{{ slspath }}/usr/local/bin/simplews.rb

run_ruby_ws:
  cmd.run:
    - name: ruby /usr/local/bin/simplews.rb / 9999 admin secret
    - unless: netstat -tapn | grep 9999

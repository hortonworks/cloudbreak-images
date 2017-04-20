install_ruby_ws:
  file.managed:
    - name: /tmp/simplews.rb
    - source:
      - salt://{{ slspath }}/tmp/simplews.rb

run_ruby_ws:
  cmd.run:
    - name: ruby /tmp/simplews.rb / 9999 admin secret
    - unless: netstat -tapn | grep 9999
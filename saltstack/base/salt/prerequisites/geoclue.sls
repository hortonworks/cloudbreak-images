disable_geoclue_service:
  service.masked:
    - name: geoclue

echo_geoclue_user_and_group:
  cmd.run:
    - name: |
        id -u geoclue
        id -g geoclue
# move_geoclue_user_and_group:
#   cmd.run:
#     - name: |
#        usermod -u 10002 geoclue
#        groupmod -g 10002 geoclue
#        find / -not -path "/proc/*" -user 987 -exec chown -h geoclue {} \;
#        find / -not -path "/proc/*" -group 987  -exec chgrp -h geoclue {} \;

geoclue_info:
  cmd.run:
    - name: dnf repoquery --alldeps --recursive --whatrequires geoclue2

remove_geoclue:
  pkg.removed:
    - name: geoclue2
disable_geoclue_service:
  service.masked:
    - name: geoclue

remove_geoclue:
  pkg.removed:
    - name: geoclue2

remove_geoclue_user:
  user.absent:
    - name: geoclue

remove_geoclue_group:
  group.absent:
    - name: geoclue

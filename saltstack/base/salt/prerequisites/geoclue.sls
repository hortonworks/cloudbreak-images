disable_geoclue_service:
  service.masked:
    - name: geoclue

remove_geoclue:
  pkg.removed:
    - name: geoclue2
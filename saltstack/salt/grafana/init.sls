create_grafana_repo:
  pkgrepo.managed:
    - name: Grafana
    - humanname: "GRAFANA"
    - baseurl: https://packagecloud.io/grafana/stable/el/7/$basearch
    - gpgcheck: 1
    - gpgkey: https://grafanarel.s3.amazonaws.com/RPM-GPG-KEY-grafana
    - priority: 1
    - enabled: 1

grafana:
  pkg:
    - installed
    - pkgs: [grafana]
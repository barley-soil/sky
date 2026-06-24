echo "clients:
  - url: http://${LOKI_HOST-loki}:3100/loki/api/v1/push

scrape_configs:
  - job_name: logs
    pipeline_stages:
      - limit:
          rate: 100
          burst: 200
          max_line_size: 200000
    static_configs:
      - targets:
          - localhost
        labels:
          app: ${APPLICATION_NAME:-promtail}
          env: ${APPLICATION_ENV:-prod}
          system: ${APPLICATION_SYSTEM:-promtail}
          instance: ${APPLICATION_INSTANCE:-default}
          region: ${APPLICATION_REGION:-shanghai}
          __path__: /logs/*.log

" > /etc/promtail/config.yml
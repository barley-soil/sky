echo "clients:
  # Loki 服务的 URL
  - url: http://${LOKI_HOST-loki}:3100/loki/api/v1/push

scrape_configs:
  # 配置日志扫描和标签
  - job_name: logs
    static_configs:
      # 可为空，Promtail 是从本地收集日志
      - targets:
          - localhost
        labels:
          app: ${APPLICATION_NAME:-promatail}
          env: ${APPLICATION_ENV:-prod}
          system: ${APPLICATION_SYSTEM:-promatail}
          instance: ${APPLICATION_INSTANCE:-default}
          region: ${APPLICATION_REGION:-shanghai}
          # 指定扫描的日志文件目录
          __path__: /logs/*.log" > /etc/promtail/config.yml

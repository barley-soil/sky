FROM billbear-cn-shanghai.cr.volces.com/base/grafana/promtail:3.4.2-base
ADD ./promtail.sh /promtail.sh
RUN chmod +x /promtail.sh
ENV LOKI_HOST=127.0.0.1
ENV APPLICATION_NAME=LOKI
ENV APPLICATION_ENV=DEV
ENV APPLICATION_SYSTEM=LOKI
ENV APPLICATION_INSTANCE=DEFAULT
ENV APPLICATION_REGION=SHANGHAI
ENTRYPOINT []
CMD ["sh", "-c", "/promtail.sh && /usr/bin/promtail -config.file=/etc/promtail/config.yml"]

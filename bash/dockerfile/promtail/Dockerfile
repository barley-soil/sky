FROM billbear-cn-shanghai.cr.volces.com/base/ubuntu:24.04 as ub24
RUN apt update && apt install -y wget \
  && wget -O /promtail.sh https://gitlab.liexiong.net/yunzhou/config/-/raw/main/grafana/promtail/promtail.sh


FROM billbear-cn-shanghai.cr.volces.com/base/grafana/promtail:3.4.2-base
COPY --from=ub24 /promtail.sh /promtail.sh
RUN chmod +x /promtail.sh
ENV LOKI_HOST=127.0.0.1
ENV APPLICATION_NAME=LOKI
ENV APPLICATION_ENV=DEV
ENV APPLICATION_SYSTEM=LOKI
ENV APPLICATION_INSTANCE=DEFAULT
ENV APPLICATION_REGION=SHANGHAI
ENTRYPOINT []
CMD ["sh", "-c", "/promtail.sh && /usr/bin/promtail -config.file=/etc/promtail/config.yml"]

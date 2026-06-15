FROM debian:oldstable-slim

RUN apt-get update && \
    apt-get install -y locales cron curl bzip2 && \
    sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=zh_CN.UTF-8

ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

RUN groupadd -g 1000 resticgroup && \
    useradd -m -u 1000 -g resticgroup -s /bin/bash resticuser

# 安装 restic 0.18.1
RUN curl -L https://github.com/restic/restic/releases/download/v0.18.1/restic_0.18.1_linux_amd64.bz2 \
    -o /tmp/restic.bz2 && \
    bunzip2 /tmp/restic.bz2 && \
    mv /tmp/restic /usr/local/bin/restic && \
    chmod +x /usr/local/bin/restic

WORKDIR /data
COPY backup.sh /data/backup.sh
RUN touch /tmp/backup.log && touch /var/log/backup.log && \
    mkdir -p /data/source && mkdir -p /data/target && \
    chown -R resticuser:resticgroup /data /tmp/backup.log /var/log/backup.log && \
    chmod +x /data/backup.sh

USER resticuser

ENV RESTIC_CACHE_DIR=/home/resticuser/.cache/restic

CMD ["/bin/bash", "-c", "while true; do /data/backup.sh >> /tmp/backup.log 2>&1; sleep 86400; done"]

FROM billbear-cn-shanghai.cr.volces.com/base/openjdk:21-slim-bullseye
RUN apt-get update && apt-get install -y wget curl telnet vim iputils-ping net-tools unzip procps fonts-dejavu fontconfig && \
    mkdir -p /app/arthas && wget -O /app/arthas/arthas-bin.zip https://github.com/alibaba/arthas/releases/download/arthas-all-3.7.2/arthas-bin.zip

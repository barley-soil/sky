FROM billbear-cn-shanghai.cr.volces.com/base/ibm-semeru-runtimes:open-25-jdk-noble


RUN apt-get update && \
    apt-get install -y wget curl telnet vim iputils-ping net-tools unzip procps fonts-dejavu fontconfig && \
    echo "Arthas .." && \
    mkdir -p /app/arthas && wget -O /app/arthas/arthas-bin.zip https://github.com/alibaba/arthas/releases/download/arthas-all-3.7.2/arthas-bin.zip && \
    echo "OpenTelemetry .." && \
    wget -O /app/opentelemetry-javaagent.jar https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.18.1/opentelemetry-javaagent.jar
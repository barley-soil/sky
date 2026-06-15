#!/bin/sh
export OTEL_RESOURCE_ATTRIBUTES="application.env=${APPLICATION_ENV},application.system=${APPLICATION_SYSTEM},application.name=${APPLICATION_NAME}"
export OTEL_SERVICE_NAME=${APPLICATION_NAME}

exec java ${AGENT} ${JAVA_OPS} -jar app.jar \
  -Djava.security.egd=file:/dev/./urandom \
  -XX:+UseContainerSupport \
  -XX:InitialRAMPercentage=65 \
  -XX:MaxRAMPercentage=80 \
  ${JAR_OPS}

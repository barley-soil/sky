FROM billbear-cn-shanghai.cr.volces.com/base/billbear-jdk:openj9-25
ENV LANG=zh_CN.UTF-8 TZ=Asia/Shanghai
ADD ./billbear-ai-llm-proxy.jar /app/app.jar
WORKDIR /app
CMD ["sh", "-c", "java -Duser.timezone=GMT+08 -Djava.security.egd=file:/dev/./urandom -XX:+UseContainerSupport -XX:InitialRAMPercentage=65 -XX:MaxRAMPercentage=80 -jar app.jar"]
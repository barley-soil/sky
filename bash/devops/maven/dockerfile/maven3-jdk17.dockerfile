FROM billbear-cn-shanghai.cr.volces.com/base/maven:3.9.0-ibm-semeru-17-focal AS builder
ENV GL_TOKEN __GL_TOKEN__
WORKDIR /code
COPY . /code
# 配置: 下载 Maven 配置文件
RUN echo "Download => [setting.xml]" && curl -o /root/.m2/settings.xml 'https://gitlab.liexiong.net/api/v4/projects/yunzhou%2Fsecret/repository/files/maven%2Fbillbear-settings2.xml/raw?ref=main' --header "PRIVATE-TOKEN: ${GL_TOKEN}"
# 配置: 下载 log4j2.xml 配置文件
RUN echo "Download => [log4j2.xml]" && curl -o log4j2.xml 'https://gitlab.liexiong.net/api/v4/projects/yunzhou%2Fsecret/repository/files/log4j2%2Flog4j2.xml/raw?ref=main' --header "PRIVATE-TOKEN: ${GL_TOKEN}"
# 执行: 编译 Java 程序
RUN cd /code __PACKAGE_BEFORE__ && mvn -T 4C clean package -Dmaven.test.skip=true __PACKAGE_AFTER__

FROM billbear-cn-shanghai.cr.volces.com/base/billbear-jdk:openj9-17
ENV LANG zh_CN.UTF-8
ENV BUILD_TIME __BUILD_TIME__
ENV APPLICATION_NAME __APPLICATION_NAME__
ENV COMMIT_ID __COMMIT_ID__
COPY --from=builder /code/__OUTPUT__ /app/app.jar
COPY --from=builder /code/log4j2.xml /app/log4j2.xml
WORKDIR /app
CMD ["sh", "-c", "java ${AGENT} ${JAVA_OPS} -jar app.jar -Djava.security.egd=file:/dev/./urandom -XX:+UseContainerSupport -XX:InitialRAMPercentage=65 -XX:MaxRAMPercentage=80 -DthreadPool.corePoolSize=32 -DthreadPool.maxPoolSize=128 -Dio.netty.resolver.dns.disabled=true -Dreactor.schedulers.defaultBoundedElasticSize=4096 -Dreactor.schedulers.defaultBoundedElasticQueueSize=40960 -Djdk.http.auth.tunneling.disabledSchemes= -Djdk.http.auth.proxying.disabledSchemes= ${JAR_OPS}"]
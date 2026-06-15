#!/usr/bin/env bash
# maven3-jdk21-ssh
# Usage: maven3-jdk21-ssh

set -euo pipefail

# WeChat Robot
push_wechat_message() {
  echo "Send weChat Message .."

  local RUN_STATUS="${1:-false}"
  local MESSAGE_ROBOT="$GL_WECHAT_ROBOT"
  local MESSAGE_TEMPLATE="$GL_WECHAT_TEMPLATE"
  local MESSAGE_ENVIRONMENT_NAME=""

  case "${ENVIRONMENT_NAME^^}" in
  "DEV") MESSAGE_ENVIRONMENT_NAME="开发环境" ;;
  "TEST") MESSAGE_ENVIRONMENT_NAME="测试环境" ;;
  "PREV") MESSAGE_ENVIRONMENT_NAME="预生产环境" ;;
  "PROD") MESSAGE_ENVIRONMENT_NAME="生产环境" ;;
  *) MESSAGE_ENVIRONMENT_NAME="${ENVIRONMENT_NAME:-未知环境}" ;;
  esac

  declare -A MESSAGE_PARAMS
  if [ "$RUN_STATUS" = "true" ]; then
    MESSAGE_PARAMS[title]='<font color="info">构建成功</font>'
    MESSAGE_PARAMS[failReason]=''
  else
    MESSAGE_PARAMS[title]='<font color="warning">构建失败</font>'
    if [ -n "$2" ]; then
      MESSAGE_PARAMS[failReason]="\r\n> **失败原因**：[点击查看详情](${CI_JOB_URL:-#}) 脚本第 $2 行命令 \`$3\` 执行失败。"
    else
      MESSAGE_PARAMS[failReason]="\r\n> **失败原因**：[点击查看详情](${CI_JOB_URL:-#}) ${MESSAGE:-未知错误}"
    fi
  fi
  MESSAGE_PARAMS[projectName]="${P_PROJECT_NAME:-}"
  MESSAGE_PARAMS[author]="${CI_COMMIT_AUTHOR:-}"
  MESSAGE_PARAMS[env]="$MESSAGE_ENVIRONMENT_NAME"
  MESSAGE_PARAMS[commitRefName]="${CI_COMMIT_REF_NAME:-}"
  MESSAGE_PARAMS[description]="${CI_COMMIT_MESSAGE:-}"
  MESSAGE_PARAMS[commitId]="${CI_COMMIT_SHA:-}"
  MESSAGE_PARAMS[link]="${CI_JOB_URL:-}"

  for k in "${!MESSAGE_PARAMS[@]}"; do
    export "V_$k"="${MESSAGE_PARAMS[$k]}"
  done

  local MESSAGE_RAW_CONTENT
  MESSAGE_RAW_CONTENT=$(awk -v template="$MESSAGE_TEMPLATE" '
    BEGIN {
      for (k in ENVIRON) if (k ~ /^V_/) {
        key = substr(k, 3); val = ENVIRON[k]
        if (key ~ /^(projectName|author|commitRefName|description)$/) {
          gsub(/\*/, "", val); gsub(/> /, "", val); gsub(/\n/, " ", val);
          gsub(/<br\/>/, "\n", val); gsub(/%/, " ", val); gsub(/\r/, "", val);
        }
        vars[key] = val
      }
      result = template
      for (k in vars) {
        gsub("#{" k "}", vars[k], result)
      }
      print result
    }
  ')

  for k in "${!MESSAGE_PARAMS[@]}"; do unset "V_$k"; done

  local MESSAGE_REQUEST
  MESSAGE_REQUEST=$(jq -n --arg content "$MESSAGE_RAW_CONTENT" '{msgtype: "markdown", markdown: {content: $content}}')
  curl -s -X POST -H "Content-Type: application/json" -d "$MESSAGE_REQUEST" "$MESSAGE_ROBOT"
}

# Exit message
trap 'push_wechat_message "false" "$LINENO" "$BASH_COMMAND"; exit 1' ERR

# Workdir
WORKDIR=$(pwd)

# Environment
ENVIRONMENT_NAME="${CI_ENVIRONMENT_NAME:-}"
if [ -z "$ENVIRONMENT_NAME" ]; then
  echo "Not CI_ENVIRONMENT_NAME" >&2
  exit 1
fi

echo "Download Config ..."

# Download setting.xml
echo "Download ==> [setting.xml]"
curl -o settings.xml 'https://gitlab.liexiong.net/api/v4/projects/yunzhou%2Fsecret/repository/files/maven%2Fbillbear-settings2.xml/raw?ref=main' --header "PRIVATE-TOKEN: ${GL_TOKEN}"

# Download Log4j2
echo "Download ==> [log4j2.xml]"
curl -o log4j2.xml 'https://gitlab.liexiong.net/api/v4/projects/yunzhou%2Fsecret/repository/files/log4j2%2Flog4j2.xml/raw?ref=main' --header "PRIVATE-TOKEN: ${GL_TOKEN}"

# Download docker auth.json
echo "Download ==> [docker_auth.json]"
mkdir -p docker_config
curl -o docker_config/config.json "https://gitlab.liexiong.net/api/v4/projects/yunzhou%2Fsecret/repository/files/docker%2F$P_DOCKER_AUTH_TYPE.json/raw?ref=main" --header "PRIVATE-TOKEN: ${GL_TOKEN}"

# Deploy
# P_PACKAGE_BEFORE: Deploy before
# P_PACKAGE_AFTER: Deploy after
docker run --rm \
  -v "$WORKDIR":/code \
  -v /home/repository/"$CI_PROJECT_ID":/root/.m2/repository \
  billbear-cn-shanghai.cr.volces.com/base/maven:3.9-ibm-semeru-21-jammy \
  sh -c "cp -a /code/settings.xml /root/.m2/settings.xml && cd /code ${P_PACKAGE_BEFORE:-} && mvn -U -T 4C clean package -Dmaven.test.skip=true ${P_PACKAGE_AFTER:-}"

# Dockerfile
BUILD_TIME=$(date "+%Y_%m_%d_%H_%M_%S")
BUILD_APPLICATION_NAME="$CI_PROJECT_NAME"
BUILD_COMMIT_ID="$CI_COMMIT_SHA"
BUILD_OUTPUT="$P_OUTPUT"
cat <<'EOF' | sed "s|__BUILD_TIME__|$BUILD_TIME|g; s|__APPLICATION_NAME__|$BUILD_APPLICATION_NAME|g; s|__COMMIT_ID__|$BUILD_COMMIT_ID|g; s|__OUTPUT__|$BUILD_OUTPUT|g" >Dockerfile
FROM billbear-cn-shanghai.cr.volces.com/base/billbear-jdk:openj9-21
ENV LANG zh_CN.UTF-8
ENV BUILD_TIME __BUILD_TIME__
ENV APPLICATION_NAME __APPLICATION_NAME__
ENV COMMIT_ID __COMMIT_ID__
ADD ./__OUTPUT__ /app/app.jar
ADD ./log4j2.xml /app/log4j2.xml
WORKDIR /app
CMD ["sh", "-c", "java ${AGENT} ${JAVA_OPS} -jar app.jar -Djava.security.egd=file:/dev/./urandom -XX:+UseContainerSupport -XX:InitialRAMPercentage=65 -XX:MaxRAMPercentage=80  -DthreadPool.corePoolSize=32 -DthreadPool.maxPoolSize=128 -Dio.netty.resolver.dns.disabled=true -DthreadPool.corePoolSize=32 -DthreadPool.maxPoolSize=128 -Dio.netty.resolver.dns.disabled=true -Dreactor.schedulers.defaultBoundedElasticSize=4096 -Dreactor.schedulers.defaultBoundedElasticQueueSize=40960 -Djdk.http.auth.tunneling.disabledSchemes= -Djdk.http.auth.proxying.disabledSchemes= ${JAR_OPS}"]
EOF

# Build Docker Image
echo " "
echo " "
echo "Docker build 「${P_IMAGE_NAME}」.."
docker build --pull -t "${P_IMAGE_NAME}" .

# Docker Push
echo " "
echo " "
echo "Docker push 「${P_IMAGE_NAME}」.."
docker --config "$WORKDIR/docker_config" push "${P_IMAGE_NAME}"

# Release Kubernetes
echo " "
echo " "
echo " "
echo " "
echo "SSH Server release ..."
sshpass -p "${P_SSH_PASSWORD:-$GL_SERVER_PASSWORD}" ssh -o StrictHostKeyChecking=no -p "${P_SSH_PORT:-22}" "${P_SSH_USERNAME:-root}"@"${P_SSH_HOSTNAME}" "${P_SSH_COMMAND}"

# Success
push_wechat_message "true"
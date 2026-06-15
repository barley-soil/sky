#!/usr/bin/env bash
# maven3-jdk21
# Usage: maven3-jdk21

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

# Deploy
# P_PACKAGE_BEFORE: Deploy before
# P_PACKAGE_AFTER: Deploy after
docker run --rm \
  -v "$WORKDIR":/code \
  -v /home/repository/"$CI_PROJECT_ID":/root/.m2/repository \
  billbear-cn-shanghai.cr.volces.com/base/maven:3.9-ibm-semeru-21-jammy \
  sh -c "cp -a /code/settings.xml /root/.m2/settings.xml && cd /code ${P_PACKAGE_BEFORE:-} && mvn -U -T 4C clean deploy -Dmaven.test.skip=true ${P_PACKAGE_AFTER:-}"


# Success
push_wechat_message "true"

#!/usr/bin/env bash
# ssr-node24-pure
# Usage: ssr-node24

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


# Download docker auth.json
echo "Download ==> [docker_auth.json]"
mkdir -p docker_config
curl -o docker_config/config.json "https://gitlab.liexiong.net/api/v4/projects/yunzhou%2Fsecret/repository/files/docker%2F$P_DOCKER_AUTH_TYPE.json/raw?ref=main" --header "PRIVATE-TOKEN: ${GL_TOKEN}"


# Deploy
# P_PACKAGE_BEFORE: Deploy before
# P_PACKAGE_AFTER: Deploy after
# P_BUILD_CMD
docker run --rm \
  -v "$WORKDIR":/code \
  -v /home/repository/"$CI_PROJECT_ID":/root/.npm \
  billbear-cn-shanghai.cr.volces.com/base/billbear-node:24-runtime \
  sh -c "cd /code && ${P_PACKAGE_BEFORE:-echo ''} && npm config set registry https://registry.npmmirror.com/ && pnpm config set dangerouslyAllowAllBuilds true && ${P_BUILD_CMD:-npm} install --no-frozen-lockfile && ${P_BUILD_CMD:-npm} run build && ${P_PACKAGE_AFTER:-echo ''}"


echo "Remove .dockerIgnore file .."
rm -rf ./.dockerignore

# Dockerfile
BUILD_TIME=$(date "+%Y_%m_%d_%H_%M_%S")
BUILD_APPLICATION_NAME="$CI_PROJECT_NAME"
BUILD_COMMIT_ID="$CI_COMMIT_SHA"
BUILD_OUTPUT="${P_OUTPUT:-dist}"
cat <<'EOF' | sed "s|__BUILD_TIME__|$BUILD_TIME|g; s|__APPLICATION_NAME__|$BUILD_APPLICATION_NAME|g; s|__COMMIT_ID__|$BUILD_COMMIT_ID|g; s|__OUTPUT__|$BUILD_OUTPUT|g" >Dockerfile
FROM billbear-cn-shanghai.cr.volces.com/base/billbear-node:24-runtime
ENV LANG zh_CN.UTF-8
ENV BUILD_TIME __BUILD_TIME__
ENV APPLICATION_NAME __APPLICATION_NAME__
ENV COMMIT_ID __COMMIT_ID__
ADD ./__OUTPUT__ /app
ADD ./node_modules /code/node_modules
WORKDIR /app
CMD ["npm", "start"]
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
if [ -n "${P_COLONY:-}" ]; then
  echo " "
  echo " "
  echo "Kubernetes prepare release ..."
  for colony in ${P_COLONY//,/ }; do
    # Download Kubeconfig
    P_COLONY_TARGET="P_COLONY_${ENVIRONMENT_NAME}"
    curl -f -s -L -o kubeconfig.yaml "https://gitlab.liexiong.net/api/v4/projects/yunzhou%2Fsecret/repository/files/kubernetes%2F$P_COLONY_TARGET.yaml/raw?ref=main" --header "PRIVATE-TOKEN: ${GL_TOKEN}" ||
      curl -f -L -o kubeconfig.yaml "https://gitlab.liexiong.net/api/v4/projects/yunzhou%2Fsecret/repository/files/kubernetes%2F$P_COLONY.yaml/raw?ref=main" --header "PRIVATE-TOKEN: ${GL_TOKEN}"
    KUBECONFIG="$WORKDIR/kubeconfig.yaml"
    # Namespace
    case "${ENVIRONMENT_NAME^^}" in
    "DEV")
      K8S_NAMESPACE="$P_NAMESPACE_DEV"
      ;;
    "TEST")
      K8S_NAMESPACE="$P_NAMESPACE_TEST"
      ;;
    "PREV")
      K8S_NAMESPACE="$P_NAMESPACE_PREV"
      ;;
    esac
    # First K8s namespace
    if [ -n "$K8S_NAMESPACE" ] && ! kubectl --kubeconfig="$KUBECONFIG" get ns "$K8S_NAMESPACE" &>/dev/null; then
      K8S_NAMESPACE=""
    fi
    # Retry K8s namespace
    if [ -z "$K8S_NAMESPACE" ] && [ -n "${P_NAMESPACE:-}" ]; then
      if kubectl --kubeconfig="$KUBECONFIG" get ns "$P_NAMESPACE" &>/dev/null; then
        K8S_NAMESPACE="$P_NAMESPACE"
      fi
    fi
    if [ -z "$K8S_NAMESPACE" ]; then
      echo -e "\033[0;31m[Error] K8S_NAMESPACE Unable to find or empty, end publishing ..\033[0m"
      exit 1
    fi

    echo "K8s Colony: $P_COLONY"
    echo "K8s Namespace: $K8S_NAMESPACE"
    echo "K8s ServiceName: $P_SERVICE_NAME"

    DEPLOYMENT_IMAGE=$(kubectl --kubeconfig="$KUBECONFIG" get deployment -n "$K8S_NAMESPACE" "$P_SERVICE_NAME" -o=jsonpath='{.spec.template.spec.containers[0].image}')
    if [ "$DEPLOYMENT_IMAGE" = "$P_IMAGE_NAME" ]; then
      # If the names are the same
      echo "K8s Redeploy the application .."
      kubectl --kubeconfig="$KUBECONFIG" rollout restart deployment -n "$K8S_NAMESPACE" "$P_SERVICE_NAME"
    else
      # Change name differently
      echo "K8s Deploy applications .."
      DEPLOYMENT_IMAGE_NAME=$(kubectl --kubeconfig="$KUBECONFIG" -n "$K8S_NAMESPACE" get deployment "$P_SERVICE_NAME" -o jsonpath='{.spec.template.spec.containers[0].name}')
      kubectl --kubeconfig="$KUBECONFIG" -n "$K8S_NAMESPACE" set image deployment/"$P_SERVICE_NAME" "$DEPLOYMENT_IMAGE_NAME"="$P_IMAGE_NAME"
    fi
  done
fi

# Success
push_wechat_message "true"

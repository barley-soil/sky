# Dockerfile 镜像与版本规范

## 1. 镜像国产化规范

- 如果使用国产化镜像仓库，统一使用前缀：`billbear-cn-shanghai.cr.volces.com/base`
- 前缀后面拼接官方镜像路径
- 示例：
  - 官方镜像：`nginx:1.31-alpine3.23`
  - 国产化镜像：`billbear-cn-shanghai.cr.volces.com/base/nginx:1.31-alpine3.23`

## 2. 镜像版本号规范

- Dockerfile 中镜像版本号统一使用 `主版本.次版本`，不体现小版本（补丁版本）
- 示例：`Nginx 1.31.1` 在 Dockerfile 中写为 `1.31`
- 如果小版本需要修复（例如补丁 BUG 或安全修复），直接覆盖同一 `主.次` 标签对应的原始镜像
- 该规范适用于所有程序镜像，**小版本更新默认不引入严重不兼容风险**


## 3.快速构建国内镜像

**环境准备**
- 香港服务器一台 （*CentOS 系列* 操作系统） 
- 默认推送到 `billbear-cn-shanghai.cr.volces.com/base` 为 **火山引擎**
- 镜像需要在 **香港服务器** 默认已经完成 **登录** 操作

**火山云容器镜像**
- 默认推送到火山云镜像服务中心，镜像前缀必须为 `billbear-cn-shanghai.cr.volces.com`
- [火山云容器镜像](https://console.volcengine.com/cr/region:cr+cn-shanghai/instance/billbear/overview)

```bash
# 快速登录

# Docker
docker login --username=上海闪态网络技术有限公司@2100809659 billbear-cn-shanghai.cr.volces.com

# Nerdctl 
nerdctl login --username 上海闪态网络技术有限公司@2100809659 billbear-cn-shanghai.cr.volces.com


# 将海外镜像 → 国内镜像
IMAGE='[Docker Hub 镜像路径]'; TARGET="billbear-cn-shanghai.cr.volces.com/base/$IMAGE"; docker pull "$IMAGE" && docker tag "$IMAGE" "$TARGET" && docker push "$TARGET"
```

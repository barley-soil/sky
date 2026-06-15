# raw-gitlab-nginx

raw-gitlab-nginx 是一个基于 Nginx + NJS 的轻量级代理工具，用于直接输出 GitLab 文件流，无需认证即可访问。

## 核心功能

**文件系统代理**

将 GitLab 仓库文件直接通过流的形式输出，支持直接访问原始内容。

**免 GitLab 认证**

用户无需登录 GitLab 即可获取文件内容。

**使用注意**

确保源仓库的访问权限符合代理策略。

流地址仅做文件输出，不支持 Git 操作。

| 类型  | 地址                                                                                                | 
| --- | ------------------------------------------------------------------------------------------------- | 
| 源地址 | `https://gitlab.liexiong.net/yunzhou/apps/gitlab-plus/raw-gitlab-nginx/-/blob/main/README.md`     | 
| 流地址 | `https://raw-gitlab.liexiong.net/yunzhou/apps/gitlab-plus/raw-gitlab-nginx/-/blob/main/README.md` |


## 构建指南

```bash
# 构建镜像
docker build -t billbear-cn-shanghai.cr.volces.com/base/nginx:raw-gitlab-1.27.1 .

# 推送镜像
docker push billbear-cn-shanghai.cr.volces.com/base/nginx:raw-gitlab-1.27.1

# 运行注入环境变量 GITLAB_TOKEN
# GITLAB_TOKEN Gitlab 后台申请令牌
docker run -d -e GITLAB_TOKEN=[you token] --name raw-gitlab billbear-cn-shanghai.cr.volces.com/base/nginx:raw-gitlab-1.27.1
```

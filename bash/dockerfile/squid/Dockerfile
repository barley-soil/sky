FROM debian:rc-buggy-20251229 AS builder

RUN apt update -y && apt install -y apache2-utils
RUN cd /opt && htpasswd -cb passwd billbear billbear123

RUN cd /opt && cat > squid.conf <<'EOF'
# 端口
http_port 3128

# 缓存目录
cache_dir ufs /var/spool/squid 1000 16 256
coredump_dir /var/spool/squid

# 日志
access_log daemon:/var/log/squid/access.log squid
cache_log /var/log/squid/cache.log
cache_store_log none

# 安全端口和 CONNECT 方法限制
acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 1025-65535  # unregistered ports
acl CONNECT method CONNECT

http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports

# Basic 认证配置
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 20 startup=5 idle=5
auth_param basic realm Squid Proxy
auth_param basic credentialsttl 2 hours

acl authenticated proxy_auth REQUIRED

http_access allow authenticated
http_access deny all
EOF

FROM sameersbn/squid:3.5.27-2

COPY --from=builder /opt/passwd /etc/squid/passwd
COPY --from=builder /opt/squid.conf /etc/squid/squid.conf

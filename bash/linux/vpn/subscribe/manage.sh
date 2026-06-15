#!/bin/sh/env bash
set -e

##########################
# 网络管理器
##########################

DATA_FILE="/home/data.xlsx" # ← 修改成你的实际路径
ROOT_PATH="/opt"
TMP_DIR=$(mktemp -d /tmp/xray_manage.XXXXXX)

trap 'rm -rf "$TMP_DIR"' EXIT

echo "正在将 Excel 转为 CSV..."
# -a 表示所有 sheet, 每个 sheet 生成一个 csv 文件
xlsx2csv -a "$DATA_FILE" "$TMP_DIR"

USERS_CSV="$TMP_DIR/用户.csv"
INBOUNDS_CSV="$TMP_DIR/入站.csv"
OUTBOUNDS_CSV="$TMP_DIR/出站.csv"
LINKS_CSV="$TMP_DIR/链路.csv"
EXTERNALS_CSV="$TMP_DIR/外部链路.csv"

# ====================== 读取数据 ======================

declare -A USER_NICKNAME USER_PORT
while IFS=',' read -r code nickname port _; do
  [[ -z "$code" ]] && continue
  code=${code//\"/}
  code=${code// /}
  nickname=${nickname//\"/}
  nickname=${nickname// /}
  port=${port// /}
  USER_NICKNAME["$code"]="$nickname"
  USER_PORT["$code"]="$port"
done < <(tail -n +2 "$USERS_CSV")

declare -A INBOUND_NAME INBOUND_PORT INBOUND_PASSWORD INBOUND_CIPHER
while IFS=',' read -r code name port password cipher _; do
  [[ -z "$code" ]] && continue
  code=${code//\"/}
  code=${code// /}
  name=${name//\"/}
  port=${port// /}
  password=${password//\"/}
  cipher=${cipher//\"/}
  INBOUND_NAME["$code"]="$name"
  INBOUND_PORT["$code"]="$port"
  INBOUND_PASSWORD["$code"]="$password"
  INBOUND_CIPHER["$code"]="$cipher"
done < <(tail -n +2 "$INBOUNDS_CSV")

declare -A OUTBOUND_HOSTNAME OUTBOUND_PORT OUTBOUND_USERNAME OUTBOUND_PASSWORD
while IFS=',' read -r code name hostname port username password _; do
  [[ -z "$code" ]] && continue
  code=${code//\"/}
  code=${code// /}
  hostname=${hostname//\"/}
  port=${port// /}
  username=${username//\"/}
  password=${password//\"/}
  OUTBOUND_HOSTNAME["$code"]="$hostname"
  OUTBOUND_PORT["$code"]="$port"
  OUTBOUND_USERNAME["$code"]="$username"
  OUTBOUND_PASSWORD["$code"]="$password"
done < <(tail -n +2 "$OUTBOUNDS_CSV")

declare -a LINK_CODES
declare -A LINK_NAME LINK_INBOUND LINK_OUTBOUND LINK_PROXY LINK_USERS
while IFS=',' read -r code name inbound_str outbound proxy users_str _; do
  [[ -z "$code" ]] && continue
  code=${code//\"/}
  code=${code// /}
  name=${name//\"/}
  outbound=${outbound//\"/}
  outbound=${outbound// /}
  proxy=${proxy//\"/}
  LINK_CODES+=("$code")
  LINK_NAME["$code"]="$name"
  LINK_INBOUND["$code"]="${inbound_str//\"/}"
  LINK_OUTBOUND["$code"]="$outbound"
  LINK_PROXY["$code"]="$proxy"
  LINK_USERS["$code"]="${users_str//\"/}"
done < <(tail -n +2 "$LINKS_CSV")

declare -a EXTERNAL_CODES
declare -A EXTERNAL_NAME EXTERNAL_HOSTNAME EXTERNAL_PORT EXTERNAL_PASSWORD EXTERNAL_CIPHER
while IFS=',' read -r code name hostname port password cipher users_str _; do
  [[ -z "$code" ]] && continue
  code=${code//\"/}
  code=${code// /}
  name=${name//\"/}
  hostname=${hostname//\"/}
  port=${port// /}
  password=${password//\"/}
  cipher=${cipher//\"/}
  EXTERNAL_CODES+=("$code")
  EXTERNAL_NAME["$code"]="$name"
  EXTERNAL_HOSTNAME["$code"]="$hostname"
  EXTERNAL_PORT["$code"]="$port"
  EXTERNAL_PASSWORD["$code"]="$password"
  EXTERNAL_CIPHER["$code"]="$cipher"
done < <(tail -n +2 "$EXTERNALS_CSV")

# ====================== Nginx ======================
echo '' >/etc/nginx/conf.d/default.conf
echo "# Nginx config generated on $(date '+%Y-%m-%d %H:%M:%S')" >> /etc/nginx/conf.d/default.conf
echo "" >> /etc/nginx/conf.d/default.conf

for code in "${!USER_PORT[@]}"; do
    port="${USER_PORT[$code]}"
    nickname="${USER_NICKNAME[$code]:-$code}"
    dir="$ROOT_PATH/$port"

    cat >> /etc/nginx/conf.d/default.conf <<EOF

# User: $nickname ($code)
server {
    listen $port;
    server_name _;
    root $dir;

    location / {
        try_files \$uri \$uri/ =404;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF
done

echo "" >> /etc/nginx/conf.d/default.conf

# ====================== 生成订阅 ======================
for user_code in "${!USER_PORT[@]}"; do
  port="${USER_PORT[$user_code]}"
  dir="$ROOT_PATH/$port"
  mkdir -p "$dir"

  # Nginx server block
  cat >>/etc/nginx/conf.d/default.conf <<EOF

server {
    listen $port;
    server_name _;
    root $dir;
    location / {
        try_files \$uri \$uri/ =404;
    }
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

  clash_proxies=()
  ss_links=()

  # 本地链路（Link sheet）
  for link_code in "${LINK_CODES[@]}"; do
    users_str="${LINK_USERS[$link_code]}"
    if [[ ",$users_str," != *",$user_code,"* ]] && [[ "$users_str" != "$user_code" ]]; then
      continue
    fi

    inbound_str="${LINK_INBOUND[$link_code]}"
    IFS=',' read -ra inbounds <<<"$inbound_str"
    for ib_code in "${inbounds[@]}"; do
      ib_code=${ib_code// /}
      [[ -z "$ib_code" ]] && continue

      proxy="${LINK_PROXY[$link_code]}"
      if [[ "$proxy" =~ : ]]; then
        hostname="${proxy%%:*}"
        port="${proxy##*:}"
      else
        hostname="$proxy"
        port="${INBOUND_PORT[$ib_code]}"
      fi

      name="${LINK_NAME[$link_code]}"
      cipher="${INBOUND_CIPHER[$ib_code]}"
      password="${INBOUND_PASSWORD[$ib_code]}"

      clash_proxies+=(" - name: \"$name\"")
      clash_proxies+=("   type: ss")
      clash_proxies+=("   server: $hostname")
      clash_proxies+=("   port: $port")
      clash_proxies+=("   cipher: $cipher")
      clash_proxies+=("   password: \"$password\"")
      clash_proxies+=("   udp: false")

      b64=$(printf '%s:%s@%s:%s' "$cipher" "$password" "$hostname" "$port" | base64 -w 0)
      name_enc=$(printf '%s' "$name" | python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.stdin.read().strip()))" 2>/dev/null || printf '%s' "$name")
      ss_links+=("ss://$b64#$name_enc")
    done
  done

  # 外部链路（External sheet）全部加入
  for ext_code in "${EXTERNAL_CODES[@]}"; do
    name="${EXTERNAL_NAME[$ext_code]}"
    clash_proxies+=(" - name: \"$name\"")
    clash_proxies+=("   type: ss")
    clash_proxies+=("   server: ${EXTERNAL_HOSTNAME[$ext_code]}")
    clash_proxies+=("   port: ${EXTERNAL_PORT[$ext_code]}")
    clash_proxies+=("   cipher: ${EXTERNAL_CIPHER[$ext_code]}")
    clash_proxies+=("   password: \"${EXTERNAL_PASSWORD[$ext_code]}\"")
    clash_proxies+=("   udp: false")

    b64=$(printf '%s:%s@%s:%s' "${EXTERNAL_CIPHER[$ext_code]}" "${EXTERNAL_PASSWORD[$ext_code]}" "${EXTERNAL_HOSTNAME[$ext_code]}" "${EXTERNAL_PORT[$ext_code]}" | base64 -w 0)
    name_enc=$(printf '%s' "$name" | python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.stdin.read().strip()))" 2>/dev/null || printf '%s' "$name")
    ss_links+=("ss://$b64#$name_enc")
  done

  # Clash 文件
  {
    cat <<'HEAD'
port: 7890
socks-port: 7891
redir-port: 7892
allow-lan: false
mode: Rule
log-level: info
proxies:
HEAD
    printf '%s\n' "${clash_proxies[@]}"
    echo "proxy-groups:"
    echo " - name: \"Proxy\""
    echo "   type: select"
    echo "   proxies:"
    echo "     - \"DIRECT\""
    for line in "${clash_proxies[@]}"; do
      if [[ $line =~ ^\ -\ name:\ \"(.*)\"$ ]]; then
        echo "     - \"${BASH_REMATCH[1]}\""
      fi
    done
    cat <<'RULES'
rules:
 - IP-CIDR,127.0.0.0/8,DIRECT
 - IP-CIDR,10.0.0.0/8,DIRECT
 - IP-CIDR,172.16.0.0/12,DIRECT
 - IP-CIDR,192.168.0.0/16,DIRECT
 - IP-CIDR,169.254.0.0/16,DIRECT
 - IP-CIDR,100.64.0.0/10,DIRECT
 - GEOIP,CN,DIRECT
 - MATCH,Proxy
RULES
  } >"$dir/clash"

  # SS 文件
  printf '%s\n' "${ss_links[@]}" >"$dir/ss"
done

# ====================== 生成 Xray config ======================
{
  cat <<'JSON_HEAD'
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
JSON_HEAD

  comma=""
  for code in "${!INBOUND_PORT[@]}"; do
    [ -n "$comma" ] && echo "$comma"
    cat <<INBOUND
    {
      "port": ${INBOUND_PORT[$code]},
      "protocol": "shadowsocks",
      "settings": {
        "method": "${INBOUND_CIPHER[$code]}",
        "password": "${INBOUND_PASSWORD[$code]}",
        "ota": false
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "tag": "$code"
    }
INBOUND
    comma="    ,"
  done

  cat <<'JSON_INBOUNDS_END'
  ],
  "outbounds": [
JSON_INBOUNDS_END

  comma=""
  for code in "${!OUTBOUND_HOSTNAME[@]}"; do
    [ -n "$comma" ] && echo "$comma"
    cat <<OUTBOUND
    {
      "protocol": "socks",
      "settings": {
        "servers": [{
          "address": "${OUTBOUND_HOSTNAME[$code]}",
          "port": ${OUTBOUND_PORT[$code]},
          "users": [{
            "user": "${OUTBOUND_USERNAME[$code]}",
            "pass": "${OUTBOUND_PASSWORD[$code]}"
          }]
        }]
      },
      "tag": "$code"
    }
OUTBOUND
    comma="    ,"
  done

  cat <<'JSON_OUTBOUNDS_END'
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8","10.0.0.0/8","100.64.0.0/10","127.0.0.0/8",
          "169.254.0.0/16","172.16.0.0/12","192.0.0.0/24","192.0.2.0/24",
          "192.88.99.0/24","192.168.0.0/16","198.18.0.0/15","198.51.100.0/24",
          "203.0.113.0/24","::1/128","fc00::/7","fe80::/10"
        ],
        "outboundTag": "blocked"
      },
JSON_OUTBOUNDS_END

  comma=""
  for link_code in "${LINK_CODES[@]}"; do
    inbound_str="${LINK_INBOUND[$link_code]}"
    outbound="${LINK_OUTBOUND[$link_code]}"
    IFS=',' read -ra inbounds <<<"$inbound_str"
    for ib in "${inbounds[@]}"; do
      ib=${ib// /}
      [[ -z "$ib" ]] && continue
      [ -n "$comma" ] && echo "$comma"
      cat <<RULE
      {
        "type": "field",
        "inboundTag": ["$ib"],
        "outboundTag": "$outbound"
      }
RULE
      comma="      ,"
    done
  done

  cat <<'JSON_END'
    ]
  }
}
JSON_END

} >/etc/xray/config.json

echo "所有配置已生成！"
systemctl restart nginx
systemctl restart xray

echo "Nginx 和 Xray 已重启，完成！"

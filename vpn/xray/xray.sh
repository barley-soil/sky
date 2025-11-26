#!/bin/sh/env bash

# 安装 xray
cp -a ./xray /usr/local/bin/xray

# config.json
mkdir -p /etc/xray
mkdir -p /var/log/xray
sudo tee "/etc/xray/config.json" >/dev/null <<'EOF_CONFIG'
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "port": 8388,
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-256-gcm",
        "password": "YOUR_SS_PASSWORD",
        "ota": false
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "tag": "ss-in"
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "127.0.0.0/8",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.88.99.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "inboundTag": ["ss-in"],
        "outboundTag": "direct"
      }
    ]
  }
}
EOF_CONFIG


# systemd 系统安装包
sudo tee "/etc/systemd/system/xray.service" >/dev/null <<'EOF_CONFIG'
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/xray run -c /etc/xray/config.json
Environment=XRAY_LOCATION=/etc/xray
LimitNPROC=500
LimitNOFILE=100000
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF_CONFIG

echo "xray 安装成功 ..."

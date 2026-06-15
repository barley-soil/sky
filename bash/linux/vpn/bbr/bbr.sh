#!/usr/bin/env bash

uname -r

echo "==========================================="
echo "      开始启用 TCP BBR 拥塞控制算法      "
echo "==========================================="

# 检查内核版本是否满足要求 (4.9+)
KERNEL_VERSION=$(uname -r | awk -F. '{print $1*100 + $2}')
if [ "$KERNEL_VERSION" -lt 409 ]; then
    echo "错误：当前内核版本 $(uname -r) 低于 4.9，不支持 BBR。"
    echo "请先升级内核再运行此脚本。"
    exit 1
fi

# 修改系统配置 /etc/sysctl.conf
SYSCTL_CONF="/etc/sysctl.conf"

echo "备份原有 $SYSCTL_CONF 文件..."
cp "$SYSCTL_CONF" "$SYSCTL_CONF.bak.$(date +%F_%H-%M-%S)"

echo "写入 BBR 优化参数到 $SYSCTL_CONF..."

# 清除可能存在的旧配置，然后写入新配置
sudo sed -i '/net.core.default_qdisc/d' "$SYSCTL_CONF"
sudo sed -i '/net.ipv4.tcp_congestion_control/d' "$SYSCTL_CONF"

# 写入 BBR 和 FQ 算法
sudo bash -c "cat >> $SYSCTL_CONF" << EOF_SYSCTL
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF_SYSCTL

# 激活新的配置
echo "正在应用 sysctl 配置..."
sudo sysctl -p

# 验证是否启用成功
echo "验证 BBR 是否成功启用..."

# 检查拥塞控制算法是否为 bbr
TCP_CC=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')

# 检查 FQ 算法是否启用
TCP_QDISC=$(sysctl net.core.default_qdisc | awk '{print $3}')

if [ "$TCP_CC" == "bbr" ] && [ "$TCP_QDISC" == "fq" ]; then
    echo "TCP BBR 拥塞控制算法已成功启用！"
    echo "当前拥塞控制算法: $TCP_CC"
    echo "当前队列调度算法: $TCP_QDISC"
else
    echo "验证失败！拥塞控制算法当前为: $TCP_CC"
    echo "请检查脚本输出或尝试重启服务器。"
fi

echo "==========================================="

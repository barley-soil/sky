#!/usr/bin/env bash
# Usage: docker-install
set -euo pipefail



# DNF Core
sudo dnf -y install dnf-plugins-core

# Docker Manager Source
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 清华大学
sed -i 's+https://download.docker.com+https://mirrors.tuna.tsinghua.edu.cn/docker-ce+' /etc/yum.repos.d/docker-ce.repo


# Docker Install
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker Start
sudo systemctl enable --now docker && sudo systemctl start docker

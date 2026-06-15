#!/usr/bin/env bash
# sysreport — Disk Cleanup Script
# Usage: docker_cleanup


set -euo pipefail
docker system prune -f
docker rmi $(docker images -q) -f
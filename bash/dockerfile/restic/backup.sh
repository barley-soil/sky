#!/usr/bin/env bash
set -euo pipefail

# 配置
RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-/data/target}"
SOURCE="${SOURCE:-/data/source}"
LOG_FILE="${LOG_FILE:-/var/log/backup.log}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 校验密码
if [[ -z "${RESTIC_PASSWORD:-}" && -z "${RESTIC_PASSWORD_FILE:-}" ]]; then
  log "RESTIC_PASSWORD 或 RESTIC_PASSWORD_FILE 未设置"
  exit 1
fi

# 初始化仓库（如果不存在）
if ! restic -r "$RESTIC_REPOSITORY" snapshots &>/dev/null; then
  log "初始化仓库"
  restic -r "$RESTIC_REPOSITORY" init
fi

# 执行备份
log "开始备份: $SOURCE"
restic -r "$RESTIC_REPOSITORY" backup "$SOURCE"

# 清理策略
log "执行清理"
restic -r "$RESTIC_REPOSITORY" forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --prune

# 简单检查
log "检查仓库"
restic -r "$RESTIC_REPOSITORY" check --read-data-subset=5%

log "完成"

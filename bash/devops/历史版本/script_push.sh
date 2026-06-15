#!/usr/bin/env bash
# script_push — Push data to the `data center`
# Usage: script_push

set -euo pipefail

# Environment
ENVIRONMENT_NAME="${CI_ENVIRONMENT_NAME:-}"
if [ -z "$ENVIRONMENT_NAME" ]; then
  echo "Not CI_ENVIRONMENT_NAME" >&2
  exit 1
fi

# Gateway
URL_ENVIRONMENT_KEY="P_${ENVIRONMENT_NAME^^}_PUSH_HOST"
URL="${!URL_ENVIRONMENT_KEY:-${P_PUSH_HOST:-}}"
URL_PROTOCOL="${URL%%://*}"
URL_REST="${URL#*://}"
URL_HOST="${URL_REST%%/*}"
GATEWAY="${URL_PROTOCOL}://${URL_HOST}"
if [[ ! "$GATEWAY" =~ ^https://[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
  echo "Not P_PUSH_HOST" >&2
  exit 1
fi

# Script replace
REPLACE_ENVIRONMENT_KEY="P_${ENVIRONMENT_NAME^^}_REPLACE"
REPLACE_RULES="${!REPLACE_ENVIRONMENT_KEY:-${P_REPLACE:-}}"
if [ -n "$REPLACE_RULES" ]; then
  echo "Scanning workspace.."
  SUFFIXES=("yaml" "js" "sql" "xml" "json")
  FIND_SCRIPT=()
  for suffix in "${SUFFIXES[@]}"; do
    if [ ${#FIND_SCRIPT[@]} -gt 0 ]; then
      FIND_SCRIPT+=(-o)
    fi
    FIND_SCRIPT+=(-name "*.${suffix}")
  done
  find . -type f \( "${FIND_SCRIPT[@]}" \) -exec gawk -i inplace -v rules="$REPLACE_RULES" '
    # 替换函数
    # str, from, to 入参
    # pos, out, cnt 局部变量
    function replace_all(str, from, to,    pos, out, cnt) {
      if (from == "") return str

      out = ""
      cnt = 0

      # 查找 from 在字符串中的位置
      while ((pos = index(str, from)) > 0) {
        out = out substr(str, 1, pos - 1) to
        str = substr(str, pos + length(from))
        cnt++
      }

      # 替换次数累计到 total
      total += cnt
      return out str
    }

    # 文件处理开始
    BEGIN {
      # 先把 rules 按 ; 拆开
      pair_count = split(rules, pairs, /;/)
      rule_count = 0

      for (i = 1; i <= pair_count; i++) {
        if (pairs[i] == "") continue

        # 找到第一个 :
        # 左边是旧值，右边是新值
        sep = index(pairs[i], ":")
        if (sep == 0) continue

        old_val = substr(pairs[i], 1, sep - 1)
        new_val = substr(pairs[i], sep + 1)

        if (old_val == "") continue

        # 规则去重复
        key = old_val SUBSEP new_val
        if (seen[key]++) continue

        rule_count++
        old[rule_count] = old_val
        new[rule_count] = new_val
      }
    }

    # AWK 默认 FNR 文件行游标
    FNR == 1 {
      total = 0
    }

    {
      line = $0

      # 当前行依次套用所有替换规则
      for (i = 1; i <= rule_count; i++) {
        line = replace_all(line, old[i], new[i])
      }

      print line
    }

    # 文件处理完后
    ENDFILE {
      if (total > 0) {
        printf "%s <== 已替换 %d 处\n", FILENAME, total > "/dev/stderr"
      }
    }
  ' {} +
fi

echo "======= Archiving in progress ======="

# Ignore Files
IGNORE_FILES=(".git/*" "node_modules/*" "*.log" "*.tmp", ".*")

# temp Zip file
ZIP_FILE="/tmp/$(basename "$PWD")-${RANDOM}${RANDOM}.zip"
# cleanup Zip file
trap 'rm -f "$ZIP_FILE"' EXIT

# Zip build
zip -r "$ZIP_FILE" . -x "${IGNORE_FILES[@]}"
echo "Compression successful: $ZIP_FILE"


echo "======= Syncing to gateway ======="

# Push data(.zip) to the server
echo "Local File (data.zip) ==> ${GATEWAY}/api/report/system/sync"
response=$(curl -s -X POST "${GATEWAY}/api/report/system/sync" \
  -H 'Content-Type: application/zip' \
  --data-binary @"$ZIP_FILE")
echo "$response"

# Resposne Status
if ! echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
  echo "推送失败"
  exit 1
fi

echo "推送成功！"

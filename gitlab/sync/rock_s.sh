#!/usr/bin/env bash

# 源仓库地址|目标目录名
PROJECTS=(
  "git@gitlab.liexiong.net:common-base/rock/billbear-common-base.git|git@github.com:barley-rock/barley-common-base.git"
  "git@gitlab.liexiong.net:common-base/rock/billbear-common-rock.git|git@github.com:barley-rock/barley-common-rock.git"
  "git@gitlab.liexiong.net:common-base/rock/billbear-common-flink.git|git@github.com:barley-rock/barley-common-flink.git"
  "git@gitlab.liexiong.net:common-base/rock/beer-assembly.git|git@github.com:barley-rock/beer-assembly.git"
  "git@gitlab.liexiong.net:common-base/rock/beer-assembly-biz.git|git@github.com:barley-rock/beer-assembly-biz.git"
  "git@gitlab.liexiong.net:common-base/rock/beer-assembly-schema.git|git@github.com:barley-rock/beer-assembly-schema.git"
)

for item in "${PROJECTS[@]}"; do
  # 用 | 分割
  IFS='|' read -r source_repo target_repo <<<"$item"
  echo "============================================"
  echo "正在处理：$source_repo → $target_repo"
  echo "============================================"

  git clone "$source_repo" "project"
  if ! cd "project"; then
    echo "克隆或进入目录失败，跳过该项目"
    continue
  fi

  echo "正在替换 billbear → barley ..."
  git ls-files '*.txt' '*.md' '*.java' '*.xml' '*.properties' '*.yaml' '*.yml' | xargs sed -i 's/billbear/barley/g'

  echo "正在替换版本号 2.3.0-SNAPSHOT → 4.2.0-SNAPSHOT ..."
  git ls-files '*.md' '*.xml' '*.properties' '*.yaml' '*.yml' | xargs sed -i 's/2\.3\.0-SNAPSHOT/4.2.0-SNAPSHOT/g'

  echo "正在更新目录结构 ..."
  find . -depth -type d -name '*billbear*' -execdir bash -c '
      current_dir="${1##*/}"
      # 取父路径
      parent="${1%/*}"
      new_dir="$(echo "$current_dir" | sed "s/billbear/barley/g")"
      if [ "$current_dir" != "$new_dir" ]; then
          echo "重命名: $1 → $parent/$new_dir"
          mv "$current_dir" "$new_dir"
      fi
    ' _ {} \;

  echo "当前远程地址:"
  git remote -v

  echo "切换推送地址为：$target_repo"
  git remote set-url --push origin "$target_repo"

  git add .
  git commit -m "Convert code upgrade" || echo "Not commit files"

  echo "正在强制推送到新仓库..."
  git push --force origin "$(git branch --show-current 2>/dev/null || echo master)":main

  # 已完成任务
  echo "已完成源: $source_repo → $target_repo"

  # 退出项目目录, 准备处理下一个
  cd ..
  rm -rf ./project
  echo ""
done

#  echo "预览包含 billbear 的文件: "
#  git grep -l 'billbear' -- '*.txt' '*.java' '*.xml' '*.properties' '*.yaml' '*.yml' '*.md' || echo "未找到 billbear"

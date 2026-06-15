#!/usr/bin/env bash

# 源仓库地址|目标目录名
PROJECTS=(
  "git@gitlab.liexiong.net:common-base/f4/billbear-authcenter.git|git@github.com:barley-soil/barley-authcenter.git"
  "git@gitlab.liexiong.net:common-base/f4/billbear-authcenter-thirdparty.git|git@github.com:barley-soil/barley-authcenter-thirdparty.git"
  "git@gitlab.liexiong.net:common-base/f4/billbear-authcenter-web.git|git@github.com:barley-soil/barley-authcenter-web.git"
  "git@gitlab.liexiong.net:common-base/f4/billbear-common-cashier.git|git@github.com:barley-soil/barley-common-cashier.git"
  "git@gitlab.liexiong.net:common-base/f4/billbear-common-data-panel.git|git@github.com:barley-soil/barley-common-data-panel.git"
  "git@gitlab.liexiong.net:common-base/f4/billbear-common-data-panel-web.git|git@github.com:barley-soil/barley-common-data-panel-web.git"
  "git@gitlab.liexiong.net:common-base/f4/billbear-common-micro-web.git|git@github.com:barley-soil/barley-common-micro-web.git"
  "git@gitlab.liexiong.net:common-base/f4/billbear-filecenter.git|git@github.com:barley-soil/barley-filecenter.git"
  "git@gitlab.liexiong.net:common-base/f4/billbear-usercenter.git|git@github.com:barley-soil/barley-usercenter.git"
  "git@gitlab.liexiong.net:common-base/f4/billbear-usercenter-web.git|git@github.com:barley-soil/barley-usercenter-web.git"
  "git@gitlab.liexiong.net:common-base/f4/billbear-web-gateway.git|git@github.com:barley-soil/barley-web-gateway.git"
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
  git ls-files '*.txt' '*.md' '*.java' '*.xml' '*.properties' '*.yaml' '*.yml' '*.factories' '*.Processor' | xargs sed -i 's/billbear/barley/g'

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

  rm -f .git/index.lock
  git checkout --orphan new-main
  git add -A
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

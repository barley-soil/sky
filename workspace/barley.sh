#!/bin/sh/env bash

# 默认已安装 git

# Rock
mkdir -p ./xxscloud/barley-common-rock
cd ./xxscloud/barley-common-rock || {
  echo "Error: Cannot cd to ./xxscloud/barley-common-service"
  exit 1
}

git clone git@github.com:barley-rock/barley-common-rock.git
git clone git@github.com:barley-rock/barley-common-base.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

# Flink
cd ./xxscloud || {
  echo "Error: Cannot cd to ./xxscloud/barley-common-service"
  exit 1
}

git clone git@github.com:barley-rock/barley-common-flink.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

# F4
mkdir -p ./xxscloud/barley-common-service
cd ./xxscloud/barley-common-service || {
  echo "Error: Cannot cd to ./xxscloud/barley-common-service"
  exit 1
}

git clone git@github.com:barley-soil/barley-authcenter.git
git clone git@github.com:barley-soil/barley-common-cashier.git
git clone git@github.com:barley-soil/barley-common-data-panel.git
git clone git@github.com:barley-soil/barley-filecenter.git
git clone git@github.com:barley-soil/barley-usercenter.git
git clone git@github.com:barley-soil/barley-web-gateway.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

#!/bin/sh/env bash

# 默认已安装 git


mkdir -p ./billbear/business-trip
cd ./xxscloud/barley-common-rock || {
  echo "Error: Cannot cd to ./billbear/business-trip"
  exit 1
}

git clone git@gitlab.liexiong.net:coral-interests/business-trip/coral-business-trip-biz.git
git clone git@gitlab.liexiong.net:coral-interests/business-trip/coral-business-trip-datatask.git
git clone git@gitlab.liexiong.net:coral-interests/business-trip/coral-business-trip-script.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

#!/bin/sh/env bash

mkdir -p ./xxscloud/barley-tiktok-ios
cd ./xxscloud/barley-tiktok-ios || {
  echo "Error: Cannot cd to ./xxscloud/barley-tiktok-ios"
  exit 1
}

git clone git@github.com:barley-worker/barley-tiktok-ios.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}
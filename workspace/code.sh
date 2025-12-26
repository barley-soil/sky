#!/bin/sh/env bash

# 默认已安装 git

# Rock
mkdir -p ./billbear/billbear-common-rock
cd ./billbear/billbear-common-rock || {
  echo "Error: Cannot cd to ./xxscloud/barley-common-service"
  exit 1
}

git clone git@gitlab.liexiong.net:common-base/rock/billbear-common-rock.git
git clone git@gitlab.liexiong.net:common-base/rock/billbear-common-base.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

# Flink
cd ./billbear || {
  echo "Error: Cannot cd to ./billbear"
  exit 1
}

git clone git@gitlab.liexiong.net:common-base/rock/billbear-common-flink.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}


# F4
mkdir -p ./billbear/billbear-common-service
cd ./billbear/billbear-common-service || {
  echo "Error: Cannot cd to ./billbear/billbear-common-service"
  exit 1
}

git clone git@gitlab.liexiong.net:common-base/f4/billbear-authcenter.git
git clone git@gitlab.liexiong.net:common-base/f4/billbear-common-cashier.git
git clone git@gitlab.liexiong.net:common-base/f4/billbear-common-data-panel.git
git clone git@gitlab.liexiong.net:common-base/f4/billbear-filecenter.git
git clone git@gitlab.liexiong.net:common-base/f4/billbear-usercenter.git
git clone git@gitlab.liexiong.net:common-base/f4/billbear-web-gateway.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

mkdir -p ./billbear/billbear-common-front
cd ./billbear/billbear-common-front || {
  echo "Error: Cannot cd to ./billbear/billbear-common-service"
  exit 1
}
git clone git@gitlab.liexiong.net:common-base/f4/billbear-authcenter-web.git
git clone git@gitlab.liexiong.net:common-base/f4/billbear-common-data-panel-web.git
git clone git@gitlab.liexiong.net:common-base/f4/billbear-common-micro-web.git
git clone git@gitlab.liexiong.net:common-base/f4/billbear-usercenter-web.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

# 珊瑚权益
mkdir -p ./billbear/billbear-coral-interests
cd ./billbear/billbear-coral-interests || {
  echo "Error: Cannot cd to ./billbear/billbear-coral-interests"
  exit 1
}

git clone git@gitlab.liexiong.net:coral-interests/coral-interests-biz.git
git clone git@gitlab.liexiong.net:coral-interests/coral-interests-ticket.git
git clone git@gitlab.liexiong.net:coral-interests/coral-interests-datatask.git
git clone git@gitlab.liexiong.net:coral-interests/coral-interests-script.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

mkdir -p ./billbear/billbear-coral-front
cd ./billbear/billbear-coral-front || {
  echo "Error: Cannot cd to ./billbear/billbear-coral-front"
  exit 1
}

git clone git@gitlab.liexiong.net:coral-interests/coral-admin-customer-web.git
git clone git@gitlab.liexiong.net:coral-interests/coral-interests-hotel-overseas-web.git
git clone git@gitlab.liexiong.net:coral-interests/coral-jd-minapp-hotel.git
git clone git@gitlab.liexiong.net:coral-interests/coral-minapp-hotel.git
git clone git@gitlab.liexiong.net:coral-interests/coral-mirroria-h5-web.git
git clone git@gitlab.liexiong.net:coral-interests/coral-mirroria-plane-ticket-h5-web.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

# 珊瑚SDP
mkdir -p ./billbear/billbear-coral-sdp
cd ./billbear/billbear-coral-sdp || {
  echo "Error: Cannot cd to ./billbear/billbear-coral-sdp"
  exit 1
}
git clone git@gitlab.liexiong.net:coral-interests/coral-sdp-hotel.git
git clone git@gitlab.liexiong.net:coral-interests/coral-sdp-hotel-script.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

mkdir -p ./billbear/billbear-coral-sdp-front
cd ./billbear/billbear-coral-sdp-front || {
  echo "Error: Cannot cd to ./billbear/billbear-coral-sdp-front"
  exit 1
}

git clone git@gitlab.liexiong.net:coral-interests/coral-sdp-hotel-admin-web.git
git clone git@gitlab.liexiong.net:coral-interests/coral-sdp-hotel-merchant-web.git
git clone git@gitlab.liexiong.net:coral-interests/coral-sdp-hotel-miniapp.git
git clone git@gitlab.liexiong.net:coral-interests/coral-sdp-hotel-mirroria-h5-web.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

# 珊瑚 商旅
mkdir -p ./billbear/billbear-coral-business-trip
cd ./billbear/billbear-coral-business-trip || {
  echo "Error: Cannot cd to ./billbear/billbear-coral-business-trip"
  exit 1
}
git clone git@gitlab.liexiong.net:coral-interests/business-trip/coral-business-trip-biz.git
git clone git@gitlab.liexiong.net:coral-interests/business-trip/coral-business-trip-datatask.git
git clone git@gitlab.liexiong.net:coral-interests/business-trip/coral-business-trip-script.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

mkdir -p ./billbear/billbear-coral-business-trip-front
cd ./billbear/billbear-coral-business-trip-front || {
  echo "Error: Cannot cd to ./billbear/billbear-coral-business-trip-front"
  exit 1
}

git clone git@gitlab.liexiong.net:coral-interests/business-trip/coral-business-trip-admin-web.git
git clone git@gitlab.liexiong.net:coral-interests/business-trip/coral-business-trip-customer-web.git

cd - || {
  echo "Error: Cannot cd -"
  exit 1
}

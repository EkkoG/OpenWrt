#!/bin/bash

echo "src/gz simonsmh https://github.com/simonsmh/openwrt-dist/raw/packages/x86/64" >> ./repositories.conf


# https://github.com/Dreamacro/clash/releases/tag/premium
CLASH_TUN_RELEASE_DATE=2021.03.10
# https://github.com/comzyh/clash/releases
CLASH_GAME_RELEASE_DATE=20210310
# https://github.com/Dreamacro/clash/releases
CLASH_VERSION=1.4.2

work_dir=$(pwd)

# Add third-party package

cd $work_dir

mkdir openclash_tmp
cd openclash_tmp

echo "下载 clash..."
#/etc/openclash/core/clash
wget https://github.com/Dreamacro/clash/releases/download/v${CLASH_VERSION}/clash-linux-amd64-v${CLASH_VERSION}.gz
mkdir clash_tmp
gunzip -c clash-linux-amd64-v${CLASH_VERSION}.gz > ./clash_tmp/clash
cd ./clash_tmp

if [ ! -f "clash" ]; then
    ls | grep clash | xargs -I {} mv {} clash
fi
chmod +x clash
cp ./* "$work_dir/files/etc/openclash/core/"
cd ..
rm -rf clash_tmp
rm clash-linux-amd64-v${CLASH_VERSION}.gz

echo "下载 clash_tun..."
sudo -E apt-get -qq install gzip
# /etc/openclash/core/clash_tun
wget -q https://github.com/Dreamacro/clash/releases/download/premium/clash-linux-amd64-${CLASH_TUN_RELEASE_DATE}.gz
mkdir clash_tmp
gunzip -c clash-linux-amd64-${CLASH_TUN_RELEASE_DATE}.gz > ./clash_tmp/clash_tun
cd ./clash_tmp
if [ ! -f "clash_tun" ]; then
    ls | grep clash | xargs -I {} mv {} clash_tun
fi
chmod +x clash_tun
cp ./* "$work_dir/files/etc/openclash/core/"
cd ..
rm -rf clash_tmp
rm clash-linux-amd64-${CLASH_TUN_RELEASE_DATE}.gz

echo "下载 clash_game"
# /etc/openclash/core/clash_game
wget -q https://github.com/comzyh/clash/releases/download/${CLASH_GAME_RELEASE_DATE}/clash-linux-amd64-${CLASH_GAME_RELEASE_DATE}.gz 
mkdir clash_tmp
gunzip -c clash-linux-amd64-${CLASH_GAME_RELEASE_DATE}.gz  > ./clash_tmp/clash_game
cd ./clash_tmp
if [ ! -f "clash_game" ]; then
    ls | grep clash | xargs -I {} mv {} clash_game
fi
chmod +x clash_game
cp ./* "$work_dir/files/etc/openclash/core/"
cd ..
rm -rf clash_tmp
rm clash-linux-amd64-${CLASH_GAME_RELEASE_DATE}.gz

echo "查看下载结果"
ls "$work_dir/files/etc/openclash/core/"

echo "清理文件"
cd ..
rm -rf openclash_tmp

cat system-custom.tpl  | sed "s/CUSTOM_PPPOE_USERNAME/$CUSTOM_PPPOE_USERNAME/g" | sed "s/CUSTOM_PPPOE_PASSWORD/$CUSTOM_PPPOE_PASSWORD/g" | sed "s/CUSTOM_LAN_IP/$CUSTOM_LAN_IP/g" | sed "s~CUSTOM_CLASH_CONFIG_URL~$CUSTOM_CLASH_CONFIG_URL~g" >  files/etc/uci-defaults/system-custom
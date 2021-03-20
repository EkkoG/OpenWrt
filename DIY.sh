#!/bin/bash

echo "src/gz simonsmh https://github.com/simonsmh/openwrt-dist/raw/packages/x86/64" >> ./repositories.conf


# https://github.com/Dreamacro/clash/releases/tag/premium
CLASH_TUN_RELEASE_DATE=2021.03.10
# https://github.com/comzyh/clash/releases
CLASH_GAME_RELEASE_DATE=20210310
# https://github.com/Dreamacro/clash/releases
CLASH_VERSION=1.4.2

ARCH=amd64

work_dir=$(pwd)

# Add third-party package


cd $work_dir

sudo -E apt-get -qq install gzip

cd files/etc/openclash/core/

function download() {
    local url=$1
    local binaryname=$2
    wget $url
    
    local filename="${url##*/}"
    gunzip -c $filename > $binaryname
    chmod +x $binaryname
    rm $filename
}

download https://github.com/Dreamacro/clash/releases/download/v${CLASH_VERSION}/clash-linux-${ARCH}-v${CLASH_VERSION}.gz clash
download https://github.com/Dreamacro/clash/releases/download/premium/clash-linux-${ARCH}-${CLASH_TUN_RELEASE_DATE}.gz clash_tun
download https://github.com/comzyh/clash/releases/download/${CLASH_GAME_RELEASE_DATE}/clash-linux-${ARCH}-${CLASH_GAME_RELEASE_DATE}.gz clash_game


cd $work_dir

echo "查看下载结果"
ls "$work_dir/files/etc/openclash/core/"

cat system-custom.tpl  | sed "s/CUSTOM_PPPOE_USERNAME/$CUSTOM_PPPOE_USERNAME/g" | sed "s/CUSTOM_PPPOE_PASSWORD/$CUSTOM_PPPOE_PASSWORD/g" | sed "s/CUSTOM_LAN_IP/$CUSTOM_LAN_IP/g" | sed "s~CUSTOM_CLASH_CONFIG_URL~$CUSTOM_CLASH_CONFIG_URL~g" >  files/etc/uci-defaults/system-custom
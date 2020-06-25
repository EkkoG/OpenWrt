#!/bin/bash
#=================================================
# https://github.com/lujimmy/openwrt-imagebuilder 
# Description: DIY script
# Author: lujimmy
# Version:1.0
#=================================================
# Modify default Lan IP
# sed -i 's/192.168.1.1/192.168.0.128/g' package/base-files/files/bin/config_generate
# Modify image size for OFFICAL OpenWrt source code
# sed -i '567c $(Device/tplink-8mlzma)' target/linux/ar71xx/image/tiny-tp-link.mk
# sed -i '238c CONFIG_ATH79_MACH_TL_WR841N_V9=y' target/linux/ar71xx/config-4.14

work_dir=$(pwd)

# Add third-party package
if [ ! -d "files" ]; then
    mkdir files
fi

cd packages
wget https://github.com/vernesong/OpenClash/releases/download/v0.39.2-beta/luci-app-openclash_0.39.2-beta_all.ipk

cd $work_dir

mkdir openclash_tmp
cd openclash_tmp
#/etc/openclash/core/clash
wget https://github.com/vernesong/OpenClash/releases/download/v0.39.2-beta/clash-linux-amd64.tar.gz
mkdir clash_tmp
tar -xzvf clash-linux-amd64.tar.gz -C ./clash_tmp
cd ./clash_tmp
ls | grep clash | xargs -I {} mv {} clash
chmod +x clash
cp ./* "$work_dir/etc/openclash/core/"
cd ..
rm -rf clash_tmp
rm clash-linux-amd64.tar.gz 

# /etc/openclash/core/clash_tun
wget https://github.com/vernesong/OpenClash/releases/download/TUN-Premium/clash-linux-amd64-2020.06.15.gbf68156.gz
mkdir clash_tmp
tar -xzvf clash-linux-amd64-2020.06.15.gbf68156.gz -C ./clash_tmp
cd ./clash_tmp
ls | grep clash | xargs -I {} mv {} clash_tun
chmod +x clash
cp ./* "$work_dir/etc/openclash/core/"
cd ..
rm -rf clash_tmp
rm clash-linux-amd64-2020.06.15.gbf68156.gz

# /etc/openclash/core/clash_game
wget https://github.com/vernesong/OpenClash/releases/download/TUN/clash-linux-amd64.tar.gz 
mkdir clash_tmp
tar -xzvf clash-linux-amd64.tar.gz -C ./clash_tmp
cd ./clash_tmp
ls | grep clash | xargs -I {} mv {} clash_game
chmod +x clash
cp ./* "$work_dir/etc/openclash/core/"
cd ..
rm -rf clash_tmp
rm clash-linux-amd64.tar.gz 

ls "$work_dir/etc/openclash/core/"

cd ..
rm -rf openclash_tmp
#!/bin/bash -e

cp diy_files/diy.sh .
./diy.sh

# base packages
all_packages="luci luci-compat -dnsmasq dnsmasq-full luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn"
if [ "$TARGET" != "ar71xx_nand" ]; then
    all_packages="$all_packages \
    wget curl vim-full \
    overture \
    clash-for-openclash \
    luci-app-openclash \
    luci-app-autoreboot \
    luci-i18n-autoreboot-zh-cn \
    luci-app-dnsfilter \
    "
else
    all_packages="$all_packages \
    luci-app-passwall \
    xray-core \
    xray-geodata \
    "
fi

all_packages="$all_packages luci-theme-argon"

make image PACKAGES="$all_packages" FILES="files"
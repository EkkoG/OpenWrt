#!/bin/bash -e

cp diy_files/diy.sh .
./diy.sh

# base packages
all_packages="luci luci-compat -dnsmasq dnsmasq-full luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn"
if [ "$TARGET" != "ar71xx_nand" ]; then
    all_packages="$all_packages \
    wget curl vim-full \
    luci-app-clash \
    overture \
    clash \
    luci-app-jd-dailybonus node \
    luci-app-dnsfilter \
    luci-app-zerotier \
    luci-app-autoreboot \
    luci-app-passwall \
    luci-app-wrtbwmon \
    luci-app-ssr-plus \
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
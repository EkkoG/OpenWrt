#!/bin/bash

cp diy_files/DIY.sh .
./DIY.sh

# base packages
all_packages="luci luci-compat -dnsmasq wget dnsmasq-full curl ipset ip-full iptables-mod-tproxy iptables-mod-extra kmod-tun ip6tables-mod-nat vim-full luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn"
# luci-app-clash
all_packages="$all_packages luci-app-clash"
# luci-app-passwall
all_packages="$all_packages luci-app-passwall"
if [ "$OPENWRT_VERSION" = "21.02" ]; then
    all_packages="$all_packages -libustream-openssl"
fi
# overture
all_packages="$all_packages overture"
# luci-app-jd-dailybonus
if [ "$TARGET" != "ar71xx_nand" ]; then
all_packages="$all_packages luci-app-jd-dailybonus"
fi

all_packages="$all_packages luci-theme-argon"

make image PACKAGES="$all_packages" FILES="files"
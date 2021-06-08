#!/bin/bash

cp diy_files/DIY.sh .
./DIY.sh

# base packages
all_packages="luci luci-compat -dnsmasq dnsmasq-full ip6tables-mod-nat luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn"
if [ "$TARGET" != "ar71xx_nand" ]; then
    all_packages="$all_packages wget curl vim-full "

    # luci-app-clash
    all_packages="$all_packages luci-app-clash"

    # overture
    all_packages="$all_packages overture"

    # luci-app-jd-dailybonus
    all_packages="$all_packages luci-app-jd-dailybonus"
fi

# luci-app-passwall
all_packages="$all_packages luci-app-passwall"
if [ "$OPENWRT_VERSION" = "21.02" ]; then
    all_packages="$all_packages -libustream-openssl"
fi

all_packages="$all_packages luci-theme-argon"

make image PACKAGES="$all_packages" FILES="files"
#!/bin/bash -e

cp diy/diy.sh .
./diy.sh

# base packages
all_packages="luci luci-compat -dnsmasq dnsmasq-full luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn"

all_packages="$all_packages \
wget curl vim-full \
luci-app-openclash \
"

all_packages="$all_packages luci-theme-argon"

if [ -z "$PROFILE" ]; then
    make image PACKAGES="$all_packages" FILES="files"
else
    make PROFILE="$PROFILE" image PACKAGES="$all_packages" FILES="files"
fi
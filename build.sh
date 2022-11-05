#!/bin/bash -e

cp diy/diy.sh .
./diy.sh

# base packages
all_packages="luci luci-compat -dnsmasq dnsmasq-full luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn"

all_packages="$all_packages \
wget curl vim-full \
overture \
luci-app-openclash \
"

all_packages="$all_packages luci-theme-argon"

make PROFILE="friendlyarm_nanopi-r2s" image PACKAGES="$all_packages" FILES="files"
#!/bin/bash

./DIY.sh

base_package="luci luci-compat -dnsmasq wget bash dnsmasq-full curl ipset ip-full iptables-mod-tproxy iptables-mod-extra kmod-tun ip6tables-mod-nat vim-full luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn"

clash_package="luci-base wget iptables coreutils-base64 coreutils coreutils-nohup bash ipset libustream-openssl curl jsonfilter ca-certificates libcap libcap-bin iptables-mod-tproxy kmod-tun luci-app-clash"

all_packages="$base_package $clash_package"

make image PACKAGES="$all_packages" FILES="files"
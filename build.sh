#!/bin/bash

./DIY.sh

make image PACKAGES="luci -dnsmasq coreutils-nohup bash dnsmasq-full curl jsonfilter ca-certificates ipset ip-full iptables-mod-tproxy iptables-mod-extra libcap ruby ruby-yaml kmod-tun ip6tables-mod-nat luci-compat vim-full luci-app-openclash luci-app-smartdns luci-i18n-smartdns-zh-cn luci-app-chinadns libcap libcap-bin luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn" FILES="files"
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
# Add third-party package
# git clone https://github.com/P3TERX/xxx package/xxx
# ./scripts/feeds update -a
# ./scripts/feeds install -a
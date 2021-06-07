#!/bin/bash

cp /Users/ciel/Documents/workspace/clash/bin/clash-darwin-amd64 /Users/ciel/Documents/workspace/openwrt-imagebuilder-actions/files/etc/clash/clash
if [ "$1" = 'amd64_19' ]; then
    docker-compose up imagebuilder_x86_64_19_07 
elif [ "$1" = 'amd64_21' ]; then
    docker-compose up imagebuilder_x86_64_21_02 
elif [ "$1" = 'rockchip_21' ]; then
    docker-compose up imagebuilder_rockchip_21_02 
elif [ "$1" = 'ar71xx_nand' ]; then
    cp /Users/ciel/Documents/workspace/clash/bin/clash-linux-mips-softfloat /Users/ciel/Documents/workspace/openwrt-imagebuilder-actions/files/etc/clash/clash
    docker-compose up imagebuilder_ar71xx_nand
fi
docker-compose rm -f
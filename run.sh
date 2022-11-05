#!/bin/bash

if [ "$1" = 'amd64_22' ]; then
    docker-compose up imagebuilder_x86_64_22
elif [ "$1" = 'amd64_21' ]; then
    docker-compose up imagebuilder_x86_64_21
elif [ "$1" = 'rockchip_21' ]; then
    docker-compose up imagebuilder_rockchip_21
elif [ "$1" = 'immortalwrt_rockchip_21' ]; then
    docker-compose up immortalwrt_imagebuilder_rockchip_21
elif [ "$1" = 'rockchip_22' ]; then
    docker-compose up imagebuilder_rockchip_22
fi
docker-compose rm -f 
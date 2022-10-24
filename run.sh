#!/bin/bash

if [ "$1" = 'amd64_22' ]; then
    docker-compose up imagebuilder_x86_64_22_03
elif [ "$1" = 'amd64_21' ]; then
    docker-compose up imagebuilder_x86_64_21_02
elif [ "$1" = 'rockchip_21' ]; then
    docker-compose up imagebuilder_rockchip_21_02
elif [ "$1" = 'rockchip_22' ]; then
    docker-compose up imagebuilder_rockchip_22_03
fi
docker-compose rm -f
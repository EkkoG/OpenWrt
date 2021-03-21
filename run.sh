#!/bin/bash

if [ "$1" = 'amd64_19' ]; then
    docker-compose up imagebuilder_x86_64_19_07 &&  docker-compose rm -f
elif [ "$1" = 'amd64_21']; then
    docker-compose up imagebuilder_x86_64_21_02 &&  docker-compose rm -f
elif [ "$1" = 'rockchip_21']; then
    docker-compose up imagebuilder_rockchip_21_02 &&  docker-compose rm -f
fi
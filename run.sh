#!/bin/bash -e

if [ "$1" = 'amd64_21' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:x86-64-openwrt-21.02"
    OPENWRT_VERSION=21.02
    IPK_ARCH=x86_64
    CLASH_ARCH=amd64-compatible
elif [ "$1" = 'amd64_22' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:x86-64-22.03.2"
    OPENWRT_VERSION=22.03
    IPK_ARCH=x86_64
    CLASH_ARCH=amd64-compatible
elif [ "$1" = 'rockchip_21' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-openwrt-21.02"
    OPENWRT_VERSION=21.02
    IPK_ARCH=aarch64_generic
    CLASH_ARCH=arm64
elif [ "$1" = 'rockchip_22' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-openwrt-22.03"
    OPENWRT_VERSION=22.03
    IPK_ARCH=aarch64_generic
    CLASH_ARCH=arm64
elif [ "$1" = 'immortalwrt_rockchip_21' ]; then
    IMAGEBUILDER_IMAGE="immortalwrt/imagebuilder:rockchip-armv8-openwrt-21.02.3"
    OPENWRT_VERSION=21.02
    IPK_ARCH=aarch64_generic
    CLASH_ARCH=arm64
else
    echo "Usage: $0 [amd64_21|amd64_22|rockchip_21|rockchip_22|immortalwrt_rockchip_21]"
    exit 1
fi
docker_compose_file_content=$(cat <<-END
version: "3.5"
services:
  imagebuilder:
    image: "${IMAGEBUILDER_IMAGE}"
    container_name: imagebuilder
    environment:
      - TARGET=${TARGET}
      - OPENWRT_VERSION=${OPENWRT_VERSION}
    env_file:
      - ./.env
    volumes:
      - ./bin:/home/build/openwrt/bin
      - ./diy:/home/build/openwrt/diy
      - ./build.sh:/home/build/openwrt/build.sh
    command: "./build.sh"
END

)

echo "$docker_compose_file_content" > docker-compose.yml

if [ "$2" = '--with-pull' ]; then
    docker-compose pull
fi

docker-compose up --remove-orphans
docker-compose rm -f 

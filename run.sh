#!/bin/bash -e
CLASH_META_VERSION=1.13.2

if [ "$1" = 'amd64_21' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:x86-64-openwrt-21.02"
elif [ "$1" = 'amd64_22' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:x86-64-22.03.2"
elif [ "$1" = 'rockchip_r2s_21' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-openwrt-21.02"
elif [ "$1" = 'rockchip_r2s_22' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-openwrt-22.03"
elif [ "$1" = 'rockchip_r4s_21' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-openwrt-21.02"
    PROFILE=friendlyarm_nanopi-r4s
elif [ "$1" = 'rockchip_r4s_22' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-openwrt-22.03"
    PROFILE=friendlyarm_nanopi-r4s
elif [ "$1" = 'immortalwrt_amd_21' ]; then
    IMAGEBUILDER_IMAGE="immortalwrt/imagebuilder:x86-64-openwrt-21.02"
elif [ "$1" = 'immortalwrt_rockchip_r2s_21' ]; then
    IMAGEBUILDER_IMAGE="immortalwrt/imagebuilder:rockchip-armv8-openwrt-21.02.3"
elif [ "$1" = 'immortalwrt_rockchip_r4s_21' ]; then
    IMAGEBUILDER_IMAGE="immortalwrt/imagebuilder:rockchip-armv8-openwrt-21.02.3"
    PROFILE=friendlyarm_nanopi-r4s
else
    echo "Usage: $0 [amd64_21|amd64_22|rockchip_r2s_21|rockchip_r2s_22|rockchip_r4s_21|rockchip_r4s_22|immortalwrt_amd_21|immortalwrt_rockchip_r2s_21]"
    exit 1
fi

if [[ "$1" =~ "amd" ]]; then
    IPK_ARCH=x86_64
    CLASH_ARCH=amd64-compatible
elif [[ "$1" =~ "rockchip" ]]; then
    IPK_ARCH=aarch64_generic
    CLASH_ARCH=arm64
fi

SMALL_VERSION=${IMAGEBUILDER_IMAGE##*-}
BIG_VERSION=$(echo "$SMALL_VERSION" | cut -d. -f1,2)

docker_compose_file_content=$(cat <<-END
version: "3.5"
services:
  imagebuilder:
    image: "${IMAGEBUILDER_IMAGE}"
    container_name: imagebuilder
    environment:
      - OPENWRT_VERSION=$BIG_VERSION
      - IPK_ARCH=$IPK_ARCH
      - CLASH_ARCH=$CLASH_ARCH
      - CLASH_META_VERSION=$CLASH_META_VERSION
      - PROFILE=$PROFILE
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

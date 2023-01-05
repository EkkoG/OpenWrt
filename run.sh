#!/bin/bash -e
CLASH_META_VERSION=1.14.0

if [ "$1" = 'amd64_21' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:x86-64-openwrt-21.02"
elif [ "$1" = 'amd64_22' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:x86-64-22.03.2"
elif [ "$1" = 'rockchip_r2s_21' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-openwrt-21.02"
elif [ "$1" = 'rockchip_r2s_22' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-22.03.2"
elif [ "$1" = 'rockchip_r4s_21' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-openwrt-21.02"
    PROFILE=friendlyarm_nanopi-r4s
elif [ "$1" = 'rockchip_r4s_22' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-22.03.2"
    PROFILE=friendlyarm_nanopi-r4s
elif [ "$1" = 'immortalwrt_amd_21' ]; then
    IMAGEBUILDER_IMAGE="immortalwrt/imagebuilder:x86-64-openwrt-21.02"
elif [ "$1" = 'immortalwrt_rockchip_r2s_21' ]; then
    IMAGEBUILDER_IMAGE="immortalwrt/imagebuilder:rockchip-armv8-openwrt-21.02.3"
elif [ "$1" = 'immortalwrt_rockchip_r4s_21' ]; then
    IMAGEBUILDER_IMAGE="immortalwrt/imagebuilder:rockchip-armv8-openwrt-21.02.3"
    PROFILE=friendlyarm_nanopi-r4s
else
    echo "Usage: $0 [amd64_21|amd64_22|rockchip_r2s_21|rockchip_r2s_22|rockchip_r4s_21|rockchip_r4s_22|immortalwrt_amd_21|immortalwrt_rockchip_r2s_21|immortalwrt_rockchip_r4s_21]"
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

if [[ $IMAGEBUILDER_IMAGE =~ "immortalwrt" ]]; then
    BUILD_DIR=/home/build/immortalwrt
else
    BUILD_DIR=/home/build/openwrt
fi

CLASH_FILE_NAME="Clash.Meta-linux-${CLASH_ARCH}-v${CLASH_META_VERSION}"
CLASH_GZ_FILE_NAME="$CLASH_FILE_NAME.gz"

gz_cmd() {
    # macOS use gunzip, Linux use gzip
    if [ "$(uname)" = 'Darwin' ]; then
        gunzip -d "$1"
    else
        gzip -d "$1"
    fi
}

if [ -f "/tmp/$CLASH_FILE_NAME" ]; then
    echo "Clash.Meta already exists, skip download"
elif [ -f "/tmp/$CLASH_GZ_FILE_NAME" ]; then
    echo "Clash.Meta.gz already exists, skip download"
    gz_cmd "/tmp/$CLASH_GZ_FILE_NAME"
else
    echo "Downloading Clash.Meta..."
    wget "https://github.com/MetaCubeX/Clash.Meta/releases/download/v${CLASH_META_VERSION}/$CLASH_GZ_FILE_NAME" -O "/tmp/$CLASH_GZ_FILE_NAME"
    gz_cmd "/tmp/$CLASH_GZ_FILE_NAME"
fi
mkdir -p clashcore
cp "/tmp/$CLASH_FILE_NAME" clashcore/clash_meta

docker_compose_file_content=$(cat <<-END
version: "3.5"
services:
  imagebuilder:
    image: "$IMAGEBUILDER_IMAGE"
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
      - ./bin:$BUILD_DIR/bin
      - ./uci:$BUILD_DIR/uci
      - ./ssh:$BUILD_DIR/ssh
      - ./keys:$BUILD_DIR/third_party_keys
      - ./build.sh:$BUILD_DIR/build.sh
      - ./clashcore:$BUILD_DIR/files/etc/openclash/core
    command: "./build.sh"
END

)

echo "$docker_compose_file_content" > docker-compose.yml

if [ "$2" = '--with-pull' ]; then
    docker-compose pull
fi

docker-compose up --remove-orphans
docker-compose rm -f

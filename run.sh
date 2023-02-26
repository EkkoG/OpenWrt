#!/bin/bash -e
CLASH_META_VERSION=1.14.2


function usage()
{
    echo "--with-pull: pull image before build"
    echo "--rm-first: remove container before build"
    echo "--tsinghua-mirror: use tsinghua mirror"
    echo "-h|--help: print this help"
    echo "and a build target: amd64_21 | amd64_22 | rockchip_r2s_21 | rockchip_r2s_22 | rockchip_r4s_21 | rockchip_r4s_22 | immortalwrt_amd64_21 | immortalwrt_rockchip_r2s_21 | immortalwrt_rockchip_r4s_21"
    exit 1
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        amd64_21 | amd64_22 | rockchip_r2s_21 | rockchip_r2s_22 | rockchip_r4s_21 | rockchip_r4s_22 | immortalwrt_amd64_21 | immortalwrt_rockchip_r2s_21 | immortalwrt_rockchip_r4s_21)
        TARGET=$PARAM
            ;;
        --with-pull)
            WITH_PULL=1
            ;;
        --rm-first)
            RM_FIRST=1
            ;;
        --tsinghua-mirror)
            TSINGHUA_MIRROR=1
            ;;
        -h | --help)
            usage
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

if [ -z "$TARGET" ]; then
    echo "ERROR: no target specified"
    usage
    exit 1
fi

if [ "$TARGET" = 'amd64_21' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:x86-64-21.02.5"
elif [ "$TARGET" = 'amd64_22' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:x86-64-22.03.3"
elif [ "$TARGET" = 'rockchip_r2s_21' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-21.02.5"
elif [ "$TARGET" = 'rockchip_r2s_22' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-22.03.3"
elif [ "$TARGET" = 'rockchip_r4s_21' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-21.02.5"
    PROFILE=friendlyarm_nanopi-r4s
elif [ "$TARGET" = 'rockchip_r4s_22' ]; then
    IMAGEBUILDER_IMAGE="openwrtorg/imagebuilder:rockchip-armv8-22.03.3"
    PROFILE=friendlyarm_nanopi-r4s
elif [ "$TARGET" = 'immortalwrt_amd64_21' ]; then
    IMAGEBUILDER_IMAGE="immortalwrt/imagebuilder:x86-64-openwrt-21.02"
elif [ "$TARGET" = 'immortalwrt_rockchip_r2s_21' ]; then
    IMAGEBUILDER_IMAGE="immortalwrt/imagebuilder:rockchip-armv8-openwrt-21.02"
elif [ "$TARGET" = 'immortalwrt_rockchip_r4s_21' ]; then
    IMAGEBUILDER_IMAGE="immortalwrt/imagebuilder:rockchip-armv8-openwrt-21.02"
    PROFILE=friendlyarm_nanopi-r4s
else
    exit 1
fi

if [[ "$TARGET" =~ "amd" ]]; then
    IPK_ARCH=x86_64
    CLASH_ARCH=amd64-compatible
elif [[ "$TARGET" =~ "rockchip" ]]; then
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
      - TSINGHUA_MIRROR=$TSINGHUA_MIRROR
    env_file:
      - ./.env
    volumes:
      - ./bin:$BUILD_DIR/bin
      - ./uci-defaults:$BUILD_DIR/uci-defaults
      - ./ssh:$BUILD_DIR/ssh
      - ./keys:$BUILD_DIR/third_party_keys
      - ./build.sh:$BUILD_DIR/build.sh
      - ./clashcore:$BUILD_DIR/files/etc/openclash/core
      - ./extra-pkgs:$BUILD_DIR/extra-pkgs
      - ./files:$BUILD_DIR/custom_files
    command: "./build.sh"
END

)

echo "$docker_compose_file_content" > docker-compose.yml

if [ ! -z $WITH_PULL ]; then
    docker-compose pull
fi

if [ ! -z $RM_FIRST ]; then
    docker-compose rm -f
fi

docker-compose up --remove-orphans
docker-compose rm -f
rm docker-compose.yml

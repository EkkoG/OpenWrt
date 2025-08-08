#!/bin/bash -e

# 设置 Docker 路径（macOS）
export PATH="/usr/local/bin:/opt/homebrew/bin:/Applications/Docker.app/Contents/Resources/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# 验证 Docker 是否可用
if ! command -v docker &> /dev/null; then
    echo "错误: 未找到 Docker，请确保 Docker Desktop 已安装并运行"
    echo "尝试查找的路径："
    echo "  - /usr/local/bin/docker (Intel Mac Homebrew)"
    echo "  - /opt/homebrew/bin/docker (Apple Silicon Homebrew)"
    echo "  - /Applications/Docker.app/Contents/Resources/bin/docker (Docker Desktop)"
    exit 1
fi

function compose() {
    # if docker-compose is not installed, use it
    if ! command -v docker-compose &> /dev/null; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}

function usage()
{
    echo "--image: specify imagebuilder docker image, find it in https://hub.docker.com/r/openwrt/imagebuilder/tags or https://hub.docker.com/r/immortalwrt/imagebuilder/tags"
    echo "--profile: specify profile"
    echo "--output: specify output directory for build results (default: ./bin)"
    echo "--with-pull: pull image before build"
    echo "--rm-first: remove container before build"
    echo "--use-mirror: use mirror"
    echo "--mirror: specify mirror url, like mirrors.jlu.edu.cn, do not add http:// or https://"
    echo "-h|--help: print this help"
    exit 1
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        --with-pull)
            WITH_PULL=1
            ;;
        --rm-first)
            RM_FIRST=1
            ;;
        --use-mirror)
            USE_MIRROR=$VALUE
            ;;
        --mirror)
            MIRROR=$VALUE
            ;;
        --profile)
            PROFILE=$VALUE
            ;;
        --image)
            IMAGEBUILDER_IMAGE=$VALUE
            ;;
        --output)
            OUTPUT_DIR=$VALUE
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

if [ -z "$IMAGEBUILDER_IMAGE" ]; then
    echo "ERROR: no image specified"
    usage
    exit 1
fi

if [ -z "$USE_MIRROR" ]; then
    USE_MIRROR=1
fi

if [ -z "$MIRROR" ]; then
    MIRROR="mirrors.pku.edu.cn"
fi

if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="./bin"
fi

echo "IMAGEBUILDER_IMAGE: $IMAGEBUILDER_IMAGE PROFILE: $PROFILE"

if [[ $IMAGEBUILDER_IMAGE =~ "immortalwrt" ]]; then
    BUILD_DIR=/home/build/immortalwrt
else
    BUILD_DIR=/builder
fi
docker_compose_file_content=$(cat <<-END
version: "3.5"
services:
  imagebuilder:
    image: "$IMAGEBUILDER_IMAGE"
    container_name: imagebuilder
    environment:
      - PROFILE=$PROFILE
      - USE_MIRROR=$USE_MIRROR
      - MIRROR=$MIRROR
      - IMAGEBUILDER_IMAGE=$IMAGEBUILDER_IMAGE
    env_file:
      - ./.env
    volumes:
      - $OUTPUT_DIR:$BUILD_DIR/bin
      - ./build.sh:$BUILD_DIR/build.sh
      - ./setup:$BUILD_DIR/setup
      - ./modules:$BUILD_DIR/modules_in_container
      - ./user_modules:$BUILD_DIR/user_modules_in_container
      - ./.env:$BUILD_DIR/.env
    command: "./build.sh"
END

)

echo "$docker_compose_file_content" > docker-compose.yml

if [ ! -z $WITH_PULL ]; then
    compose pull
fi

if [ ! -z $RM_FIRST ]; then
    compose rm -f
fi

mkdir -p "$OUTPUT_DIR"
# macOS no need to change the owner
# change the owner of output directory to 1000:1000 when running on linux
if [[ $(uname) =~ "Linux" ]]; then
    sudo chown -R 1000:1000 "$OUTPUT_DIR"
fi

if [ ! -f .env ]; then
    echo "WARNING: .env file not found, using default values"
    echo "" > .env
fi

compose up --exit-code-from imagebuilder --remove-orphans
build_status=$?
compose rm -f
rm docker-compose.yml

if [ $build_status -ne 0 ]; then
    echo "build failed with exit code $build_status"
    exit 1
else
    ls -R "$OUTPUT_DIR"
fi

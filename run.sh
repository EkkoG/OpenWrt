#!/bin/bash -e

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

# Set the TARGET_VERSION that need to change the modules
TARGET_VERSION=24.10

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
      - TARGET_VERSION=$TARGET_VERSION
      - IMAGEBUILDER_IMAGE=$IMAGEBUILDER_IMAGE
    env_file:
      - ./.env
    volumes:
      - ./bin:$BUILD_DIR/bin
      - ./build.sh:$BUILD_DIR/build.sh
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

mkdir -p bin
# macOS no need to change the owner
# change the owner of bin to 1000:1000 when running on linux
if [[ $(uname) =~ "Linux" ]]; then
    sudo chown -R 1000:1000 bin
fi

compose up --exit-code-from imagebuilder --remove-orphans
build_status=$?
compose rm -f
rm docker-compose.yml

if [ $build_status -ne 0 ]; then
    echo "build failed with exit code $build_status"
    exit 1
else
    ls -R bin
fi

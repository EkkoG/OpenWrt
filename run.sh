#!/bin/bash -e
function usage()
{
    echo "--image: specify imagebuilder docker image, find it in https://hub.docker.com/r/openwrtorg/imagebuilder/tags or https://hub.docker.com/r/immortalwrt/imagebuilder/tags"
    echo "--profile: specify profile"
    echo "--with-pull: pull image before build"
    echo "--rm-first: remove container before build"
    echo "--tsinghua-mirror: use tsinghua mirror, only for openwrt, not for immortalwrt"
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

echo "IMAGEBUILDER_IMAGE: $IMAGEBUILDER_IMAGE PROFILE: $PROFILE"

if [[ $IMAGEBUILDER_IMAGE =~ "immortalwrt" ]]; then
    BUILD_DIR=/home/build/immortalwrt
else
    BUILD_DIR=/home/build/openwrt
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
    env_file:
      - ./.env
    volumes:
      - ./bin:$BUILD_DIR/bin
      - ./build.sh:$BUILD_DIR/build.sh
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
build_status=$?
docker-compose rm -f
rm docker-compose.yml

if [ $build_status -ne 0 ]; then
    echo "build failed"
    exit 1
fi

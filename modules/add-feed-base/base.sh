if [[ $PWD =~ "immortalwrt" ]]; then
    PROJECT_NAME="immortalwrt"
    sudo chown -R $(whoami):$(whoami) bin
else
    PROJECT_NAME="openwrt"
fi

PACKAGES_ARCH=$(cat .config | grep CONFIG_TARGET_ARCH_PACKAGES | awk -F '=' '{print $2}' | sed 's/"//g')
OPENWRT_VERSION=$(cat ./include/version.mk | grep 'VERSION_NUMBER:=$(if' | awk -F ',' '{print $3}' | awk -F ')' '{print $1}')
BIG_VERSION=$(echo $OPENWRT_VERSION | awk -F '.' '{print $1"."$2}')

echo "PACKAGES_ARCH: $PACKAGES_ARCH OPENWRT_VERSION: $OPENWRT_VERSION BIG_VERSION: $BIG_VERSION"
DISTRIB_ARCH=$PACKAGES_ARCH
DISTRIB_RELEASE=$OPENWRT_VERSION
add_packages() {
    echo "try add $1"

    all_supported=$(curl https://sourceforge.net/projects/ekko-openwrt-dist/files/$1/ | grep -e "<th.*files/$1" | grep -o 'href="/projects[^"]*"' | sed 's/href="//' | sed 's/"$//' | awk -F/ '{print $6}')
    echo "All supported version: "
    echo "$all_supported"

    version=$(echo "$DISTRIB_RELEASE" | awk -F- '{print $1}')
    echo "Current version: $version"

    # get the first two version number
    big_version=$(echo "$version" | awk -F. '{print $1"."$2}')

    if [ "$1" == "luci" ]; then
        supported=$(echo "$all_supported" | grep "$big_version")
        feed_version="$DISTRIB_RELEASE"
    else
        supported=$(echo "$all_supported" | grep $DISTRIB_ARCH | grep $big_version)
        feed_version="$DISTRIB_ARCH-v$DISTRIB_RELEASE"
    fi

    echo "Supported version: "
    echo "$supported"

    if [ -z "$supported" ]; then
        echo "Your device is not supported"
        exit 1
    fi

    full_support=0
    for i in $supported; do
        if [ "$i" = "$feed_version" ]; then
            full_support=1
            break
        fi
    done

    if [ "$full_support" = "0" ]; then
        echo "Your device is not fully supported"
        echo "Find the latest version that supports your device"

        # 过滤掉 rc 和 SNAPSHOT 版本, 不用 grep
        final_release=$(echo "$supported" | grep -v "\-rc" | grep -v "SNAPSHOT" | tail -n 1)
        if [ -z "$final_release" ]; then
            echo "No final release found, use the latest rc version"
            feed_version=$(echo "$supported" | grep "\-rc" | tail -n 1)
        else
            feed_version=$final_release
        fi
    fi
    echo "Feed version: $feed_version"
    EKKOG_FEED="src/gz ekkog_$1 https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/ekko-openwrt-dist/$1/$feed_version"
    echo "$EKKOG_FEED" >> files/etc/opkg/customfeeds.conf
    # 添加软件源到第一行
    echo "$EKKOG_FEED" | cat - ./repositories.conf > temp && mv temp ./repositories.conf
}

add_geodata() {
    FEED_URL="src/gz ekkog_geodata https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/ekko-openwrt-dist/$1" 
    echo "$FEED_URL" | cat - ./repositories.conf > temp && mv temp ./repositories.conf
    echo "$FEED_URL" >> files/etc/opkg/customfeeds.conf
}

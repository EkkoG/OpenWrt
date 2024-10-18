PACKAGES_ARCH=$(cat .config | grep CONFIG_TARGET_ARCH_PACKAGES | awk -F '=' '{print $2}' | sed 's/"//g')

add_packages() {
    dist_path="$1/$PACKAGES_ARCH"
    if [ $1 = luci ]; then
        dist_path="luci"
    fi
    EKKOG_FEED="src/gz ekkog_$1 https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/ekko-openwrt-dist/$dist_path"
    mkdir -p files/etc/opkg/
    echo "$EKKOG_FEED" >> files/etc/opkg/customfeeds.conf
    # 添加软件源到第一行
    echo "$EKKOG_FEED" | cat - ./repositories.conf > temp && mv temp ./repositories.conf
}

add_geodata() {
    FEED_URL="src/gz ekkog_geodata https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/ekko-openwrt-dist/$1" 
    echo "$FEED_URL" | cat - ./repositories.conf > temp && mv temp ./repositories.conf
    mkdir -p files/etc/opkg/
    echo "$FEED_URL" >> files/etc/opkg/customfeeds.conf
}

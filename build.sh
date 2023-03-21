#!/bin/bash -e
sudo chown -R $(whoami):$(whoami) bin
if [ -z $LAN_IP ]; then
    echo "LAN_IP is empty"
    exit 1
fi

cp -r custom_files files

mkdir -p files/etc/openclash/config
wget $CLASH_CONFIG_URL -O files/etc/openclash/config/config.yaml

# sudo apt-get update
# sudo apt-get install tree
# tree files
IPK_ARCH=$(cat ./repositories.conf | grep _packages | awk -F '/' '{print $8}')
OPENWRT_VERSION=$(cat ./repositories.conf | grep _packages | awk -F '/' '{print $6}')
BIG_VERSION=$(echo $OPENWRT_VERSION | awk -F '.' '{print $1"."$2}')

echo "IPK_ARCH: $IPK_ARCH OPENWRT_VERSION: $OPENWRT_VERSION BIG_VERSION: $BIG_VERSION"

THIRD_SOURCE=$(cat <<-END
src/gz ekkog https://ghproxy.com/https://github.com/ekkog/openwrt-dist/blob/packages/${IPK_ARCH}-${BIG_VERSION}
END
)

if [[ $PWD =~ "immortalwrt" ]]; then
    echo "no need to add third source"
else
# 添加软件源
    echo "$THIRD_SOURCE" >> ./repositories.conf

    if [ ! -z $TSINGHUA_MIRROR ]; then
        sed -i 's/https:\/\/downloads.openwrt.org/https:\/\/mirrors.tuna.tsinghua.edu.cn\/openwrt/g' ./repositories.conf
    fi

    mkdir -p files/etc/opkg/
    echo "$THIRD_SOURCE" >> files/etc/opkg/customfeeds.conf
    # sed -i '/check_signature/d' ./repositories.conf
fi

cat ./repositories.conf

# 添加签名验证的 key
cp files/etc/opkg/keys/* keys

# merge files in uci folder to /tmp/init.sh
for file in files/etc/uci-defaults/*; do
    # 替换自定义参数
    sed -i "s/PPPOE_USERNAME/$PPPOE_USERNAME/g" $file
    sed -i "s/PPPOE_PASSWORD/$PPPOE_PASSWORD/g" $file
    sed -i "s/LAN_IP/$LAN_IP/g" $file
    sed -i "s~CLASH_CONFIG_URL~$CLASH_CONFIG_URL~g" $file
done

# 添加 SSH 相关
if [ -f "files/etc/dropbear/authorized_keys" ];then
    chmod 644 files/etc/dropbear/authorized_keys
fi

# 扩大 rootfs 大小，不然编译 x86_64 会报错
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/ c\CONFIG_TARGET_ROOTFS_PARTSIZE=200' .config

# # 添加本地软件源，安装自定义 ipk 使用
# if [ "$OPENWRT_VERSION" = "21.02" ]; then
#     echo "src imagebuilder file:packages" >> ./repositories.conf
# fi

# base packages
all_packages="luci luci-compat -dnsmasq dnsmasq-full luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn openssl-util"

# openclash
all_packages="$all_packages luci-app-openclash clash-meta-for-openclash"

if [ $OPENWRT_VERSION = "22.03" ]; then
    all_packages="$all_packages \
    kmod-nft-tproxy \
    "
else
    all_packages="$all_packages \
    ip6tables-mod-nat \
    ipset \
    iptables-mod-extra \
    iptables-mod-tproxy \
    "
fi

# theme
all_packages="$all_packages $EXTRA_PKGS luci-theme-argon"

chmod +x files/etc/openclash/core/clash_meta

make info
if [ -z "$PROFILE" ]; then
    make image PACKAGES="$all_packages" FILES="files"
else
    make PROFILE="$PROFILE" image PACKAGES="$all_packages" FILES="files"
fi
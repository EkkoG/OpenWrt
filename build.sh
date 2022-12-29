#!/bin/bash -e

if [ -z $LAN_IP ]; then
    echo "LAN_IP is empty"
    exit 1
fi

# =================================================================
# change files folder to current user
sudo chown -R $(whoami):$(whoami) files

THIRD_SOURCE=$(cat <<-END
src/gz ekkog https://ghproxy.com/https://github.com/ekkog/openwrt-dist/blob/packages/${IPK_ARCH}-${OPENWRT_VERSION}
END
)

if [[ $PWD =~ "immortalwrt" ]]; then
    echo "no need to add third source"
else
# 添加软件源
    echo "$THIRD_SOURCE" >> ./repositories.conf

    sed -i 's/https:\/\/downloads.openwrt.org/https:\/\/mirrors.tuna.tsinghua.edu.cn\/openwrt/g' ./repositories.conf

    mkdir -p files/etc/opkg/
    echo "$THIRD_SOURCE" >> files/etc/opkg/customfeeds.conf
    # sed -i '/check_signature/d' ./repositories.conf
fi

# 添加签名验证的 key
cp third_party_keys/* keys

mkdir -p files/etc/opkg/keys/
cp third_party_keys/* files/etc/opkg/keys/

# 添加自定义 uci 脚本
mkdir -p files/etc/uci-defaults/

# merge files in uci folder to /tmp/init.sh
for file in uci/*.sh; do
    cat "$file" >> files/etc/uci-defaults/init
    printf "\n" >> files/etc/uci-defaults/init
done

# 替换自定义参数
sed -i "s/PPPOE_USERNAME/$PPPOE_USERNAME/g" files/etc/uci-defaults/init
sed -i "s/PPPOE_PASSWORD/$PPPOE_PASSWORD/g" files/etc/uci-defaults/init
sed -i "s/LAN_IP/$LAN_IP/g" files/etc/uci-defaults/init
sed -i "s~CLASH_CONFIG_URL~$CLASH_CONFIG_URL~g" files/etc/uci-defaults/init

# 添加 SSH 相关
if [ -f "ssh/authorized_keys" ];then
    mkdir -p files/etc/dropbear/
    cat "ssh/authorized_keys" >> files/etc/dropbear/authorized_keys
    chmod 644 files/etc/dropbear/authorized_keys
fi

# 扩大 rootfs 大小，不然编译 x86_64 会报错
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/ c\CONFIG_TARGET_ROOTFS_PARTSIZE=200' .config

# # 添加本地软件源，安装自定义 ipk 使用
# if [ "$OPENWRT_VERSION" = "21.02" ]; then
#     echo "src imagebuilder file:packages" >> ./repositories.conf
# fi

# base packages
all_packages="luci luci-compat -dnsmasq dnsmasq-full luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn"

all_packages="$all_packages \
wget curl vim-full \
luci-app-openclash \
"

all_packages="$all_packages luci-theme-argon"

if [ -z "$PROFILE" ]; then
    make image PACKAGES="$all_packages" FILES="files"
else
    make PROFILE="$PROFILE" image PACKAGES="$all_packages" FILES="files"
fi
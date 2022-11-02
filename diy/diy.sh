#!/bin/bash -e

IPK_ARCH=
IPK_ARCH_STYLE_2=
CLASH_ARCH=
if [ "$TARGET" = "x86_64" ]; then
    IPK_ARCH=x86_64
    IPK_ARCH_STYLE_2=x86/64
    CLASH_ARCH=amd64-compatible
elif [ "$TARGET" = "rockchip" ]; then
    IPK_ARCH=aarch64_generic
    IPK_ARCH_STYLE_2=rockchip/armv8
    CLASH_ARCH=arm64
fi

# =================================================================

# 添加软件源

S1="src/gz ekkog https://ghproxy.com/https://github.com/ekkog/openwrt-dist/blob/packages/${IPK_ARCH}-21.02.5"
S3="src/gz simonsmh https://ghproxy.com/https://github.com/simonsmh/openwrt-dist/blob/packages/${IPK_ARCH_STYLE_2}"

echo "$S1" >> ./repositories.conf
echo "$S3" >> ./repositories.conf

mkdir -p files/etc/opkg/
echo "$S1" >> files/etc/opkg/customfeeds.conf
echo "$S3" >> files/etc/opkg/customfeeds.conf
# sed -i '/check_signature/d' ./repositories.conf

# 添加签名验证的 key
cp diy/keys/* keys

mkdir -p files/etc/opkg/keys/
cp diy/keys/* files/etc/opkg/keys/

# 添加自定义 uci 脚本
mkdir -p files/etc/uci-defaults/

cat "diy/uci/common.sh" >> /tmp/init.sh
printf "\n" >> /tmp/init.sh

# 自定义定义网络配置命令
cat "diy/uci/network.sh" >> /tmp/init.sh
printf "\n" >> /tmp/init.sh

if [ -f "diy/uci/others.sh" ]; then
    cat "diy/uci/other.sh" >> /tmp/init.sh
fi
printf "\n" >> /tmp/init.sh

if [ -z $LAN_IP ]; then
    echo "LAN_IP is empty"
    exit 1
fi

# 替换自定义参数
cat /tmp/init.sh | \
 sed "s/PPPOE_USERNAME/$PPPOE_USERNAME/g" | \
 sed "s/PPPOE_PASSWORD/$PPPOE_PASSWORD/g" | \
 sed "s/LAN_IP/$LAN_IP/g" | \
 sed "s~CLASH_CONFIG_URL~$CLASH_CONFIG_URL~g" \
 >  files/etc/uci-defaults/uci-diy

# 添加 SSH 相关
if [ -f "diy/ssh/authorized_keys" ];then
    mkdir -p files/etc/dropbear/
    cat "diy/ssh/authorized_keys" >> files/etc/dropbear/authorized_keys
    chmod 644 files/etc/dropbear/authorized_keys
fi

# 安装依赖
sudo -E apt-get -qq install gzip

# 扩大 rootfs 大小，不然编译 x86_64 会报错

if [ "$TARGET" = "x86_64" ] || [ "$TARGET" = "rockchip" ];then
    sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/ c\CONFIG_TARGET_ROOTFS_PARTSIZE=200' .config
fi

# 去广告相关
mkdir -p files/etc/dnsfilter
cp diy/other/dnsfilter_white.list files/etc/dnsfilter/white.list

mkdir -p files/etc/openclash/core

wget "https://github.com/MetaCubeX/Clash.Meta/releases/download/v1.13.1/Clash.Meta-linux-${CLASH_ARCH}-v1.13.1.gz"

gzip -d "Clash.Meta-linux-${CLASH_ARCH}-v1.13.1.gz"
cp "Clash.Meta-linux-${CLASH_ARCH}-v1.13.1" files/etc/openclash/core/clash_meta

# # 添加本地软件源，安装自定义 ipk 使用
# if [ "$OPENWRT_VERSION" = "21.02" ]; then
#     echo "src imagebuilder file:packages" >> ./repositories.conf
# fi
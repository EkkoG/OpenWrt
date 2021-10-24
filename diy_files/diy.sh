#!/bin/bash -e

CUSTOM_IPK_ARCH=
if [ "$TARGET" = "x86_64" ]; then
    CUSTOM_IPK_ARCH=x86_64
elif [ "$TARGET" = "rockchip" ]; then
    CUSTOM_IPK_ARCH=aarch64_generic
elif [ "$TARGET" = "ar71xx_nand" ]; then
    CUSTOM_IPK_ARCH=mips_24kc

    mkdir -p files/etc/config
    cp diy_files/config/wireless files/etc/config/wireless

fi

# =================================================================

# 添加软件源

S1="src/gz cielpy https://ghproxy.com/https://github.com/cielpy/openwrt-dist/blob/packages/${CUSTOM_IPK_ARCH}"
S2="src/gz cielpy_base https://ghproxy.com/https://github.com/cielpy/openwrt-dist/blob/base/${CUSTOM_IPK_ARCH}"
S3="src/gz simonsmh https://ghproxy.com/https://github.com/simonsmh/openwrt-dist/blob/packages/x86/64/"

echo "$S1" >> ./repositories.conf
echo "$S2" >> ./repositories.conf
echo "$S3" >> ./repositories.conf

mkdir -p files/etc/opkg/
echo "$S1" >> files/etc/opkg/customfeeds.conf
echo "$S2" >> files/etc/opkg/customfeeds.conf
# echo "$S3" >> files/etc/opkg/customfeeds.conf
sed -i '/check_signature/d' ./repositories.conf

cat ./repositories.conf

# 如果需要，添加签名验证的 key
if [ -d keys ] && [ -d diy_files/keys ] && [ ! -z $(ls diy_files/keys) ]; then
    ls diy_files/keys
    cp diy_files/keys/* keys

    mkdir -p files/etc/opkg/keys/
    cp diy_files/keys/* files/etc/opkg/keys/
fi

# 添加自定义 uci 脚本
mkdir -p files/etc/uci-defaults/
cat diy_files/uci-diy.tpl.sh > /tmp/init.sh
printf "\n" >> /tmp/init.sh

# 针对个人的自定义，需要在定义 FLAG 环境变量，并在 diy_files/personal_diy 下放一个脚本，脚本名为 $FLAG.sh
if [ -f "diy_files/personal_diy/$FLAG.sh" ];then
    cat "diy_files/personal_diy/$FLAG.sh" >> /tmp/init.sh
    printf "\n" >> /tmp/init.sh
fi
cat "diy_files/common.sh" >> /tmp/init.sh
printf "\n" >> /tmp/init.sh

# 如果上网方法为 pppoe，记得在 diy_files 下放一个 pppoe.sh, 定义网络配置命令
if [ "$WAN_TYPE" = "pppoe" ]; then
    cat "diy_files/pppoe.sh" >> /tmp/init.sh
    printf "\n" >> /tmp/init.sh
fi

# 替换自定义参数
cat /tmp/init.sh | \
 sed "s/CUSTOM_PPPOE_USERNAME/$CUSTOM_PPPOE_USERNAME/g" | \
 sed "s/CUSTOM_PPPOE_PASSWORD/$CUSTOM_PPPOE_PASSWORD/g" | \
 sed "s/CUSTOM_LAN_IP/$CUSTOM_LAN_IP/g" | \
 sed "s~CUSTOM_CLASH_CONFIG_URL~$CUSTOM_CLASH_CONFIG_URL~g" | \
 sed "s~CUSTOM_PASSWALL_SUBSCRIBE_URL~$CUSTOM_PASSWALL_SUBSCRIBE_URL~g" \
 >  files/etc/uci-defaults/uci-diy

# 添加 SSH key，放在 diy_files/personal_diy 下，名字为 $FLAG.pub
if [ -f "diy_files/personal_diy/$FLAG.pub" ];then
    mkdir -p files/etc/dropbear/
    cat "diy_files/personal_diy/$FLAG.pub" >> files/etc/dropbear/authorized_keys
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
cp diy_files/dnsfilter_white.list files/etc/dnsfilter/white.list

# # 添加本地软件源，安装自定义 ipk 使用
# if [ "$OPENWRT_VERSION" = "21.02" ]; then
#     echo "src imagebuilder file:packages" >> ./repositories.conf
# fi
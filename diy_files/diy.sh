#!/bin/bash -e

CUSTOM_IPK_ARCH=
CLASH_ARCH=

# https://github.com/Dreamacro/clash/releases/tag/premium
CLASH_TUN_RELEASE_DATE=2021.05.08
# https://github.com/comzyh/clash/releases
CLASH_GAME_RELEASE_DATE=20210310
# https://github.com/Dreamacro/clash/releases
CLASH_VERSION=1.6.0


if [ "$TARGET" = "x86_64" ]; then
    CUSTOM_IPK_ARCH=x86_64
    CLASH_ARCH=amd64
elif [ "$TARGET" = "rockchip" ]; then
    CUSTOM_IPK_ARCH=aarch64_generic
    CLASH_ARCH=armv8
elif [ "$TARGET" = "ar71xx_nand" ]; then
    CUSTOM_IPK_ARCH=mips_24kc
    CLASH_ARCH=mips-softfloat

    mkdir -p files/etc/config
    cp diy_files/config/wireless files/etc/config/wireless

fi

# 工具方法定义
function download_clash_binaries() {
    local url=$1
    local binaryname=$2
    local dist=$3
    wget $url

    if [ "$dist" != "" ];then
        mkdir -p $dist
        pushd $dist
    fi
    
    local filename="${url##*/}"
    gunzip -c $filename > $binaryname
    chmod +x $binaryname

    if [ "$dist" != "" ];then
        popd
    fi

    rm $filename
}

function download_xray() {
    mkdir /tmp/download_xray
    pushd /tmp/download_xray

    url=https://github.com/XTLS/Xray-core/releases/download/v1.4.2/Xray-linux-64.zip
    if [ "$TARGET" = "ar71xx_nand" ]; then
        url=https://github.com/XTLS/Xray-core/releases/download/v1.4.2/Xray-linux-mips32le.zip
    fi

    wget $url
    local filename="${url##*/}"
    unzip $filename
    mkdir -p /home/build/openwrt/files/usr/bin/xray
    cp xray /home/build/openwrt/files/usr/bin/xray
    mkdir -p /home/build/openwrt/files/usr/share/xray/
    cp geosite.dat /home/build/openwrt/files/usr/share/xray/
    cp geoip.dat /home/build/openwrt/files/usr/share/xray/
    popd
}

function add_anti_ad() {
    mkdir -p files/etc/dnsmasq.d
    url=https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/master/adblock-for-dnsmasq.conf
    local filename="${url##*/}"
    pushd files/etc/dnsmasq.d
        wget $url
        sed -i '/seeip.org/d' $filename
    popd
}

function download_missing_ipks() {
    local url=$1
    local binaryname=$2
    wget $url
    
    local filename="${url##*/}"

    mkdir -p packages
    cp $filename ./packages/$filename
    rm $filename
}

# =================================================================

# 添加软件源
echo "src/gz supres https://op.supes.top/packages/${CUSTOM_IPK_ARCH}" >> ./repositories.conf
if grep 'check_signature' ./repositories.conf
then
    sed -i '/check_signature/d' ./repositories.conf
fi

if [ "$OPENWRT_VERSION" = "21.02" ]; then
    echo "src imagebuilder file:packages" >> ./repositories.conf
fi

# 如果需要，添加签名验证的 key
if [ -d keys ] && [ -d diy_files/keys ] && [ ! -z $(ls diy_files/keys) ]; then
    ls diy_files/keys
    cp diy_files/keys/* keys
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

if [ "$TARGET" = "x86_64" ];then
    sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/ c\CONFIG_TARGET_ROOTFS_PARTSIZE=154' .config
fi

# 添加去广告
add_anti_ad

# 添加 clash 可执行文件，ar71xx_nand 上由于空间太小，不适合使用 clash
if [ "$TARGET" != "ar71xx_nand" ]; then
    mkdir -p files/etc/clash/
    pushd files/etc/clash/
    download_clash_binaries https://github.com/cielpy/clash/releases/download/v${CLASH_VERSION}/clash-linux-${CLASH_ARCH}-v${CLASH_VERSION}.gz clash
# if [ "$TARGET" != "ar71xx_nand" ]; then
#     download_clash_binaries https://github.com/Dreamacro/clash/releases/download/premium/clash-linux-${CLASH_ARCH}-${CLASH_TUN_RELEASE_DATE}.gz clash ./dtun/
#     download_clash_binaries https://github.com/comzyh/clash/releases/download/${CLASH_GAME_RELEASE_DATE}/clash-linux-${CLASH_ARCH}-${CLASH_GAME_RELEASE_DATE}.gz clash ./clashtun/
# fi
    popd
fi

# 在 ar71xx_nand 上添加 xray 可执行文件，其他平台安装 luci-app-passwall 时会自动安装 xray
if [ "$TARGET" = "ar71xx_nand" ]; then
    download_xray
fi

# libcap-bin 在 19.07 上缺失，需要单独添加安装包
if [ "$OPENWRT_VERSION" = "19.07" ]; then
    download_missing_ipks https://downloads.openwrt.org/releases/packages-21.02/${CUSTOM_IPK_ARCH}/packages/libcap_2.43-1_${CUSTOM_IPK_ARCH}.ipk
    download_missing_ipks https://downloads.openwrt.org/releases/packages-21.02/${CUSTOM_IPK_ARCH}/packages/libcap-bin_2.43-1_${CUSTOM_IPK_ARCH}.ipk
fi

# 添加自定义主题
download_missing_ipks https://github.com/jerrykuku/luci-theme-argon/releases/download/v2.2.5/luci-theme-argon_2.2.5-20200914_all.ipk
# 添加京东签到
download_missing_ipks https://github.com/cielpy/luci-app-jd-dailybonus/releases/download/v1.0.5/luci-app-jd-dailybonus_1.0.5-20210316_all.ipk
# 添加自定义的 luci-app-clash
download_missing_ipks https://github.com/cielpy/luci-app-clash/releases/download/v1.9.0/luci-app-clash_v1.9.0_all.ipk
# 添加自定义的 overture
download_missing_ipks https://github.com/cielpy/overture-openwrt/releases/download/v1.8-rc1/overture_1.8-rc1-1_${CUSTOM_IPK_ARCH}.ipk

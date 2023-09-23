#!/bin/bash -e
if [[ $PWD =~ "immortalwrt" ]]; then
    PROJECT_NAME="immortalwrt"
else
    PROJECT_NAME="openwrt"
fi


if [ -z $LAN_IP ]; then
    LAN_IP="192.168.3.1"
fi

cp -r custom_files files

# sudo apt-get update
# sudo apt-get install tree
# tree files

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
    # 添加软件源到第一行
    echo "$EKKOG_FEED" | cat - ./repositories.conf > temp && mv temp ./repositories.conf
}

if [[ $OPENWRT_VERSION =~ "SNAPSHOT" ]]; then
EKKOG_FEED=$(cat <<-END
src/gz ekkog_packages https://github.com/ekkog/openwrt-packages/raw/${PACKAGES_ARCH}-${OPENWRT_VERSION}
src/gz ekkog_luci https://github.com/ekkog/openwrt-luci/raw/${OPENWRT_VERSION}
END
)
else
EKKOG_FEED=$(cat <<-END
src/gz ekkog_packages https://github.com/ekkog/openwrt-packages/raw/${PACKAGES_ARCH}-${BIG_VERSION}
src/gz ekkog_luci https://github.com/ekkog/openwrt-luci/raw/${BIG_VERSION}
END
)
fi

if [[ $OPENWRT_VERSION =~ "SNAPSHOT" ]]; then
PASSWALL_FEED=$(cat <<-END
src/gz passwall_luci https://free.nchc.org.tw/osdn/storage/g/o/op/openwrt-passwall-build/snapshots/packages/$PACKAGES_ARCH/passwall_luci
src/gz passwall_packages https://free.nchc.org.tw/osdn/storage/g/o/op/openwrt-passwall-build/snapshots/packages/$PACKAGES_ARCH/passwall_packages
src/gz passwall2 https://free.nchc.org.tw/osdn/storage/g/o/op/openwrt-passwall-build/snapshots/packages/$PACKAGES_ARCH/passwall2
END
)
else
PASSWALL_FEED=$(cat <<-END
src/gz passwall_luci https://free.nchc.org.tw/osdn/storage/g/o/op/openwrt-passwall-build/releases/packages-$BIG_VERSION/$PACKAGES_ARCH/passwall_luci
src/gz passwall_packages https://free.nchc.org.tw/osdn/storage/g/o/op/openwrt-passwall-build/releases/packages-$BIG_VERSION/$PACKAGES_ARCH/passwall_packages
src/gz passwall2 https://free.nchc.org.tw/osdn/storage/g/o/op/openwrt-passwall-build/releases/packages-$BIG_VERSION/$PACKAGES_ARCH/passwall2
END
)
fi


if [ $USE_MIRROR = '1' ]; then
    sed -i 's/https:\/\/downloads.'"$PROJECT_NAME"'.org/https:\/\/mirrors.pku.edu.cn\/'"$PROJECT_NAME"'/g' ./repositories.conf
fi

add_packages "luci"
add_packages "packages"
# if big version great than 23.05 or snapshot
if [[ $OPENWRT_VERSION =~ "23.05" ]] || [[ $OPENWRT_VERSION =~ "SNAPSHOT" ]]; then
    add_packages "dae"
fi
add_packages "clash"

mkdir -p files/etc/opkg/
echo "$EKKOG_FEED" >> files/etc/opkg/customfeeds.conf

if [ $PROJECT_NAME = "openwrt" ]; then
    echo "$PASSWALL_FEED" >> ./repositories.conf
    echo "$PASSWALL_FEED" >> files/etc/opkg/customfeeds.conf
fi

cat ./repositories.conf

# 添加签名验证的 key
cp files/etc/opkg/keys/* keys

# 添加 SSH 相关
if [ -f "files/etc/dropbear/authorized_keys" ];then
    chmod 644 files/etc/dropbear/authorized_keys
fi

# 不需要的镜像
sed -i '/CONFIG_ISO_IMAGES/ c\# CONFIG_ISO_IMAGES is not set' .config
sed -i '/CONFIG_TARGET_IMAGES_PAD/ c\# CONFIG_TARGET_IMAGES_PAD is not set' .config
sed -i '/CONFIG_VDI_IMAGES/ c\# CONFIG_VDI_IMAGES is not set' .config
sed -i '/CONFIG_VMDK_IMAGES/ c\# CONFIG_VMDK_IMAGES is not set' .config
sed -i '/CONFIG_VHDX_IMAGES/ c\# CONFIG_VHDX_IMAGES is not set' .config


# # 添加本地软件源，安装自定义 ipk 使用
# if [ "$OPENWRT_VERSION" = "21.02" ]; then
#     echo "src imagebuilder file:packages" >> ./repositories.conf
# fi

# base packages
all_packages="luci luci-compat luci-lib-ipkg luci-i18n-opkg-zh-cn -dnsmasq dnsmasq-full luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn openssl-util"

if [ $PROXY_CLIENT = "openclash" ]; then
    # openclash
    all_packages="$all_packages luci-app-openclash clash-meta-for-openclash"

    mkdir -p files/etc/openclash/config
    wget --user-agent='clash' $CLASH_CONFIG_URL -O files/etc/openclash/config/config.yaml

elif [ $PROXY_CLIENT = "passwall" ]; then
    all_packages="$all_packages luci-app-passwall luci-i18n-passwall-zh-cn"
fi

# printenv | grep 'CONFIG_', export all config
for config in $(printenv | grep '^CONFIG_'); do
    config_name=$(echo $config | awk -F '=' '{print $1}')
    config_value=$(echo $config | awk -F '=' '{print $2}')
    sed -i "/$config_name/ c\\$config_name=$config_value" .config
done


# theme
all_packages="$all_packages $EXTRA_PKGS luci-theme-argon"

echo "EXTRA_PKGS: $EXTRA_PKGS"

make info
if [ -z "$PROFILE" ]; then
    make image PACKAGES="$all_packages" FILES="files"
else
    make PROFILE="$PROFILE" image PACKAGES="$all_packages" FILES="files"
fi
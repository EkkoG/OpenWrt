PACKAGES_ARCH=$(cat .config | grep CONFIG_TARGET_ARCH_PACKAGES | awk -F '=' '{print $2}' | sed 's/"//g')
if [[ $IS_SNAPSHOT_BUILD == 1 ]]; then
PASSWALL_FEED=$(cat <<-END
src/gz passwall_luci https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/openwrt-passwall-build/snapshots/packages/$PACKAGES_ARCH/passwall_luci
src/gz passwall_packages https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/openwrt-passwall-build/snapshots/packages/$PACKAGES_ARCH/passwall_packages
src/gz passwall2 https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/openwrt-passwall-build/snapshots/packages/$PACKAGES_ARCH/passwall2
END
)
else
PASSWALL_FEED=$(cat <<-END
src/gz passwall_luci https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/openwrt-passwall-build/releases/packages-$OPENWRT_VERSION/$PACKAGES_ARCH/passwall_luci
src/gz passwall_packages https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/openwrt-passwall-build/releases/packages-$OPENWRT_VERSION/$PACKAGES_ARCH/passwall_packages
src/gz passwall2 https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/openwrt-passwall-build/releases/packages-$OPENWRT_VERSION/$PACKAGES_ARCH/passwall2
END
)
fi

mkdir -p files/etc/opkg/

if [ $PROJECT_NAME = "openwrt" ]; then
    echo "$PASSWALL_FEED" >> ./repositories.conf
    echo "$PASSWALL_FEED" >> files/etc/opkg/customfeeds.conf
fi

cp files/etc/opkg/keys/* keys